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

// RAM for LAB4 storage. This is a 8192x12 random-access dual-port RAM. First
// attempt to see if the problem is just the BRAM generator. Output is a 4096x24
// random-access port.
module lab4_buffer(
		input clka,
		input wea,
		input [12:0] addra,
		input [15:0] dina,
		
		input clkb,
		input enb,
		input [11:0] addrb,
		output [31:0] doutb
    );

	// For an 8192x12 RAM, we use 3 RAMB36s in 4-bit mode. This nicely eliminates address
	// decoding and output multiplexing.
	
	// One side is 8192x4, one side is 4096x8.
	
	// RAMB36s in 7-series devices are fairly psychotic.
	wire [15:0] ram_addra = {1'b0,addra,2'b00};
	wire [15:0] ram_addrb = {1'b0,addrb,3'b000};
	generate
		genvar i;
		for (i=0;i<3;i=i+1) begin : RAM
			wire [31:0] diadi = {{28{1'b0}},dina[4*i +: 4]};
			wire [31:0] dobdo;
			wire [3:0] wea = {{3{1'b0}},wea};
			RAMB36E1 #(.WRITE_WIDTH_A(4),.READ_WIDTH_B(9),.RDADDR_COLLISION_HWCONFIG("PERFORMANCE")) 
				u_ram(.CLKARDCLK(clka),
						.ENARDEN(wea),
						.WEA(wea),
						.ADDRARDADDR(ram_addra),
						.DIADI(diadi),
						.CLKBWRCLK(clkb),
						.ENBWREN(enb),
						.WEBWE(8'h00),
						.ADDRBWRADDR(ram_addrb),
						.DOBDO(dobdo));
			assign doutb[4*i +: 4] = dobdo[3:0];
			assign doutb[16 + 4*i +: 4] = dobdo[7:4];
		end
	endgenerate

endmodule
