`timescale 1ns / 1ps
`include "wishbone.vh"
// Simple WISHBONE interconnect.
// Because we have bucketloads of register space available the address spaces are all hardcoded.
module wbc_intercon(
		input clk_i,
		input rst_i,
		`WBS_NAMED_PORT(pcic, 32, 20, 4),
		`WBS_NAMED_PORT(turfc, 32, 20, 4),
		`WBS_NAMED_PORT(hkc, 32, 20, 4),
		`WBM_NAMED_PORT(s4_id_ctrl, 32, 20, 4)
    );

	localparam [19:0] S4_ID_CTRL_BASE = 20'h00000;
	localparam [19:0] S4_ID_CTRL_MASK = 20'h0FFFF;
	localparam [19:0] HKC_BASE			 = 20'h10000;
	localparam [19:0] HKC_MASK			 = 20'h0FFFF;
	localparam [19:0] RFP_BASE_1		 = 20'h20000; // 0010, 0011, 0100, 0101, 0110, and 0111 all match. So we split in 2.
	localparam [19:0] RFP_MASK			 = 20'h1FFFF; // match 0010, 0011.
	localparam [19:0] RFP_BASE_2		 = 20'h40000;
	localparam [19:0]	RFP_MASK_2		 = 20'h3FFFF; // match 0100, 0101, 0110, 0111.
	localparam [19:0] LAB4_BASE		 = 20'h80000;
	localparam [19:0] LAB4_MASK		 = 20'h7FFFF; // match 1000-1111.
	
	wire pcic_gnt;
	wire turfc_gnt;
	wire hkc_gnt;
	
	// Simple round robin arbiter for right now. Stolen from asic-world.
	arbiter u_arbiter(.clk(clk_i),.rst(rst_i),
							.req0(pcic_cyc_i),.gnt0(pcic_gnt),
							.req1(turfc_cyc_i),.gnt1(turfc_gnt),
							.req2(hkc_cyc_i),.gnt2(hkc_gnt),
							.req3(1'b0));							
	wire cyc = (pcic_cyc_i && pcic_gnt) || (turfc_cyc_i && turfc_gnt) || (hkc_cyc_i && hkc_gnt);
	wire stb = (pcic_stb_i && pcic_gnt) || (turfc_stb_i && turfc_gnt) || (hkc_stb_i && hkc_gnt);
	wire we = (pcic_we_i && pcic_gnt) || (turfc_we_i && turfc_gnt) || (hkc_we_i && hkc_gnt);
	reg [19:0] adr;
	reg [31:0] dat_o;
	reg [3:0] sel;
	always @(*) begin
		if (turfc_gnt) begin 
			adr <= turfc_adr_i;
			dat_o <= turfc_dat_i;
			sel <= turfc_sel_i;
		end else if (hkc_gnt) begin
			adr <= hkc_adr_i;
			dat_o <= hkc_dat_i;
			sel <= hkc_sel_i;
		end else begin
			adr <= pcic_adr_i;
			dat_o <= pcic_dat_i;
			sel <= pcic_sel_i;
		end
	end
	
	wire sel_s4_id_ctrl = ((adr & ~S4_ID_CTRL_MASK) == S4_ID_CTRL_BASE);
	assign s4_id_ctrl_cyc_o = cyc && sel_s4_id_ctrl;
	assign s4_id_ctrl_stb_o = stb && sel_s4_id_ctrl;
	assign s4_id_ctrl_we_o = we;
	assign s4_id_ctrl_adr_o = (adr - S4_ID_CTRL_BASE);
	assign s4_id_ctrl_dat_o = dat_o;
	assign s4_id_ctrl_sel_o = sel;
	
	// Mux these in a bit.
	assign pcic_ack_o = (pcic_gnt && s4_id_ctrl_ack_i);
	assign pcic_err_o = (pcic_gnt && s4_id_ctrl_err_i);
	assign pcic_rty_o = (pcic_gnt && s4_id_ctrl_rty_i);
	assign pcic_dat_o = s4_id_ctrl_dat_i;
	
	assign turfc_ack_o = (turfc_gnt && s4_id_ctrl_ack_i);
	assign turfc_err_o = (turfc_gnt && s4_id_ctrl_err_i);
	assign turfc_rty_o = (turfc_gnt && s4_id_ctrl_rty_i);
	assign turfc_dat_o = s4_id_ctrl_dat_i;

	assign hkc_ack_o = (hkc_gnt && s4_id_ctrl_ack_i);
	assign hkc_err_o = (hkc_gnt && s4_id_ctrl_err_i);
	assign hkc_rty_o = (hkc_gnt && s4_id_ctrl_rty_i);
	assign hkc_dat_o = s4_id_ctrl_dat_i;
endmodule
