`timescale 1ns / 1ps
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
// 0x0010: PPS selection register
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
		input [30:0] interrupt_i, 
		output pci_interrupt_o,
		input [11:0] internal_led_i,
		input ext_pps_i,
		output pps_o,
		// SPI
		output MOSI,
		input MISO,
		output CS_B,
		output ICE40_RESET,

		output [3:0] LED,
		output FP_LED,
		input LOCAL_CLK,
		output LOCAL_OSC_EN,
		output FPGA_SST_SEL,
		input FPGA_SST,
		output sys_clk_o
    );

		parameter DEVICE = "S4A7";
		parameter VERSION = 32'h00000000;
		
		reg [31:0] wb_data_out_mux;
		reg [31:0] wb_data_out_internal = {32{1'b0}};
		// Our internal space is 4 bits wide = 16 registers (5:2 only matter).
		// The last 4 are really the SPI core, and the 2 before that are reserved.
		wire [31:0] wishbone_registers[15:0];
		
		wire sel_int_sr_reg;
		reg [31:0] int_sr_reg = {32{1'b0}};
		reg [31:0] int_mask_reg = {32{1'b0}};
		reg [31:0] pps_sel_reg = {32{1'b0}};
		reg [31:0] reset_reg = {32{1'b0}};
		wire sel_led_reg;
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

		always @(*) begin
			if (pll_drp_select) wb_data_out_mux <= pll_drp_dat_o;
			else if (spi_select) wb_data_out_mux <= spi_dat_o;
			else wb_data_out_mux <= wb_data_out_internal;
		end
		always @(*) begin
			if (spi_select) wb_ack_o <= spi_ack_o;
			else wb_ack_o <= internal_ack;
		end
		
		
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
		`define SELECT(addr, x, addrrange, dummy)																			\
					wire x;																											\
					localparam [BASEWIDTH-1:0] addr_``x = addr;															\
					assign x = (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && (wb_adr_i addrrange == addr_``x addrrange))
		`define OUTPUTSELECT(addr, x, y, addrrange)																		\
					wire y;																											\
					localparam [BASEWIDTH-1:0] addr_``y = addr;															\
					assign y = (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && (wb_adr_i addrrange == addr_``y addrrange));	\
					assign wishbone_registers[ addr ] = x

		`define SIGNALRESET(addr, x, range, resetval)																	\
					always @(posedge wb_clk_i) begin																			\
						if (rst_i) x <= resetval;																				\
						else if (wb_cyc_i && wb_stb_i && wb_we_i && (wb_adr_i[BASEWIDTH-1:0] == addr))		\
							x <= dat_i range;																						\
					end																												\
					assign wishbone_registers[ addr ] range = x
		`define WISHBONE_ADDRESS( addr, name, TYPE, par1, par2 )														\
					`TYPE(BASE(addr), name, par1, par2)

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
		
		// Sleaze at first. Just make all the registers 32 bit.
		`WISHBONE_ADDRESS( 16'h0000, DEVICE, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0004, VERSION, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0008, int_sr_reg, OUTPUTSELECT, sel_int_sr_reg, [5:2]);
		`WISHBONE_ADDRESS( 16'h000C, int_mask_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0010, pps_sel_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0014, reset_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0018, led_reg, OUTPUTSELECT, sel_led_reg, [5:1]);
		`WISHBONE_ADDRESS( 16'h001C, clocksel_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0020, pllctrl_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0024, spiss_reg, SIGNALRESET, [31:0], {32{1'b0}});
		`WISHBONE_ADDRESS( 16'h0028, {32{1'b0}}, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h002C, {32{1'b0}}, OUTPUT, [31:0], 0);
		// Shadow registers - never accessed (the SPI core takes over). Just here to make decoding easier.
		`WISHBONE_ADDRESS( 16'h0030, pps_sel_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0034, reset_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h0038, led_reg, OUTPUT, [31:0], 0);
		`WISHBONE_ADDRESS( 16'h003C, clocksel_reg, OUTPUT, [31:0], 0);
		

		simple_spi u_spi(.clk_i(clk_i),
							  .rst_i(rst_i),
							  .inta_o(spi_inta_o),
							  .cyc_i(wb_cyc_i && spi_select),
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
									 .USRDONEO(1'b0),
									 .USRDONETS(1'b0));
	
		
		assign FPGA_SST_SEL = clock_sel_reg[0];
		assign LOCAL_OSC_EN = clock_sel_reg[1];
		assign ICE40_RESET = reset_reg[0];
		assign CS_B = !spiss_reg[0];		
		// LED register:
		// bits [27:16]: override internal LED values and replace with written values.
		// bits 11:0: either current state of internal LEDs, or overridden values.
		// bit 12: FP_LED
		assign FP_LED = led_register[12];
		
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
				0: if (led_register[0]) begin led_out <= 4'b0001; led_oen <= 4'b0110; end // 0-3
				1: if (led_register[1]) begin led_out <= 4'b0010; led_oen <= 4'b0101; end // 1-3
				2: if (led_register[2]) begin led_out <= 4'b0100; led_oen <= 4'b0011; end // 2-3
				3: if (led_register[3]) begin led_out <= 4'b0001; led_oen <= 4'b1010; end // 0-2
				4: if (led_register[4]) begin led_out <= 4'b0010; led_oen <= 4'b1001; end // 1-2
				5: if (led_register[5]) begin led_out <= 4'b0001; led_oen <= 4'b1100; end // 0-1
				6: if (led_register[6]) begin led_out <= 4'b1000; led_oen <= 4'b0110; end // 3-0
				7: if (led_register[7]) begin led_out <= 4'b1000; led_oen <= 4'b0101; end // 3-1
				8: if (led_register[8]) begin led_out <= 4'b1000; led_oen <= 4'b0011; end // 3-2
				9: if (led_register[9]) begin led_out <= 4'b0100; led_oen <= 4'b1010; end // 2-0
				10: if (led_register[10]) begin led_out <= 4'b0100; led_oen <= 4'b1001; end // 2-1
				11: if (led_register[11]) begin led_out <= 4'b0010; led_oen <= 4'b1100; end // 1-0
				default: led_oen <= 4'b1111;
			endcase
		end
		assign LED[0] = (led_oen[0]) ? 1'bZ : led_out[0];
		assign LED[1] = (led_oen[1]) ? 1'bZ : led_out[1];
		assign LED[2] = (led_oen[2]) ? 1'bZ : led_out[2];
		assign LED[3] = (led_oen[3]) ? 1'bZ : led_out[3];
			
		assign pci_interrupt_o = (int_sr_reg & ~int_mask_reg);
		assign pps_o = 0;
endmodule
