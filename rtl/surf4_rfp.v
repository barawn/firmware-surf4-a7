`timescale 1ns / 1ps
`include "wishbone.vh"
`define PICOBLAZE_DEBUG
module surf4_rfp(
		input clk_i,
		input rst_i,
		`WBS_NAMED_PORT(wbc, 32, 19, 4),
		`WBM_NAMED_PORT(i2c, 8, 7, 1),
		input pps_i
    );

	// We have a 19-bit (8-bit) address space, but we can only use 0x00000-0x5FFFF.
	// Partitioning:
	// 0x0000-0x007F : shared port space with PicoBlaze
	// 0x0080-0x00FF : (shadowed with 00-0x7F)
	// PicoBlaze runs off of 1 BRAM, which is 18k, or 18 bits at 1024 instructions.
	// Let's map the BRAM to 1024 addresses, or 4096 byte addresses: 0xFFF space needed.
	// 0x0100-0x04FF : PicoBlaze BRAM (write-protected by bit in shared port space)
	// Then we'll map the I2C bus (which needs 7 bits of address space)
	// into 0x500-0x6FF. Only the low byte will be used.
	
	// The RFP data can be stored in 0x1000-0x1FFFF.
	// 0x0000-0x00FF : PicoBlaze registers  - shadowed at 0x0100 and 0x0800 and 0x0900 (
	// 0x0200-0x03FF : I2C bus              
	// 0x1000-0x1FFF : PicoBlaze BRAM
	// 0x8000-0xFFFF : RFP RAM
	// Then we'll just shadow the remaining addresses.
	wire [18:0] pb_port_bar		= 19'h00000;			
	wire [18:0] i2c_port_bar	= 19'h00200;
	wire [18:0] pb_bram_bar		= 19'h00400;
	wire [18:0] rfp_ram_bar 	= 19'h10000;

	wire [18:0] pb_port_mask	= 19'h769FF;      	// match xxx 0xx0 x00x xxxx xxxx
	wire [18:0] i2c_port_mask	= 19'h769FF;			// match xxx 0xx0 x01x xxxx xxxx
	wire [18:0] pb_bram_mask	= 19'h76FFF;			// match xxx 0xx1 xxxx xxxx xxxx
	wire [18:0] rfp_ram_mask 	= 19'h77FFF;			// match xxx 1xxx xxxx xxxx xxxx

	wire pb_port_sel 	= (wbc_adr_i & ~pb_port_mask) == pb_port_bar;
	wire i2c_port_sel = (wbc_adr_i & ~i2c_port_mask) == i2c_port_bar;
	wire pb_bram_sel 	= (wbc_adr_i & ~pb_bram_mask) == pb_bram_bar;
	wire rfp_ram_sel = (wbc_adr_i & ~rfp_ram_mask) == rfp_ram_bar;

	wire pb_port_ack;
	wire pb_port_err = 0;
	wire pb_port_rty = 0;
	wire [31:0] pb_port_dat_o;
	wire pb_bram_ack;
	wire pb_bram_rty = 0;
	wire pb_bram_err = 0;
	wire [31:0] pb_bram_dat_o;
	wire rfp_ram_ack;
	wire rfp_ram_rty = 0;
	wire rfp_ram_err = 0;
	wire [31:0] rfp_ram_dat_o;
	
	
	// PicoBlaze has 32 32-bit registers shared with WISHBONE.
	// This is the dumbest register map ever, we'll improve this later.
	wire [31:0] pb_registers[31:0];
	
	wire [17:0] pbInstruction;
	wire [11:0] pbAddress;
	wire pbRomEnable;
	wire [7:0] pbOutput;
	reg [7:0] pbInput;
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
	wire [17:0] rom_dat_o;
	assign pb_bram_dat_o[17:0] = rom_dat_o;
	assign pb_bram_dat_o[31:18] = {14{1'b0}};
	rfp_dummy rom(.address(pbAddress),.instruction(pbInstruction), .enable(pbRomEnable),.clk(clk_i),
							  .bram_adr_i(wbc_adr_i[11:2]),
							  .bram_dat_o(rom_dat_o),
							  .bram_dat_i(wbc_dat_i[17:0]),
							  .bram_we_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && wbc_we_i && !pb_rom_write_protect),
							  .bram_rd_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && !wbc_we_i),
							  .bram_ack_o(pb_bram_ack));
	
	assign pb_port_dat_o = pb_registers[wbc_adr_i[6:2]];
	
	reg [1:0] 	pb_control  = {2{1'b0}};
	reg [31:0] 	pb_i2c	   = {32{1'b0}};
	reg [31:0]  pb_inreg	   = {32{1'b0}};
	reg [31:0] 	pb_outreg   = {32{1'b0}};
	reg [15:0]  pb_ram_addr = {16{1'b0}};
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
	reg pb_ack = 0;
	assign pb_port_ack = pb_ack;
	
	generate
		genvar pb_dum_i;
		for (pb_dum_i=8;pb_dum_i<32;pb_dum_i = pb_dum_i+1) begin : DUMMY
			assign pb_registers[pb_dum_i] = pb_registers[pb_dum_i % 8];
		end
	endgenerate

	always @(*) begin
		case (pbPort[1:0])
			2'b00: pbInput <= pb_registers[pbPort[6:2]][7:0];
			2'b01: pbInput <= pb_registers[pbPort[6:2]][15:8];
			2'b10: pbInput <= pb_registers[pbPort[6:2]][23:16];
			2'b11: pbInput <= pb_registers[pbPort[6:2]][31:24];
		endcase
	end

	always @(posedge clk_i) begin
		pb_ack <= pb_port_sel && wbc_cyc_i && wbc_stb_i;
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
		end 
	end
// The PicoBlaze debug interface here generates single-stepping through a breakpoint:
// if the address matches, pb_breakpoint[19] is set, and the PicoBlaze sleeps.
// Then, when pb_breakpoint[20] is set, for 1 cycle, the PicoBlaze wakes up.
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
   // Prevent writing to PicoBlaze program unless the process is in reset or sleeping.
	// The 'sleep' case allows the horrible mechanism of altering the program code while
	// single stepping, for Ultimate Debugging Power.
	assign pb_rom_write_protect = !(pbReset || pbSleep);
	assign pbSleep = pb_control[1] || (pb_breakpoint[19] && !pb_breakpoint[20]);
`else
	assign pbSleep = pb_control[1];
	// Prevent writing to PicoBlaze program unless the processor is in reset.
	assign pb_rom_write_protect = !pbReset;
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
	assign i2c_dat_o = (i2c_wb_gnt && i2c_port_sel) ? wbc_dat_i[7:0] : i2c_pb_dat_o;
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
					  .addra(pb_ram_addr),
					  .dina(pbOutput),
					  .clkb(clk_i),
					  .enb(wbc_cyc_i && wbc_stb_i && rfp_ram_sel),
					  .addrb(wbc_adr_i[15:2]),
					  .doutb(rfp_ram_dat_o));
	reg ram_ack = 0;
	always @(posedge clk_i) ram_ack <= rfp_ram_sel;
	assign rfp_ram_ack = ram_ack;
	
	reg muxed_ack;
	reg muxed_rty;
	reg muxed_err;
	reg [31:0] muxed_dat_o;
	always @(*) begin
		if (pb_port_sel) begin
			muxed_ack <= pb_port_ack;
			muxed_rty <= pb_port_rty;
			muxed_err <= pb_port_err;
			muxed_dat_o <= pb_port_dat_o;
		end else if (i2c_port_sel) begin
			muxed_ack <= i2c_ack_i;
			muxed_rty <= i2c_rty_i;
			muxed_err <= i2c_err_i;
			muxed_dat_o <= {{24{1'b0}},i2c_dat_i};
		end else if (pb_bram_sel) begin
			muxed_ack <= pb_bram_ack;
			muxed_rty <= pb_bram_rty;
			muxed_err <= pb_bram_err;
			muxed_dat_o <= pb_bram_dat_o;
		end else begin
			muxed_ack <= rfp_ram_ack;
			muxed_rty <= rfp_ram_rty;
			muxed_err <= rfp_ram_err;
			muxed_dat_o <= rfp_ram_dat_o;
		end
	end
	assign wbc_ack_o = muxed_ack;
	assign wbc_err_o = muxed_err;
	assign wbc_rty_o = muxed_rty;
	assign wbc_dat_o = muxed_dat_o;
   assign i2c_sel_o = 1'b0;				  
endmodule
