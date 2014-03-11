`timescale 1ns / 1ps
`include "wishbone.vh"
module surf4_rfp(
		input wbc_clk_i,
		input wbc_rst_i,
		`WBS_NAMED_PORT(wbc, 32, 19, 4),
		`WBM_NAMED_PORT(i2c, 8, 7, 1),
		input pps_i
    );

	// We have a 19-bit (8-bit) address space, but we can only use 0x00000-0x5FFFF.
	// Partitioning:
	// 0x0000-0x007F : shared port space with PicoBlaze
	// 0x0080-0x00FF : (shadowed with 00-0x7F)
	// PicoBlaze runs off of 1 BRAM, which is 18k, or 18 bits at 1024 instructions.
	// Let's map the BRAM to 1024 addresses, or 4096 byte addresses: 0x3FF space needed.
	// 0x0100-0x04FF : PicoBlaze BRAM (write-protected by bit in shared port space)
	// Then we'll map the I2C bus (which needs 7 bits of address space)
	// into 0x500-0x6FF. Only the low byte will be used.
	
	// The RFP data can be stored in 0x1000-0x1FFFF.
	// 0x0000-0x00FF : PicoBlaze registers  - shadowed at 0x0100 and 0x0800 and 0x0900 (
	// 0x0200-0x03FF : I2C bus              
	// 0x0400-0x07FF : PicoBlaze BRAM 
	// 0x8000-0xFFFF : RFP RAM
	// Then we'll just shadow the remaining addresses.
	wire [18:0] pb_port_bar		= 19'h00000;			
	wire [18:0] i2c_port_bar	= 19'h00200;
	wire [18:0] pb_bram_bar		= 19'h00400;
	wire [18:0] rfp_ram_bar 	= 19'h10000;

	wire [18:0] pb_port_mask	= 19'h6F9FF;      	// match xx0 xxxx x00x xxxx xxxx
	wire [18:0] i2c_port_mask	= 19'h6F9FF;			// match xx0 xxxx x01x xxxx xxxx
	wire [18:0] pb_bram_mask	= 19'h6FBFF;			// match xx0 xxxx x1xx xxxx xxxx
	wire [18:0] rfp_ram_mask 	= 19'h6FFFF;			// match xx1 xxxx xxxx xxxx xxxx

	wire pb_port_sel 	= (wbc_adr_i & pb_port_mask) == pb_port_bar;
	wire i2c_port_sel = (wbc_adr_i & i2c_port_mask) == i2c_port_bar;
	wire pb_bram_sel 	= (wbc_adr_i & pb_bram_mask) == pb_bram_bar;
	wire rfp_ram_sel = (wbc_adr_i & rfp_ram_mask) == rfp_ram_bar;
	
	// PicoBlaze has 32 32-bit registers shared with WISHBONE.
	// This is the dumbest register map ever, we'll improve this later.
	wire [31:0] pb_registers[31:0];
	
	wire [17:0] pbInstruction;
	wire [11:0] pbAddress;
	wire pbRomEnable;
	wire [7:0] pbOutput;
	wire [7:0] pbInput;
	wire [7:0] pbPort;
	wire pbKWrite;
	wire pbWrite;
	wire pbRead;
	wire pbInterrupt;
	wire pbInterruptAck;
	wire pbSleep;
	wire pbReset;	
	wire pb_rom_write_protect;
	kcpsm6 processor(.address(pbAddress),.instruction(pbInstruction),
						  .bram_enable(pbRomEnable),
						  .in_port(pbInput),.out_port(pbOutput),.port_id(pbPort),
						  .write_strobe(pbWrite),.read_strobe(pbRead),.k_write_strobe(pbKWrite),
						  .interrupt(pbInterrupt),.interrupt_ack(pbInterruptAck),
						  .sleep(pbSleep),.reset(pbReset),
						  .clk(clk_i));
	rfp_dummy rom(.address(pbAddress),.instruction(pbInstruction), .enable(pbRomEnable),.clk(clk_i),
							  .bram_adr_i(wbc_adr_i[9:2]),
							  .bram_dat_o(pb_bram_dat_o),
							  .bram_dat_i(wbc_dat_i),
							  .bram_we_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && wbc_we_i && !pb_rom_write_protect),
							  .bram_rd_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && !wbc_we_i),
							  .bram_ack_o(pb_bram_ack));
	
	wire [31:0] pb_port_dat_o = pb_registers[wbc_adr_i[6:2]];
	
	reg [1:0] 	pb_control  = {2{1'b0}};
	reg [31:0] 	pb_i2c	   = {32{1'b0}};
	reg [31:0]  pb_inreg	   = {32{1'b0}};
	reg [31:0] 	pb_outreg   = {32{1'b0}};
	reg [31:0]  pb_ram_addr = {32{1'b0}};
	reg [31:0]  pb_debug_1 = {32{1'b0}};
	reg [31:0]  pb_debug_2 = {32{1'b0}};
	reg [31:0]  pb_breakpoint = {32{1'b0}};
	assign pb_registers[0] = {{30{1'b0}}, pb_control};
	assign pb_registers[1] = pb_i2c;
	assign pb_registers[2] = pb_inreg;
	assign pb_registers[3] = pb_outreg;
	assign pb_registers[4] = pb_ram_addr;
	assign pb_registers[5] = pb_debug_1;
	assign pb_registers[6] = pb_debug_2;
	assign pb_registers[7] = pb_breakpoint;
	generate
		genvar pb_dum_i;
		for (pb_dum_i=8;pb_dum_i<32;pb_dum_i = pb_dum_i+1) begin : DUMMY
			assign pb_registers[pb_dum_i] = pb_registers[pb_dum_i % 8];
		end
	endgenerate

	always @(posedge clk_i) begin
		if (pbWrite && !pbPort[7]) begin // PicoBlaze write access. 
			case (pbPort)
				8'h04: begin 
					pb_i2c[0] <= pbOutput[0];	// i2c grant
					pb_i2c[6] <= pbOutput[6];	// persist cyc
				end
				8'h0C: pb_outreg[7:0] <= pbOutput;
				8'h0D: pb_outreg[15:8] <= pbOutput;
				8'h0E: pb_outreg[23:16] <= pbOutput;
				8'h0F: pb_outreg[31:24] <= pbOutput;
				8'h10: pb_ram_addr[7:0] <= pbOutput;
				8'h11: pb_ram_addr[15:8] <= pbOutput;
			endcase
		end	
		if (wbc_cyc_i && wbc_stb_i && pb_port_sel && wbc_we_i) begin
			case (wbc_adr_i[6:2])
				5'h00: pb_control <= wbc_dat_i[1:0]; // reset, sleep
				5'h01: pb_i2c[1]  <= wbc_dat_i[1];   // request I2C bridge
				5'h02: pb_inreg 	<= wbc_dat_i;
			endcase
		end else begin
			if (pb_control[3]) pb_control[3] <= 0;
		end
	end
	
`ifdef PICOBLAZE_DEBUG
	always @(posedge clk_i) begin 
		if (wbc_cyc_i && wbc_stb_i && pb_port_sel && wbc_we_i && (wbc_adr_i[6:2] == 5'h07)) begin
			pb_breakpoint <= wbc_dat_i;
		end else begin
			if (pbAddress == pb_breakpoint[17:0] && pb_breakpoint[18]) begin
				pb_breakpoint[19] <= 1;
			end
			
			if (pb_breakpoint[20]) pb_breakpoint[20] <= 0;
		end

		pb_debug_1 <= {{2'b00},pbInstruction,pbAddress};
		// port and output are static. We need to capture pbInput.
		pb_debug_2[31:24] <= {8{1'b0}};
		pb_debug_2[23:16] <= pbPort;
		pb_debug_2[15:8] <= pbOutput;
		if (pbRead) pb_debug_2[7:0] <= pbInput;
	end
	
	assign pbSleep = pb_control[1] || (pb_breakpoint[19] && !pb_breakpoint[20]);
`else
	assign pbSleep = pb_control[1];
`endif

	always @(posedge clk_i) begin
		if (i2c_ack_i && !pb_i2c[0]) begin
			pb_i2c[2] <= pb_i2c[6];
			pb_i2c[3] <= 0;
			pb_i2c[4] <= 0;
			pb_i2c[5] <= 1;
			pb_i2c[31:24] <= i2c_dat_i;
		end else if (pbPort[7] && (pbWrite || pbRead)) begin
			// I2C txn has been issued, begin cycle
			pb_i2c[2] 	  <= 1;   	 						// cyc
			pb_i2c[3] 	  <= 1;		 						// stb
			pb_i2c[4] 	  <= pbWrite; 						// we
			pb_i2c[5]	  <= 0;								// ack
			pb_i2c[14:8]  <= pbPort[6:0];				// addr
			pb_i2c[23:16] <= pbOutput;					// dat_o
		end
	end
	// Register 0: PicoBlaze control.
	assign pbReset = pb_control[1];
	// Prevent writing to PicoBlaze program unless the processor is in reset.
	assign pb_rom_write_protect = !pbReset;
	// Register 4: I2C control.
	wire i2c_wb_gnt = pb_i2c[0];
	wire i2c_wb_req = pb_i2c[1];
	wire i2c_pb_cyc = pb_i2c[2];
	wire i2c_pb_stb = pb_i2c[3];
	wire i2c_pb_we = pb_i2c[4];
	wire i2c_pb_dat_o = pb_i2c[23:16];
	wire i2c_pb_adr_o = pb_i2c[14:8];
	
	assign i2c_cyc_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_cyc_i : i2c_pb_cyc;
	assign i2c_stb_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_stb_i : i2c_pb_stb;
	assign i2c_we_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_we_i : i2c_pb_we;
	assign i2c_dat_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_dat_i : i2c_pb_dat_o;
	assign i2c_adr_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_adr_i[8:2] : i2c_pb_adr_o;
	
	// So the PicoBlaze I2C transaction method is:
	// if i2c is not granted to external master, 
	// for an interruptible write:
	// 	write to I2C core address with bit 7 also set.
	//    poll 0x04 bit 5
	// for a read:
	//    read from I2C core address with bit 7 also set.
	//    Then poll 0x04 bit 5.
	//    Then read 0x07 for the response.
	// For an *uninterruptible transaction*:
	// write 0x04, bit 6
	// perform transactions as normal
	// clear 0x04, bit 6 before last transaction
	//
	// So for instance:
	// write 0x04, bit 6
	// poll 0x04 bit 5
	// clear 0x04, bit 6
	// write to TX register
	// poll 0x04 bit 5
	// poll I2C status register
	
	// for RFP RAM:
	// assume we take data at 1 kHz or something
	// 12 channels 2x16 bits 12,000 ints/sec. or something like that.
	// 16384x4 should be fine.
	// so 8 bits x 65536
	// and 32 bits x 16384
	rfp_ram u_ram(.clka(clk_i),
					  .wea(pbWrite && (pbPort == 8'h10)),
					  .addra(pbRamAddress),
					  .dina(pbOutput),
					  .clkb(clk_i),
					  .enb(wbc_cyc_i && wbc_stb_i && rfp_ram_sel),
					  .addrb(wbc_adr_i[15:2]),
					  .doutb(rfp_ram_dat_o));
					  
endmodule
