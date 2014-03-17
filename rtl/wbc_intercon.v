`timescale 1ns / 1ps
`include "wishbone.vh"
// Simple WISHBONE interconnect.
// Because we have bucketloads of register space available the address spaces are all hardcoded.
module wbc_intercon(
		input clk_i,
		input rst_i,
		`WBS_NAMED_PORT(pcic, 32, 20, 4),
		`WBS_NAMED_PORT(turfc, 32, 20, 4),
		`WBS_NAMED_PORT(hkmc, 32, 20, 4),
		`WBM_NAMED_PORT(s4_id_ctrl, 32, 16, 4),
		`WBM_NAMED_PORT(hksc, 32, 16, 4),
		`WBM_NAMED_PORT(rfp, 32, 19, 4),
		`WBM_NAMED_PORT(lab4, 32, 19, 4)
    );

	localparam [19:0] S4_ID_CTRL_BASE = 20'h00000;
	localparam [19:0] S4_ID_CTRL_MASK = 20'h0FFFF;
	localparam [19:0] HKSC_BASE		 = 20'h10000;
	localparam [19:0] HKSC_MASK	    = 20'h0FFFF;
	localparam [19:0] RFP_BASE_1		 = 20'h20000; // 0010, 0011, 0100, 0101, 0110, and 0111 all match. So we split in 2.
	localparam [19:0] RFP_MASK_1		 = 20'h1FFFF; // match 0010, 0011.
	localparam [19:0] RFP_BASE_2		 = 20'h40000;
	localparam [19:0]	RFP_MASK_2		 = 20'h3FFFF; // match 0100, 0101, 0110, 0111.
	localparam [19:0] LAB4_BASE		 = 20'h80000;
	localparam [19:0] LAB4_MASK		 = 20'h7FFFF; // match 1000-1111.
	
	wire pcic_gnt;
	wire turfc_gnt;
	wire hkmc_gnt;
	
	// Simple round robin arbiter for right now. Stolen from asic-world.
	arbiter u_arbiter(.clk(clk_i),.rst(rst_i),
							.req0(pcic_cyc_i),.gnt0(pcic_gnt),
							.req1(turfc_cyc_i),.gnt1(turfc_gnt),
							.req2(hkmc_cyc_i),.gnt2(hkmc_gnt),
							.req3(1'b0));							
	wire cyc = (pcic_cyc_i && pcic_gnt) || (turfc_cyc_i && turfc_gnt) || (hkmc_cyc_i && hkmc_gnt);
	wire stb = (pcic_stb_i && pcic_gnt) || (turfc_stb_i && turfc_gnt) || (hkmc_stb_i && hkmc_gnt);
	wire we = (pcic_we_i && pcic_gnt) || (turfc_we_i && turfc_gnt) || (hkmc_we_i && hkmc_gnt);
	reg [19:0] adr;
	reg [31:0] dat_o;
	reg [3:0] sel;
	always @(*) begin
		if (turfc_gnt) begin 
			adr <= turfc_adr_i;
			dat_o <= turfc_dat_i;
			sel <= turfc_sel_i;
		end else if (hkmc_gnt) begin
			adr <= hkmc_adr_i;
			dat_o <= hkmc_dat_i;
			sel <= hkmc_sel_i;
		end else begin
			adr <= pcic_adr_i;
			dat_o <= pcic_dat_i;
			sel <= pcic_sel_i;
		end
	end
	
	`define SLAVE_MAP(prefix, mask, base)						\
		wire sel_``prefix = ((adr & ~ mask ) == base );		\
		assign prefix``_cyc_o = cyc && sel_``prefix ;		\
		assign prefix``_stb_o = stb && sel_``prefix ;		\
		assign prefix``_we_o = we && sel_``prefix;			\
		assign prefix``_adr_o = (adr & mask );					\
		assign prefix``_dat_o = dat_o;							\
		assign prefix``_sel_o = sel
	
/*	wire sel_s4_id_ctrl = ((adr & ~S4_ID_CTRL_MASK) == S4_ID_CTRL_BASE);
	assign s4_id_ctrl_cyc_o = cyc && sel_s4_id_ctrl;
	assign s4_id_ctrl_stb_o = stb && sel_s4_id_ctrl;
	assign s4_id_ctrl_we_o = we;
	assign s4_id_ctrl_adr_o = (adr - S4_ID_CTRL_BASE);
	assign s4_id_ctrl_dat_o = dat_o;
	assign s4_id_ctrl_sel_o = sel;
*/
// All of these compares should become simple:
// s4_id_ctrl should map down to 
// [19:16] == 0000.
	`SLAVE_MAP( s4_id_ctrl, S4_ID_CTRL_MASK, S4_ID_CTRL_BASE );
	`SLAVE_MAP( hksc, HKSC_MASK, HKSC_BASE );
// RFP is not one contiguous power-of-2 space, so we can't use the
// macro. The address conversion is a little complicated: we span
// 0x20000 - 0x7FFFF, and we want to map that to
// 0x00000 - 0x5FFFF.
// 010 -> 000
// 011 -> 001
// 100 -> 010
// 101 -> 011
// 110 -> 100
// 111 -> 101
// which is just
// 01 -> 00
// 10 -> 01
// 11 -> 10 
// or ((a & b), a)
	wire sel_rfp = ((adr & RFP_MASK_1) == RFP_BASE_1) ||
					   ((adr & RFP_MASK_2) == RFP_BASE_2);
	assign rfp_cyc_o = cyc && sel_rfp;
	assign rfp_stb_o = stb && sel_rfp;
	assign rfp_we_o = we && sel_rfp;
	assign rfp_adr_o = {adr[18] && adr[17], adr[18],adr[16:0]};
	assign rfp_dat_o = dat_o;
	assign rfp_sel_o = sel;	
	`SLAVE_MAP( lab4, LAB4_MASK, LAB4_BASE );

	reg muxed_ack;
	reg muxed_err;
	reg muxed_rty;
	reg [31:0] muxed_dat_i;

	always @(*) begin
		if (sel_lab4) begin
			muxed_ack <= lab4_ack_i;
			muxed_err <= lab4_err_i;
			muxed_rty <= lab4_rty_i;
			muxed_dat_i <= lab4_dat_i;
		end else if (sel_rfp) begin
			muxed_ack <= rfp_ack_i;
			muxed_err <= rfp_err_i;
			muxed_rty <= rfp_rty_i;
			muxed_dat_i <= rfp_dat_i;
		end else if (sel_hksc) begin
			muxed_ack <= hksc_ack_i;
			muxed_err <= hksc_err_i;
			muxed_rty <= hksc_rty_i;
			muxed_dat_i <= hksc_dat_i;
		end else begin
			muxed_ack <= s4_id_ctrl_ack_i;
			muxed_err <= s4_id_ctrl_err_i;
			muxed_rty <= s4_id_ctrl_rty_i;
			muxed_dat_i <= s4_id_ctrl_dat_i;
		end
	end
	
	assign pcic_ack_o = (pcic_gnt && muxed_ack);
	assign pcic_err_o = (pcic_gnt && muxed_err);
	assign pcic_rty_o = (pcic_gnt && muxed_rty);
	assign pcic_dat_o = muxed_dat_i;
	
	assign turfc_ack_o = (turfc_gnt && muxed_ack);
	assign turfc_err_o = (turfc_gnt && muxed_err);
	assign turfc_rty_o = (turfc_gnt && muxed_rty);
	assign turfc_dat_o = muxed_dat_i;

	assign hkmc_ack_o = (hkmc_gnt && muxed_ack);
	assign hkmc_err_o = (hkmc_gnt && muxed_err);
	assign hkmc_rty_o = (hkmc_gnt && muxed_rty);
	assign hkmc_dat_o = muxed_dat_i;
endmodule
