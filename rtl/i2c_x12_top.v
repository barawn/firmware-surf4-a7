`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:47:06 02/28/2014 
// Design Name: 
// Module Name:    i2c_x12_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "wishbone.vh"
module i2c_x12_top(
			input clk_i,
			input rst_i,
			`WBS_NAMED_PORT(wb0, 8, 7, 1),
			`WBS_NAMED_PORT(wb1, 8, 7, 1),
			inout [11:0] SDA,
			inout [11:0] SCL
    );

	`WB_DEFINE_VECTOR(i2c, 8, 3, 1, 12);
	wire [11:0] scl_pad_i;
	wire [11:0] scl_pad_o;
	wire [11:0] scl_pad_oen_o;
	wire [11:0] sda_pad_i;
	wire [11:0] sda_pad_o;
	wire [11:0] sda_pad_oen_o;

	reg [15:0] wb0_gnt = {16{1'b0}};
	reg [15:0] wb1_gnt = {16{1'b0}};

	// WISHBONE cores and crossbar interconnect.
	// We now have two 'slave' inputs (wb0/wb1)
	// and 12 'master' outputs (i2c[11:0])
	// Note that accessing an 'unmapped' address (above the 12 I2C cores) results in err_i being asserted immediately.
	generate
		genvar ii;
		for (ii=0;ii<12;ii=ii+1) begin : I2C_CORE
			assign SDA[ii] = sda_pad_oen_o[ii] ? 1'bZ : sda_pad_o[ii];
			assign SCL[ii] = scl_pad_oen_o[ii] ? 1'bZ : scl_pad_o[ii];
			assign scl_pad_i[ii] = SCL[ii];
			assign sda_pad_i[ii] = SDA[ii];
			assign i2c_sel_o[ii] = 1'b0;
			i2c_master_top u_i2c(.scl_pad_i(scl_pad_i[ii]),.scl_pad_o(scl_pad_o[ii]),.scl_padoen_o(scl_pad_oen_o[ii]),
										.sda_pad_i(sda_pad_i[ii]),.sda_pad_o(sda_pad_o[ii]),.sda_padoen_o(sda_pad_oen_o[ii]),
										.wb_clk_i(clk_i),
										.wb_rst_i(rst_i),
										.arst_i(1'b0),
										`WBS_CONNECT_VECTOR(i2c, wb, ii));
			// demux cyc, stb, we, adr, dat_o.
			assign i2c_cyc_o[ii] = (wb0_gnt[ii] && wb0_cyc_i) || (wb1_gnt[ii] && wb1_cyc_i);
			assign i2c_stb_o[ii] = (wb0_gnt[ii] && wb0_stb_i) || (wb1_gnt[ii] && wb1_stb_i);
			assign i2c_we_o[ii] = (wb0_gnt[ii] && wb0_we_i) || (wb1_gnt[ii] && wb1_we_i);
			assign i2c_adr_o[ii] = (wb0_gnt[ii]) ? (wb0_adr_i[2:0]) : (wb1_adr_i[2:0]);
			assign i2c_dat_o[ii] = (wb0_gnt[ii]) ? wb0_dat_i : wb1_dat_i;
			always @(posedge clk_i) begin : PRIORITY_ARBITER
				// This is a simple 2-way arbiter with priority.
				// There are 2 input ports: WB0 and WB1.
				// WB0 has priority on simultaneous requests over WB1.
				
				// Release grant as soon as we finish.
				if (!wb0_cyc_i) wb0_gnt[ii] <= 0;
				// Otherwise, if we're requesting this slave, and it hasn't been granted
				// to the other bus (or if that bus is ending its transaction), grant.
				else if (wb0_adr_i[6:3] == ii && wb0_cyc_i &&
							(!wb1_gnt[ii] || !wb1_cyc_i)) wb0_gnt[ii] <= 1;
				// Exactly the same, except we *require* that wb1
				// is not simultaneously requesting.
				if (!wb1_cyc_i) wb1_gnt[ii] <= 0;
				else if (wb1_adr_i[6:3] == ii && wb1_cyc_i && !wb0_cyc_i) wb1_gnt[ii] <= 1;
				
				// Here if wb0_cyc_i and wb1_cyc_i are both requesting the same slave,
				// wb0_gnt[ii] goes high (wb0 wins).
				// When wb0 releases (wb0_cyc_i goes low) then wb1 immediately wins.
			end
		end
	endgenerate
	
	// illegal address indicator.
	wire wb0_illegal_address = (wb0_adr_i[6:3] > 11);
	wire wb1_illegal_address = (wb1_adr_i[6:3] > 11);
	
	// The crossbar switch is pretty easy to do, since we only need to block "cyc", "stb", and "ack/err/rty".
	// Everything else we can just mux.
	
	// mux
	assign wb0_dat_o = i2c_dat_i[wb0_adr_i[6:3]];
	assign wb0_ack_o = i2c_ack_i[wb0_adr_i[6:3]] && wb0_gnt[wb0_adr_i[6:3]];
	assign wb0_rty_o = i2c_rty_i[wb0_adr_i[6:3]] && wb0_gnt[wb0_adr_i[6:3]];
	assign wb0_err_o = i2c_err_i[wb0_adr_i[6:3]] && wb0_gnt[wb0_adr_i[6:3]] || (wb0_illegal_address && wb0_cyc_i && wb0_stb_i);
	// mux
	assign wb1_dat_o = i2c_dat_i[wb1_adr_i[6:3]];
	assign wb1_ack_o = i2c_ack_i[wb1_adr_i[6:3]] && wb1_gnt[wb1_adr_i[6:3]];
	assign wb1_rty_o = i2c_rty_i[wb1_adr_i[6:3]] && wb1_gnt[wb1_adr_i[6:3]];
	assign wb1_err_o = i2c_err_i[wb1_adr_i[6:3]] && wb1_gnt[wb1_adr_i[6:3]] || (wb1_illegal_address && wb1_cyc_i && wb1_stb_i);

endmodule
