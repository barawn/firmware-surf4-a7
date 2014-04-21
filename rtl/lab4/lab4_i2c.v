`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// This file is a part of the Antarctic Impulsive Transient Antenna (ANITA)
// project, a collaborative scientific effort between multiple institutions. For
// more information, contact Peter Gorham (gorham@phys.hawaii.edu).
//
// All rights reserved.
//
// Author: Patrick Allison, Ohio State University (allison.122@osu.edu)
// Author:
// Author:
////////////////////////////////////////////////////////////////////////////////

// Provides an interface to set the LAB4 I2C DACs. 
//
// Right now we're going to make things very simple - to write to a DAC,
// you need to write them one-by-one, and wait for the ACK. This shouldn't
// be a problem.
//
// Two interfaces here: a WISHBONE clock domain one, and a system clock domain
// one. The system clock domain has priority in timing.
//
`include "wishbone.vh"
module lab4_i2c(
		input clk_i,
		input rst_i,
		
		input cyc_i,
		input stb_i,
		input we_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		output ack_o,
		
		input sysclk_i,
		input syswr_i,
		input [31:0] sysdat_i,
		output [31:0] sysdat_o,
		
		`WBM_NAMED_PORT(i2c, 8, 7, 1),

		output [70:0] debug_o
    );

	// 32-bit control register:
	// [11:0] data value to write to DAC
	// [15:12] DAC address (only 0-11 are allowed: others ignored)
	// [19:16] LAB address (only 0-11 are allowed: others ignored)
	// [20]    update in progress. Must be set when written! When readback as 0, operation complete.
	reg [31:0] wbclk_register = {32{1'b0}};
	reg [31:0] sysclk_register = {32{1'b0}};
	// sysclk_register in the SYSCLK domain
	reg [31:0] sysclk_register_SYSCLK = {32{1'b0}};
	// acknowledge on WISHBONE
	reg ack = 0;
	
	// indicates that the wbclk_register operation is complete
	wire pb_wbclk_ack;
	// ack, in the wbclk domain, indicating that the sysclk_register operation is complete
	wire pb_sysclk_ack;
	// ack, in the sysclk domain, indicating that the sysclk_register operation is complete
	wire pb_sysclk_ack_SYSCLK;
	// syswr in the wbclk domain
	wire syswr_WBCLK;
	
	always @(posedge clk_i) begin
		if (cyc_i && stb_i && we_i && !wbclk_register[20]) wbclk_register[19:0] <= dat_i[19:0]; 
		if (pb_wbclk_ack) wbclk_register[20] <= 0;
		else if (cyc_i && stb_i && we_i) wbclk_register[20] <= dat_i[20];
		
		ack <= cyc_i && stb_i;
	end
	
	always @(posedge sysclk_i) begin
		if (syswr_i) sysclk_register_SYSCLK[19:0] <= sysdat_i[19:0];
		if (pb_sysclk_ack_SYSCLK) sysclk_register_SYSCLK[20] <= 0;
		else if (syswr_i) sysclk_register_SYSCLK[20] <= sysdat_i[20];
	end

	flag_sync u_syswr(.clkA(sysclk_i),.clkB(clk_i),.in_clkA(syswr_i),.out_clkB(syswr_WBCLK));
	always @(posedge clk_i) begin
		if (syswr_WBCLK) sysclk_register[19:0] <= sysclk_register_SYSCLK[19:0];
		if (pb_sysclk_ack) sysclk_register[20] <= 0;
		else if (syswr_WBCLK) sysclk_register[20] <= sysclk_register_SYSCLK[20];
	end
	flag_sync u_sysclk_ack(.clkA(clk_i),.clkB(sysclk_i),.in_clkA(pb_sysclk_ack),.out_clkB(pb_sysclk_ack_SYSCLK));	

	// PicoBlaze
	wire [17:0] pbInstruction;
	wire [11:0] pbAddress;
	wire pbRomEnable;
	wire [7:0] pbOutput;
	wire [7:0] pbInput;
	wire [7:0] pbPort;
	wire pbKWrite;
	wire pbDWrite;
	wire pbWrite = (pbKWrite || pbDWrite);
	wire pbRead;
	wire pbInterrupt;
	wire pbInterruptAck;
	wire pbSleep;
	wire pbReset;	
	wire pb_rom_write_protect;
	
	kcpsm6 processor(.address(pbAddress),.instruction(pbInstruction),
						  .bram_enable(pbRomEnable),
						  .in_port(pbInput),.out_port(pbOutput),.port_id(pbPort),
						  .write_strobe(pbDWrite),.read_strobe(pbRead),.k_write_strobe(pbKWrite),
						  .interrupt(pbInterrupt),.interrupt_ack(pbInterruptAck),
						  .sleep(pbSleep),.reset(pbReset),
						  .clk(clk_i));
	l4_i2c_rom rom(.address(pbAddress),.instruction(pbInstruction), .enable(pbRomEnable),.clk(clk_i));

	wire [7:0] pb_registers_bytemux[3:0];
	wire [31:0] pb_registers[3:0];
	assign pb_registers_bytemux[0] = pb_registers[pbPort[3:2]][0 +: 8];
	assign pb_registers_bytemux[1] = pb_registers[pbPort[3:2]][8 +: 8];
	assign pb_registers_bytemux[2] = pb_registers[pbPort[3:2]][16 +: 8];
	assign pb_registers_bytemux[3] = pb_registers[pbPort[3:2]][24 +: 8];
	assign pbInput = pb_registers_bytemux[pbPort[1:0]];
	
	reg [31:0] pb_i2c = {32{1'b0}};
	assign pb_registers[0] = wbclk_register;
	assign pb_registers[1] = sysclk_register;
	assign pb_registers[2] = pb_i2c;
	assign pb_registers[3] = pb_i2c;
	assign pb_wbclk_ack = (pbWrite && (pbPort[3:0] == 4'h2) && pbOutput[4]);
	assign pb_sysclk_ack = (pbWrite && (pbPort[3:0] == 4'h6) && pbOutput[4]);
	
	always @(posedge clk_i) begin
		if (pbWrite && (pbPort[3] && (pbPort[1:0] == 2'b00))) pb_i2c[6] <= pbOutput[6];
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
	assign i2c_cyc_o = pb_i2c[2];
	assign i2c_stb_o = pb_i2c[3];
	assign i2c_we_o = pb_i2c[4];
	assign i2c_dat_o = pb_i2c[23:16];
	assign i2c_adr_o = pb_i2c[14:8];

	assign dat_o = wbclk_register;
	assign ack_o = ack;
	assign sysdat_o = sysclk_register_SYSCLK;

	assign debug_o[0 +: 12] = pbAddress;
	assign debug_o[12 +: 8] = (pbWrite) ? pbOutput : pbInput;
	assign debug_o[20] = pbWrite;
	assign debug_o[21] = pbRead;
	assign debug_o[22 +: 8] = pbPort;
	assign debug_o[30 +: 8] = (i2c_we_o) ? i2c_dat_o : i2c_dat_i;
	assign debug_o[38 +: 7] = i2c_adr_o;
	assign debug_o[45] = i2c_cyc_o;
	assign debug_o[46] = i2c_stb_o;
	assign debug_o[47] = i2c_we_o;
	assign debug_o[48] = i2c_ack_i;
	assign debug_o[49] = wbclk_register[20];
	assign debug_o[50] = sysclk_register[20];
	
endmodule
