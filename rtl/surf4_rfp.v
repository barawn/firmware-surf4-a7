`timescale 1ns / 1ps
`include "wishbone.vh"
module surf4_rfp(
		input wbc_clk_i,
		input wbc_rst_i,
		`WBS_NAMED_PORT(wbc, 32, 16, 4),
		`WBM_NAMED_PORT(i2c, 8, 7, 1),
		input pps_i
    );

	// We have a 16-bit (8-bit) address space, so let's partition it up into:
	// 0x0000-0x007F : shared port space with PicoBlaze
	// 0x0080-0x00FF : (shadowed with 00-0x7F)
	// PicoBlaze runs off of 1 BRAM, which is 18k, or 18 bits at 1024 instructions.
	// Let's map the BRAM to 1024 addresses, or 4096 byte addresses: 0x3FF space needed.
	// 0x0100-0x04FF : PicoBlaze BRAM (write-protected by bit in shared port space)
	// Then we'll map the I2C bus (which needs 7 bits of address space)
	// into 0x500-0x6FF. Only the low byte will be used.
	
	// The RFP data can be stored in 0x8000-0xFFFF.
	// 0x0000-0x00FF : PicoBlaze registers  - shadowed at 0x0100 and 0x0800 and 0x0900 (
	// 0x0200-0x03FF : I2C bus              
	// 0x0400-0x05FF : PicoBlaze BRAM 
	// 0x8000-0xFFFF : RFP RAM
	wire [15:0] pb_port_bar		= 16'h0000;			
	wire [15:0] i2c_port_bar	= 16'h0200;
	wire [15:0] pb_bram_bar		= 16'h0400;
	wire [15:0] rfp_ram_bar 	= 16'h8000;
	
	wire [15:0] pb_port_mask	= 16'h79FF;      	// match 0xxx x00x xxxx xxxx
	wire [15:0] i2c_port_mask	= 16'h79FF;			// match 0xxx x01x xxxx xxxx
	wire [15:0] pb_bram_mask	= 16'h7BFF;			// match 0xxx x1xx xxxx xxxx
	wire [15:0] rfp_ram_mask 	= 16'h7FFF;			// match 1xxx xxxx xxxx xxxx

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
	rfp_program_rom rom(.address(pbAddress),.instruction(pbInstruction), .enable(pbRomEnable),.clk(clk_i),
							  .bram_adr_i(wbc_adr_i[9:2]),
							  .bram_dat_o(pb_bram_dat_o),
							  .bram_dat_i(wbc_dat_i),
							  .bram_we_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && wbc_we_i && !pb_rom_write_protect),
							  .bram_rd_i(wbc_cyc_i && wbc_stb_i && pb_bram_sel && !wbc_we_i),
							  .bram_ack_o(pb_bram_ack));
	
	wire [31:0] pb_port_dat_o = pb_registers[wbc_adr_i[6:2]];
	
	reg [1:0] 	pb_control = {2{1'b0}};
	reg [31:0] 	pb_i2c	  = {32{1'b0}};
	reg [31:0]  pb_inreg	  = {32{1'b0}};
	reg [31:0] 	pb_outreg  = {32{1'b0}};
	assign pb_registers[0] = {{30{1'b0}}, pb_control};
	assign pb_registers[1] = pb_i2c;
	assign pb_registers[2] = pb_inreg;
	assign pb_registers[3] = pb_outreg;
	generate
		genvar pb_dum_i;
		for (pb_dum_i=4;pb_dum_i<32;pb_dum_i = pb_dum_i+1) begin : DUMMY
			assign pb_registers[pb_dum_i] = {32{1'b0}};
		end
	endgenerate
	


	always @(posedge clk_i) begin
		if (pbWrite && !pbPort[7]) begin // PicoBlaze write access. 
			case (pbPort)
				8'h04: begin 
					pb_i2c[0] <= pbOutput[0];
					pb_i2c[6] <= pbOutput[6];
				end
				8'h0C: pb_outreg[7:0] <= pbOutput;
				8'h0D: pb_outreg[15:8] <= pbOutput;
				8'h0E: pb_outreg[23:16] <= pbOutput;
				8'h0F: pb_outreg[31:24] <= pbOutput;
			endcase
		end
	
		if (wbc_cyc_i && wbc_stb_i && pb_port_sel && wbc_we_i) begin
			case (wbc_adr_i[6:2])
				5'h00: pb_control <= wbc_dat_i[1:0]; // reset and sleep
				5'h01: pb_i2c[1]  <= wbc_dat_i[1];   // request I2C bridge
				5'h02: pb_inreg 	<= wbc_dat_i;
			endcase
		end
	end
	
	
	always @(posedge clk_i) begin
		if (pbWrite && !pbPort[7]) begin
			case (pbPort[1:0])
				2'b00: pb_registers[pbPort[6:2]][7:0] <= pbOutput;
				2'b01: pb_registers[pbPort[6:2]][7:0] <= pbOutput;
				2'b10: pb_registers[pbPort[6:2]][7:0] <= pbOutput;
				2'b11: pb_registers[pbPort[6:2]][7:0] <= pbOutput;
			endcase
		end else if (wbc_cyc_i && wbc_stb_i && pb_port_sel && wbc_we_i) begin
			pb_registers[wbc_adr_i[6:2]] <= wbc_dat_i;
		end else begin
			if (i2c_ack_i && !pb_registers[1][1]) begin
				pb_registers[1][2]	  <= pb_registers[1][6];		// if '1', we hold the bus.
				pb_registers[1][3]	  <= 0;
				pb_registers[1][4]	  <= 0;
				pb_registers[1][5]	  <= 1;
				pb_registers[1][31:24] <= i2c_dat_i;					// dat_i capture
			end else if (pbPort[7] && (pbWrite || pbRead)) begin
				// I2C txn has been issued, begin cycle
				pb_registers[1][2] 	  <= 1;   	 						// cyc
				pb_registers[1][3] 	  <= 1;		 						// stb
				pb_registers[1][4] 	  <= pbWrite; 						// we
				pb_registers[1][5]	  <= 0;								// ack
				pb_registers[1][14:8]  <= pb_port[6:0];				// addr
				pb_registers[1][23:16] <= pb_output;					// dat_o
			end
		end
	end
	// Register 0: PicoBlaze control.
	assign pbReset = pb_registers[0][0];
	assign pbSleep = pb_registers[0][1];	
	// Prevent writing to PicoBlaze program unless the processor is in reset.
	assign pb_rom_write_protect = !pbReset;
	// Register 4: I2C control.
	wire i2c_pb_busy = pb_registers[1][0];
	wire i2c_cpci_busy = pb_registers[1][1];
	wire i2c_pb_cyc = pb_registers[1][2];
	wire i2c_pb_stb = pb_registers[1][3];
	wire i2c_pb_we = pb_registers[1][4];
	wire i2c_pb_dat_o = pb_registers[1][23:16];
	wire i2c_pb_adr_o = pb_registers[1][14:8];
	
	assign i2c_cyc_o = (pb_registers[1][1] && i2c_port_sel) ? wbc_cyc_i : i2c_pb_cyc;
	assign i2c_stb_o = (pb_registers[1][1] && i2c_port_sel) ? wbc_stb_i : i2c_pb_stb;
	assign i2c_we_o = (pb_registers[1][1] && i2c_port_sel) ? wbc_we_i : i2c_pb_we;
	assign i2c_dat_o = (pb_registers[1][1] && i2c_port_sel) ? wbc_dat_i : i2c_pb_dat_o;
	assign i2c_adr_o = (pb_registers[1][1] && i2c_port_sel) ? wbc_adr_i[8:2] : i2c_pb_adr_o;
	
	// So the PicoBlaze I2C transaction method is:
	// check register 4, bit 2
	// set register 4, bit 1
	// 
	
endmodule
