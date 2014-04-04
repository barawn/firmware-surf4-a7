`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:58:14 02/28/2014
// Design Name:   wbc_intercon
// Module Name:   C:/cygwin/home/barawn/SURF4/SURF4_A7/sim//wbc_intercon_tb.v
// Project Name:  SURF4_A7
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: wbc_intercon
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`include "wishbone.vh"

module wbc_intercon_tb;

	// Inputs
	reg clk_i;
	reg rst_i;

	reg pcic_cyc_o = 0;
	reg pcic_stb_o = 0;
	reg pcic_we_o = 0;
	reg [19:0] pcic_adr_o = {20{1'b0}};
	reg [31:0] pcic_dat_o = {32{1'b0}};
	reg [3:0] pcic_sel_o = {4{1'b0}};
	wire [31:0] pcic_dat_i;
	wire pcic_ack_i;
	wire pcic_err_i;
	wire pcic_rty_i;

	reg turfc_cyc_o = 0;
	reg turfc_stb_o = 0;
	reg turfc_we_o = 0;
	reg [19:0] turfc_adr_o = {20{1'b0}};
	reg [31:0] turfc_dat_o = {32{1'b0}};
	reg [3:0] turfc_sel_o = {4{1'b0}};
	wire [31:0] turfc_dat_i;
	wire turfc_ack_i;
	wire turfc_err_i;
	wire turfc_rty_i;

	reg hkc_cyc_o = 0;
	reg hkc_stb_o = 0;
	reg hkc_we_o = 0;
	reg [19:0] hkc_adr_o = {20{1'b0}};
	reg [31:0] hkc_dat_o = {32{1'b0}};
	reg [3:0] hkc_sel_o = {4{1'b0}};
	wire [31:0] hkc_dat_i;
	wire hkc_ack_i;
	wire hkc_err_i;
	wire hkc_rty_i;

	reg wbvio_cyc_o = 0;
	reg wbvio_stb_o = 0;
	reg wbvio_we_o = 0;
	reg [19:0] wbvio_adr_o = {20{1'b0}};
	reg [31:0] wbvio_dat_o = {32{1'b0}};
	reg [3:0] wbvio_sel_o = {4{1'b0}};
	wire [31:0] wbvio_dat_i;
	wire wbvio_ack_i;
	wire wbvio_err_i;
	wire wbvio_rty_i;

	reg ack;
	`WB_DEFINE(s4_id_ctrl, 32, 20, 4);
	assign s4_id_ctrl_ack_i = ack;
	always @(posedge clk_i) begin
		ack <= s4_id_ctrl_stb_o && s4_id_ctrl_cyc_o;
	end
	assign s4_id_ctrl_err_i = 0;
	assign s4_id_ctrl_rty_i = 0;
	assign s4_id_ctrl_dat_i = {32{1'b0}};
	

	
	
	// Instantiate the Unit Under Test (UUT)
	wbc_intercon uut (
		.clk_i(clk_i), 
		.rst_i(rst_i),
		`WBS_CONNECT(pcic, pcic),
		`WBS_CONNECT(turfc, turfc),
		`WBS_CONNECT(hkc, hkmc),
		`WBS_CONNECT(wbvio, wbvio),
		`WBM_CONNECT(s4_id_ctrl, s4_id_ctrl)
	);
	always begin
		#5 clk_i = ~clk_i;
	end
	
	initial begin
		// Initialize Inputs
		clk_i = 0;
		rst_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		// Fake a PCIC cycle.
		@(posedge clk_i);
		pcic_cyc_o = 1;
		pcic_stb_o = 1;
		pcic_adr_o = 20'h11234;
		pcic_dat_o = 32'h12345678;
		turfc_cyc_o = 1;
		turfc_stb_o = 1;
		turfc_adr_o = 20'h05678;
		turfc_dat_o = 32'h9ABCDEF0;
		while (pcic_cyc_o || turfc_cyc_o) begin
			@(posedge clk_i);
			if (pcic_ack_i) begin
				pcic_cyc_o <= 0;
				pcic_stb_o <= 0;
			end
			if (turfc_ack_i) begin
				turfc_cyc_o <= 0;
				turfc_stb_o <= 0;
			end
		end
	end
 
	
 
endmodule

