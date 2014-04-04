`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:29:47 03/18/2014
// Design Name:   SURF4_A7
// Module Name:   C:/cygwin/home/barawn/repositories/firmware-surf4-a7/sim/SURF4_A7_tb.v
// Project Name:  SURF4_A7
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: SURF4_A7
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
///////////////////////////////////////////////////////////////////////////////

module SURF4_A7_tb;

	// Inputs
	reg LOCAL_CLK;
	wire LOCAL_OSC_EN;
	pullup pu_osc(LOCAL_OSC_EN);
	
	reg EXT_TRIG;
	reg FPGA_TURF_SST_P;
	wire FPGA_TURF_SST_N = ~FPGA_TURF_SST_P;
	reg [11:0] L4_RX_P;
	wire [11:0] L4_RX_N = ~L4_RX_P;
	reg [11:0] L4_TIMING_P;
	wire [11:0] L4_TIMING_N = ~L4_TIMING_P;
	reg PCI_CLK;
	reg pci_idsel;
	reg pci_gnt;
	reg TREQ_neg;
	reg TCLK_P;
	wire TCLK_N = ~TCLK_P;
	reg PPS_N;
	reg PPS_P;
	reg [3:0] HOLD;
	reg SPI_D1_MISO;
	reg MGT1V_P;
	reg MGT1V_N;
	reg MGT1P2_P;
	reg MGT1P2_N;

	// Outputs
	wire FP_LED;
	wire FPGA_SST_N;
	wire FPGA_SST_P;
	wire ICE40_RESET;
	wire [11:0] L4_CLK_P;
	wire [11:0] L4_CLK_N;
	wire [11:0] L4_TX_P;
	wire [11:0] L4_TX_N;
	wire [11:0] L4_WCLK_P;
	wire [11:0] L4_WCLK_N;
	wire L4A_WR_EN;
	wire [4:0] L4A_WR;
	wire L4B_WR_EN;
	wire [4:0] L4B_WR;
	wire L4C_WR_EN;
	wire [4:0] L4C_WR;
	wire L4D_WR_EN;
	wire [4:0] L4D_WR;
	wire L4E_WR_EN;
	wire [4:0] L4E_WR;
	wire L4F_WR_EN;
	wire [4:0] L4F_WR;
	wire L4G_WR_EN;
	wire [4:0] L4G_WR;
	wire L4H_WR_EN;
	wire [4:0] L4H_WR;
	wire L4I_WR_EN;
	wire [4:0] L4I_WR;
	wire L4J_WR_EN;
	wire [4:0] L4J_WR;
	wire L4K_WR_EN;
	wire [4:0] L4K_WR;
	wire L4L_WR_EN;
	wire [4:0] L4L_WR;
	wire [4:0] MON;
	wire pci_req;
	wire [7:0] TD_P;
	wire [7:0] TD_N;
	wire SCLK_N;
	wire SCLK_P;
	wire SREQ_neg;
	wire SPI_CS_neg;
	wire SPI_D0_MOSI;

	// Bidirs
	wire FPGA_SST_SEL;
	wire [11:0] L4_SCL;
	wire [11:0] L4_SDA;
	generate
		genvar i;
		for (i=0;i<12;i=i+1) begin : I2CPULL
			pullup pu_scl(L4_SCL[i]);
			pullup pu_sda(L4_SDA[i]);
		end
	endgenerate
	
	wire [3:0] LED;
	wire pci_rst;
	pullup pu_rst(pci_rst);
	
	reg [31:0] pci_ad_o = {32{1'b0}};
	reg pci_ad_oe = 0;
	wire [31:0] pci_ad;
	assign pci_ad = pci_ad_oe ? pci_ad_o : {32{1'bZ}};
	
	wire pci_perr;
	pullup pu_perr(pci_perr);
	
	wire pci_par;
	pulldown pu_par(pci_par);
	
	wire pci_trdy;
	pullup pu_trdy(pci_trdy);
	
	wire pci_devsel;
	pullup pu_devsel(pci_devsel);
	
	wire pci_stop;
	pullup pu_stop(pci_stop);
	
	reg [3:0] pci_cbe_o = {4{1'b0}};
	reg pci_cbe_oe = 0;
	wire [3:0] pci_cbe = (pci_cbe_oe) ? pci_cbe_o : {4{1'bZ}};
	
	wire pci_frame;
	pullup pu_frame(pci_frame);	
	wire pci_irdy;
	pullup pu_irdy(pci_irdy);
	wire pci_inta;
	pullup pu_inta(pci_inta);	
	wire pci_serr;
	pullup pu_serr(pci_serr);
	
	wire UC_SCL;
	wire UC_SDA;
	pullup uc_scl(UC_SCL);
	pullup uc_sda(UC_SDA);
	
	// Instantiate the Unit Under Test (UUT)
	SURF4_A7 uut (
		.LOCAL_CLK(LOCAL_CLK), 
		.LOCAL_OSC_EN(LOCAL_OSC_EN), 
		.EXT_TRIG(EXT_TRIG), 
		.FP_LED(FP_LED), 
		.FPGA_SST_N(FPGA_SST_N), 
		.FPGA_SST_P(FPGA_SST_P), 
		.FPGA_SST_SEL(FPGA_SST_SEL), 
		.FPGA_TURF_SST_N(FPGA_TURF_SST_N), 
		.FPGA_TURF_SST_P(FPGA_TURF_SST_P), 
		.ICE40_RESET(ICE40_RESET), 
		.L4_CLK_P(L4_CLK_P), 
		.L4_CLK_N(L4_CLK_N), 
		.L4_RX_P(L4_RX_P), 
		.L4_RX_N(L4_RX_N), 
		.L4_TX_P(L4_TX_P), 
		.L4_TX_N(L4_TX_N), 
		.L4_SCL(L4_SCL), 
		.L4_SDA(L4_SDA), 
		.L4_TIMING_P(L4_TIMING_P), 
		.L4_TIMING_N(L4_TIMING_N), 
		.L4_WCLK_P(L4_WCLK_P), 
		.L4_WCLK_N(L4_WCLK_N), 
		.L4A_WR_EN(L4A_WR_EN), 
		.L4A_WR(L4A_WR), 
		.L4B_WR_EN(L4B_WR_EN), 
		.L4B_WR(L4B_WR), 
		.L4C_WR_EN(L4C_WR_EN), 
		.L4C_WR(L4C_WR), 
		.L4D_WR_EN(L4D_WR_EN), 
		.L4D_WR(L4D_WR), 
		.L4E_WR_EN(L4E_WR_EN), 
		.L4E_WR(L4E_WR), 
		.L4F_WR_EN(L4F_WR_EN), 
		.L4F_WR(L4F_WR), 
		.L4G_WR_EN(L4G_WR_EN), 
		.L4G_WR(L4G_WR), 
		.L4H_WR_EN(L4H_WR_EN), 
		.L4H_WR(L4H_WR), 
		.L4I_WR_EN(L4I_WR_EN), 
		.L4I_WR(L4I_WR), 
		.L4J_WR_EN(L4J_WR_EN), 
		.L4J_WR(L4J_WR), 
		.L4K_WR_EN(L4K_WR_EN), 
		.L4K_WR(L4K_WR), 
		.L4L_WR_EN(L4L_WR_EN), 
		.L4L_WR(L4L_WR), 
		.LED(LED), 
		.MON(MON), 
		.PCI_CLK(PCI_CLK), 
		.pci_rst(pci_rst), 
		.pci_idsel(pci_idsel), 
		.pci_gnt(pci_gnt), 
		.pci_req(pci_req), 
		.pci_ad(pci_ad), 
		.pci_perr(pci_perr), 
		.pci_par(pci_par), 
		.pci_trdy(pci_trdy), 
		.pci_devsel(pci_devsel), 
		.pci_stop(pci_stop), 
		.pci_cbe(pci_cbe), 
		.pci_frame(pci_frame), 
		.pci_irdy(pci_irdy), 
		.pci_inta(pci_inta), 
		.pci_serr(pci_serr), 
		.TD_P(TD_P), 
		.TD_N(TD_N), 
		.SCLK_N(SCLK_N), 
		.SCLK_P(SCLK_P), 
		.SREQ_neg(SREQ_neg), 
		.TREQ_neg(TREQ_neg), 
		.TCLK_N(TCLK_N), 
		.TCLK_P(TCLK_P), 
		.PPS_N(PPS_N), 
		.PPS_P(PPS_P), 
		.HOLD(HOLD), 
		.UC_SCL(UC_SCL), 
		.UC_SDA(UC_SDA), 
		.SPI_CS_neg(SPI_CS_neg), 
		.SPI_D0_MOSI(SPI_D0_MOSI), 
		.SPI_D1_MISO(SPI_D1_MISO), 
		.MGT1V_P(MGT1V_P), 
		.MGT1V_N(MGT1V_N), 
		.MGT1P2_P(MGT1P2_P), 
		.MGT1P2_N(MGT1P2_N)
	);

	always #15 PCI_CLK = ~PCI_CLK;
	always #40 LOCAL_CLK = (LOCAL_OSC_EN == 1'b1) ? ~LOCAL_CLK : 1'b0;
	always #40 FPGA_TURF_SST_P = ~FPGA_TURF_SST_P;

	initial begin
		// Initialize Inputs
		LOCAL_CLK = 0;
		EXT_TRIG = 0;
		FPGA_TURF_SST_P = 0;
		L4_RX_P = 0;
		L4_TIMING_P = 0;
		PCI_CLK = 0;
		pci_idsel = 0;
		pci_gnt = 0;
		TREQ_neg = 0;
		TCLK_P = 0;
		PPS_N = 0;
		PPS_P = 0;
		HOLD = 0;
		SPI_D1_MISO = 0;
		MGT1V_P = 0;
		MGT1V_N = 0;
		MGT1P2_P = 0;
		MGT1P2_N = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

