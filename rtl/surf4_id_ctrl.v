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


// SURF4 ID and Control Block.
//
// This module contains:
//
// *) Device ID register
// *) Firmware ID register
// *) a few general purpose I/O registers (clock selection, internal PPS selection,
//    iCE40 reset)
// *) LED output charlieplexer
// *) SPI flash WISHBONE module.
//
// Module memory map:
// Internal address range is 0x0000-0xFFFF.
// 0x0000: Device ID   ('S4A7')
// 0x0004: Firmware ID (standard board rev/day/month/major/minor/revision packing)
// 0x0008: Interrupt service register.
// 0x000C: Interrupt mask register.
// 0x0010: PPS selection register.
// 0x0014: Reset register (iCE40/Global reset)
// 0x0018: LED output/override register.
// 0x001C: Clock selection register (FPGA_SST_SEL, LOCAL_OSC_EN, and clock detection).
// 0x0020: MMCM/PLL control register for internal SST generation.
// 0x0024: SPI core slave select output register.
// 0x0028-2C: Reserved.
// 0x0030-0x003F: Simple SPI core.
// 0x0200-0x03FF: Dynamic Reconfiguration Port for internal SST generation.
//                Mainly reserved, maybe we'll add it at some point.
//
// *Note*: In order to use the SPI flash, the internal CCLK signal needs a few dummy
//         cycles to switch over from the internal configuration clock. To do this,
//         execute a dummy SPI transaction with the Slave Select pin high (bit 0 in
//         register 0x0030 = 0) before performing any real SPI transactions.
`include "wishbone.vh"
module surf4_id_ctrl(
		input clk_i,
		input rst_i,
		`WBS_NAMED_PORT(wb, 32, 16, 4),
		output pci_interrupt_o,
		input [30:0] interrupt_i, 

		output pps_o,
		output pps_sysclk_o,
		
		output ext_trig_o,
		output ext_trig_sysclk_o,
		
		input [11:0] internal_led_i,

		output sys_clk_o,
		output local_clk_o,
		
		input [11:0] wclk_en_i,		

		// PPS.
		input PPS,

		// Ext trig.
		input EXT_TRIG,
		// SPI
		output MOSI,
		input MISO,
		output CS_B,
		output ICE40_RESET,

		inout [3:0] LED,
		output FP_LED,
		input LOCAL_CLK,
		output LOCAL_OSC_EN,
		inout FPGA_SST_SEL,
		output FPGA_SST,
		input FPGA_TURF_SST,
		output [11:0] L4_WCLK_P,
		output [11:0] L4_WCLK_N
    );

		parameter DEVICE = "S4A7";
		parameter VERSION = 32'h00000000;

		reg wb_ack_mux;
		reg [31:0] wb_data_out_mux;
		// Our internal space is 4 bits wide = 16 registers (5:2 only matter).
		// The last 4 are really the SPI core, and the 2 before that are reserved.
		wire [31:0] wishbone_registers[15:0];

		reg [31:0] int_sr_reg = {32{1'b0}};
		reg [31:0] int_mask_reg = {32{1'b0}};
		reg [31:0] pps_sel_reg = {32{1'b0}};
		reg [31:0] reset_reg = {32{1'b0}};
		reg [31:0] led_reg = {32{1'b0}};
		reg [31:0] clocksel_reg = {32{1'b0}};
		reg [31:0] pllctrl_reg = {32{1'b0}};
		reg [31:0] spiss_reg = {32{1'b0}};
		reg internal_ack = 0;
		
		wire [31:0] pll_drp_dat_o; 
		wire pll_drp_select = (wb_adr_i[9]);

		wire [31:0] spi_dat_o;
		wire spi_ack_o;
		wire spi_inta_o;
		wire spi_select = (wb_adr_i[7:4] == 4'h3) && (!wb_adr_i[9]);
		wire spi_sck;
		wire spi_cyc = wb_cyc_i && spi_select;
		
		// Sysclk/Wclk generation.
		wire wclk_p;
		wire wclk_n;
		wire mmcm_locked;
		wire mmcm_reset;
		wire mmcm_fb_out;
		wire mmcm_fb_in = mmcm_fb_out;
		wire mmcm_power_down;
		wire mmcm_clock_select;
		wire mmcm_clkfbstopped;
		wire mmcm_clkinstopped;
		always @(posedge clk_i) begin
			internal_ack <= wb_cyc_i && wb_stb_i && !(pll_drp_select || spi_select);
		end

		always @(*) begin
			if (pll_drp_select) wb_data_out_mux <= pll_drp_dat_o;
			else if (spi_select) wb_data_out_mux <= spi_dat_o;
			else wb_data_out_mux <= wishbone_registers[wb_adr_i[5:2]];
		end
		always @(*) begin
			if (spi_select) wb_ack_mux <= spi_ack_o;
			else wb_ack_mux <= internal_ack;
		end
		assign wb_ack_o = wb_ack_mux && wb_cyc_i;
		assign wb_dat_o = wb_data_out_mux;
		assign wb_err_o = 0;
		assign wb_rty_o = 0;
		// BASE needs to be defined to convert the base address into an index.
		localparam BASEWIDTH = 4;
		function [BASEWIDTH-1:0] BASE;
				input [15:0] bar_value;
				begin
						BASE = bar_value[5:2];
				end
		endfunction
		`define OUTPUT(addr, x, range, dummy)																				\
					assign wishbone_registers[ addr ] range = x
		`define SELECT(addr, x, dummy, dummy)																			\
					wire x;																											\
					localparam [BASEWIDTH-1:0] addr_``x = addr;															\
					assign x = (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && (BASE(wb_adr_i) == addr_``x))
		`define OUTPUTSELECT(addr, x, y, dummy)																		\
					wire y;																											\
					localparam [BASEWIDTH-1:0] addr_``y = addr;															\
					assign y = (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && (BASE(wb_adr_i) == addr_``y));	\
					assign wishbone_registers[ addr ] = x

		`define SIGNALRESET(addr, x, range, resetval)																	\
					always @(posedge clk_i) begin																			\
						if (rst_i) x <= resetval;																				\
						else if (wb_cyc_i && wb_stb_i && wb_we_i && (BASE(wb_adr_i) == addr))		\
							x <= wb_dat_i range;																						\
					end																												\
					assign wishbone_registers[ addr ] range = x
		`define WISHBONE_ADDRESS( addr, name, TYPE, par1, par2 )														\
					`TYPE(BASE(addr), name, par1, par2)

		// Sleaze at first. Just make all the registers 32 bit.
		`WISHBONE_ADDRESS( 16'h0000, DEVICE, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0004, VERSION, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0008, int_sr_reg, OUTPUTSELECT, sel_int_sr_reg, 0);
		`WISHBONE_ADDRESS( 16'h000C, int_mask_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0010, pps_sel_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0014, reset_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0018, led_reg, OUTPUTSELECT, sel_led_reg, 0);
		`WISHBONE_ADDRESS( 16'h001C, clocksel_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0020, pllctrl_reg, OUTPUTSELECT, sel_pllctrl_reg, 0);
		`WISHBONE_ADDRESS( 16'h0024, spiss_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0028, {32{1'b0}}, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h002C, {32{1'b0}}, OUTPUT, [31:0], 0);
		// Shadow registers - never accessed (the SPI core takes over). Just here to make decoding easier.
		`WISHBONE_ADDRESS( 16'h0030, pps_sel_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0034, reset_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0038, led_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h003C, clocksel_reg, OUTPUT, [31:0], 0);
		

		//% Interrupt status register. Bits cleared by writing a 1 to them.
		always @(posedge clk_i) begin : INTERRUPT_STATUS_REGISTER
			if (rst_i) int_sr_reg <= {32{1'b0}};
			else begin
				if (sel_int_sr_reg) int_sr_reg <= int_sr_reg & ~wb_dat_i;
				else int_sr_reg <= {interrupt_i, spi_inta_o};
			end
		end
		//% LED register. If the override is set, then use the written value.
		always @(posedge clk_i) begin : LED_REGISTER
			if (rst_i) led_reg <= {32{1'b0}};
			else begin
				if (sel_led_reg) begin
					led_reg[31:16] <= wb_dat_i[31:16];
					led_reg[11:0] <= (wb_dat_i[11:0] & wb_dat_i[27:16]) | (internal_led_i[11:0] & ~wb_dat_i[27:16]);
					led_reg[15:12] <= wb_dat_i[15:12];
				end else begin
					led_reg[11:0] <= led_reg[11:0] | (internal_led_i[11:0] & ~wb_dat_i[27:16]);
				end
			end
		end
		//% PLL control register.
		always @(posedge clk_i) begin : PLLCTRL_REGISTER
			if (sel_pllctrl_reg) begin
				pllctrl_reg[0] <= wb_dat_i[0]; 		// reset
				pllctrl_reg[1] <= wb_dat_i[1];		// clock select
				pllctrl_reg[2] <= wb_dat_i[2];		// power down
			end
			pllctrl_reg[3] <= mmcm_locked;
			pllctrl_reg[4] <= mmcm_clkfbstopped;
			pllctrl_reg[5] <= mmcm_clkinstopped;
		end
		assign mmcm_reset = pllctrl_reg[0];
		assign mmcm_clock_select = pllctrl_reg[1];
		assign mmcm_power_down = pllctrl_reg[2];

		simple_spi_top u_spi(.clk_i(clk_i),
							  .rst_i(~rst_i),
							  .inta_o(spi_inta_o),
							  .cyc_i(spi_cyc),
							  .stb_i(wb_stb_i),
							  .we_i(wb_we_i),
							  .adr_i(wb_adr_i[3:2]),
							  .dat_i(wb_dat_i[7:0]),
							  .dat_o(spi_dat_o[7:0]),
							  .ack_o(spi_ack_o),
							  .sck_o(spi_sck),
							  .mosi_o(MOSI),
							  .miso_i(MISO));
		STARTUPE2 #(.PROG_USR("FALSE")) u_startupe2(.CLK(1'b0),
									 .GSR(1'b0),
									 .GTS(1'b0),
									 .KEYCLEARB(1'b0),
									 .PACK(1'b0),
									 .USRCCLKO(spi_sck),
									 .USRCCLKTS(1'b0),
									 .USRDONEO(1'b1),
									 .USRDONETS(1'b1));
	
		
		// LED register:
		// bits [27:16]: override internal LED values and replace with written values.
		// bits 11:0: either current state of internal LEDs, or overridden values.
		// bit 12: FP_LED
		
		reg [3:0] counter = {4{1'b0}};
		always @(posedge clk_i) begin
			if (counter == 11) counter <= {4{1'b0}};
			counter <= counter + 1;
		end
		
		reg [3:0] led_out = {4{1'b0}};
		reg [3:0] led_oen = {4{1'b1}};
		
		always @(posedge clk_i) begin
			case (counter)
				// 0-5 are green, 6-11 are red.
				0: if (led_reg[0]) begin led_out <= 4'b0001; led_oen <= 4'b0110; end // 0-3
							else		 led_oen <= 4'b1111;
				1: if (led_reg[1]) begin led_out <= 4'b0010; led_oen <= 4'b0101; end // 1-3
							else		 led_oen <= 4'b1111;
				2: if (led_reg[2]) begin led_out <= 4'b0100; led_oen <= 4'b0011; end // 2-3
							else		 led_oen <= 4'b1111;
				3: if (led_reg[3]) begin led_out <= 4'b0001; led_oen <= 4'b1010; end // 0-2
							else		 led_oen <= 4'b1111;
				4: if (led_reg[4]) begin led_out <= 4'b0010; led_oen <= 4'b1001; end // 1-2
							else		 led_oen <= 4'b1111;
				5: if (led_reg[5]) begin led_out <= 4'b0001; led_oen <= 4'b1100; end // 0-1
							else		 led_oen <= 4'b1111;
				6: if (led_reg[6]) begin led_out <= 4'b1000; led_oen <= 4'b0110; end // 3-0
							else		 led_oen <= 4'b1111;
				7: if (led_reg[7]) begin led_out <= 4'b1000; led_oen <= 4'b0101; end // 3-1
							else		 led_oen <= 4'b1111;
				8: if (led_reg[8]) begin led_out <= 4'b1000; led_oen <= 4'b0011; end // 3-2
							else		 led_oen <= 4'b1111;
				9: if (led_reg[9]) begin led_out <= 4'b0100; led_oen <= 4'b1010; end // 2-0
							else		 led_oen <= 4'b1111;
				10: if (led_reg[10]) begin led_out <= 4'b0100; led_oen <= 4'b1001; end // 2-1
							else		 led_oen <= 4'b1111;
				11: if (led_reg[11]) begin led_out <= 4'b0010; led_oen <= 4'b1100; end // 1-0
							else		 led_oen <= 4'b1111;
				default: led_oen <= 4'b1111;
			endcase
		end

		assign FPGA_SST_SEL = (clocksel_reg[1]) ? clocksel_reg[0] : 1'bZ;
		assign LOCAL_OSC_EN = clocksel_reg[2];
		assign ICE40_RESET = !reset_reg[0];
		assign CS_B = !spiss_reg[0];		

		assign LED[0] = (led_oen[0]) ? 1'bZ : led_out[0];
		assign LED[1] = (led_oen[1]) ? 1'bZ : led_out[1];
		assign LED[2] = (led_oen[2]) ? 1'bZ : led_out[2];
		assign LED[3] = (led_oen[3]) ? 1'bZ : led_out[3];
			
		assign FP_LED = led_reg[12];

		assign pci_interrupt_o = |(int_sr_reg & ~int_mask_reg);

		assign local_clk_o = LOCAL_CLK;

		// We just want a multiply by 4, so we'll boost the VCO to 1 GHz and divide by 10.
		// 
		wire SST_FB;
		wire sys_clk_mmcm;
		
		MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"), // Jitter programming ("HIGH","LOW","OPTIMIZED")
		.CLKFBOUT_MULT_F(40.0), // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (0.00-360.00).
		// CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		.CLKIN1_PERIOD(40.0),
		.CLKIN2_PERIOD(40.0),
		// CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
		.CLKOUT0_DIVIDE_F(10.0), // Divide amount for CLKOUT0 (1.000-128.000).
		.CLKOUT1_DIVIDE(5.0),	 // Divide amount for CLKOUT1 (WCLK)
		// CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
		.CLKOUT0_DUTY_CYCLE(0.5),
		// CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
		.CLKOUT0_PHASE(0.0),
		.COMPENSATION("ZHOLD"), // "ZHOLD", "INTERNAL", "EXTERNAL" or "BUF_IN"
		.DIVCLK_DIVIDE(1), // Master division value (1-106)		
		.REF_JITTER1(0.0),
		.REF_JITTER2(0.0),
		.STARTUP_WAIT("FALSE")) u_mmcm(	.CLKIN1(FPGA_TURF_SST),
													.CLKIN2(LOCAL_CLK),
													.CLKOUT0(sys_clk_mmcm),
													.CLKOUT1(wclk_p),
													.CLKOUT1B(wclk_n),
													.LOCKED(mmcm_locked),
													.RST(mmcm_reset),
													.PWRDWN(mmcm_power_down),
													.CLKFBOUT(mmcm_fb_out),
													.CLKFBIN(mmcm_fb_in),
													.CLKINSEL(mmcm_clock_select),
													.CLKFBSTOPPED(mmcm_clkfbstopped),
													.CLKINSTOPPED(mmcm_clkinstopped));
		wire wclk;
		BUFG u_wclk(.I(wclk_p),.O(wclk));
		BUFG u_sysclk(.I(sys_clk_mmcm),.O(sys_clk_o));

		generate
			genvar w_i;
			for (w_i=0;w_i<12;w_i=w_i+1) begin : WCLK_OUT
				wire wclk_to_obuf;
				ODDR #(.INIT(1'b0),.SRTYPE("SYNC")) u_wclk_oddr2(.Q(wclk_to_obuf),.C(wclk),.CE(wclk_en_i[w_i]),.D1(1'b0),.D2(1'b1),.R(1'b0),.S(1'b0));
				OBUFDS u_wclk_obufds(.I(wclk_to_obuf),.O(L4_WCLK_P[w_i]),.OB(L4_WCLK_N[w_i]));
			end
		endgenerate													
													
		// To Do:
		// -- PPS generation/selection/control.
		// -- Ext trig generation/selection/control.
		assign pps_o = 0;
		assign pps_sysclk_o = 0;
		assign ext_trig_o = 0;
		assign ext_trig_sysclk_o = 0;
endmodule
