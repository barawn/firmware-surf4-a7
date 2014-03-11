`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:34:27 03/11/2014
// Design Name:   surf4_id_ctrl
// Module Name:   C:/cygwin/home/barawn/repositories/github/firmware-surf4-a7/sim/surf4_id_ctrl_tb.v
// Project Name:  SURF4_A7
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: surf4_id_ctrl
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`include "wishbone.vh"

module surf4_id_ctrl_tb;

	// Inputs
	reg clk_i;
	reg rst_i;
	
	`WB_DEFINE(wb, 32, 16, 4);
	wire pci_interrupt_o;
	wire [30:0] interrupt_i;
	wire pps_o;
	wire pps_sysclk_o;
	wire ext_trig_o;
	wire ext_trig_sysclk_o;
	wire [11:0] internal_led_i;
	
	reg PPS = 0;
	reg EXT_TRIG = 0;
	wire MOSI;
	reg MISO = 0;
	wire CS_B;
	
	wire ICE40_RESET;
	wire [3:0] LED;
	wire FP_LED;
	
	reg LOCAL_CLK = 0;
	wire LOCAL_OSC_EN;
	
	wire FPGA_SST_SEL;
	wire FPGA_SST;
	reg FPGA_TURF_SST = 0;
	
	// Instantiate the Unit Under Test (UUT)
	surf4_id_ctrl uut (
		.clk_i(clk_i), 
		.rst_i(rst_i),
		`WBS_CONNECT(wb, wb),
		.pci_interrupt_o(pci_interrupt_o),
		.interrupt_i(interrupt_i),
		.pps_o(pps_o),
		.pps_sysclk_o(pps_sysclk_o),
		.ext_trig_o(ext_trig_o),
		.ext_trig_sysclk_o(ext_trig_sysclk_o),
		.internal_led_i(internal_led_i),
		.PPS(PPS),
		.EXT_TRIG(EXT_TRIG),
		.MOSI(MOSI),
		.MISO(MISO),
		.CS_B(CS_B),
		.ICE40_RESET(ICE40_RESET),
		.LED(LED),
		.FP_LED(FP_LED),
		.LOCAL_CLK(LOCAL_CLK),
		.LOCAL_OSC_EN(LOCAL_OSC_EN),
		.FPGA_SST_SEL(FPGA_SST_SEL),
		.FPGA_SST(FPGA_SST),
		.FPGA_TURF_SST(FPGA_TURF_SST)
	);

	always begin
		#15 clk_i = ~clk_i;
	end

	initial begin
		// Initialize Inputs
		clk_i = 0;
		rst_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		@(posedge clk_i);
		
	end
endmodule

