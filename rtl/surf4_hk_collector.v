`timescale 1ns / 1ps
`include "wishbone.vh"
module surf4_hk_collector(
		input clk_i,
		input rst_i,
		`WBS_NAMED_PORT(wbsc, 32, 16, 4),
		`WBM_NAMED_PORT(wbmc, 32, 20, 4),
		input pps_i,
		// external ports (MGT_1V/MGT_VTT)
		input MGT1V_P,
		input MGT1V_N,
		input MGT1P2_P,
		input MGT1P2_N
    );

	// The HK collector handles housekeeping stuff. It's called a
	// "collector" because a PicoBlaze processor will read all of the
	// housekeeping from all of the modules (and the internal XADC stuff)
	// and write them into a housekeeping buffer which can be DMA'd either
	// to the TURF or to the PCI bus.
	
	// First simple sketch: connect the XADC block to the WISHBONE bus.
	// We have a 14-bit 32-bit address space [15:2]. Reserve
	// address [15:9] = 7'h00 for random control registers or something.
	//                        Probably also allow for reprogramming the PicoBlaze
	//                        via the control bus.
	// address [15:9] = 7'h01 for the XADC.
	// address [15:9] = 7'h08-7'h7F for the housekeeping buffer.
	wire sel_control = (wbsc_adr_i[15:9] == 7'h00);
	wire sel_xadc    = (wbsc_adr_i[15:9] == 7'h01);
	wire sel_buffer  = (wbsc_adr_i[15:9] == 7'h02);

	wire [15:0] xadc_data_in = wbsc_dat_i[15:0];
	wire [15:0] xadc_data_out;
	wire [6:0] xadc_addr = wbsc_adr_i[8:2];
	wire xadc_en;
	wire xadc_we;
	wire xadc_ack;
	assign xadc_en = (wbsc_cyc_i && wbsc_stb_i && sel_control);
	assign xadc_we = wbsc_we_i;
	wire [15:0] xadc_vaux_p;
	assign xadc_vaux_p[15:11] = {5{1'b0}};
	assign xadc_vaux_p[10] = MGT1P2_P;
	assign xadc_vaux_n[9:0] = {10{1'b0}};
	wire [15:0] xadc_vaux_n;
	assign xadc_vaux_n[15:11] = {5{1'b0}};
	assign xadc_vaux_n[10] = MGT1P2_N;
	assign xadc_vaux_n[9:0] = {10{1'b0}};
	
	XADC u_xadc(.DADDR(xadc_addr),
					.DCLK(clk_i),
					.DEN(xadc_en),
					.DI(xadc_data_in),
					.DO(xadc_data_out),
					.RESET(rst_i),
					.DRDY(xadc_ack),
					.DWE(xadc_we),
					.VP(MGT1V_P),
					.VN(MGT1V_N),
					.VAUXP(xadc_vaux_p),
					.VAUXN(xadc_vaux_n));
	// Control register section.
	wire [31:0] ctrl_dat_o;
	wire ctrl_ack;
	// just kill it for now
	assign ctrl_dat_o = {32{1'b0}};
	assign ctrl_ack = cyc_i && stb_i && sel_control;

	// Buffer section
	wire [31:0] buf_dat_o;
	wire buf_ack;
	// just kill it for now
	assign buf_dat_o = {32{1'b0}};
	assign buf_ack_o = cyc_i && stb_i && sel_control;
	
	
	///////////////////////////////////////////////
	// WISHBONE slave port muxing.
	///////////////////////////////////////////////
	reg [31:0] wbsc_dat_out_muxed;
	reg wbsc_ack_muxed;
	always @(*) begin
		if (sel_control) wbsc_dat_out_muxed <= ctrl_dat_o;
		else if (sel_xadc) wbsc_dat_out_muxed <= xadc_data_out;
		else wbsc_dat_out_muxed <= buf_dat_o;
	end
	always @(*) begin
		if (sel_control) wbsc_ack_muxed <= ctrl_ack;
		else if (sel_xadc) wbsc_ack_muxed <= xadc_ack;
		else wbsc_ack_muxed <= buf_ack;
	end
	///////////////////////////////////////////////
	// WISHBONE master port.
	///////////////////////////////////////////////
	// Just kill it for now.
	`WB_KILL(wmbc, 32, 20, 4);
	
endmodule
