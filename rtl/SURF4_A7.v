`timescale 1ns / 1ps
`include "wishbone.vh"
`include "pci.vh"

module SURF4_A7(
		//Local clocks
		input 	      LOCAL_CLK,
		output			LOCAL_OSC_EN,

		//External trigger - externally 50 ohm terminated - 2.5V bank
		input 	      EXT_TRIG,

		//Front Panel LED
		output 	      FP_LED,

		//SSTs and controls
		output 	      FPGA_SST_N,
		output 	      FPGA_SST_P,// Note inout: this is a 3-state pin.
		inout 	      FPGA_SST_SEL,
		//TURF_derived clock for LABs
		input 	      FPGA_TURF_SST_N,
		input 	      FPGA_TURF_SST_P, 

		//ICE40 reset
		output 	      ICE40_RESET,

		// LAB4 signals - clk, RX and TX interfaces 
		// for the iCE - differential x12
		output [11:0] L4_CLK_P,
		output [11:0] L4_CLK_N,
		input [11:0]  L4_RX_P,
 		input [11:0]  L4_RX_N,
		output [11:0] L4_TX_P,
		output [11:0] L4_TX_N,

		// LAB4 signals - DAC interfaces
		// Both SCL and SDA are tristates.
		inout [11:0]  L4_SCL,
		inout [11:0]  L4_SDA,
		// LAB4 signals - direct connection to LAB4B - MONTIMING inputs, 
		// Wilkinson clocks and WR signals
		input [11:0]  L4_TIMING_P,
		input [11:0]  L4_TIMING_N,
		output [11:0] L4_WCLK_P,
		output [11:0] L4_WCLK_N,
		
		output 	      L4A_WR_EN,
		output [4:0]  L4A_WR,

		output 	      L4B_WR_EN,
		output [4:0]  L4B_WR,

		output 	      L4C_WR_EN,
		output [4:0]  L4C_WR,

		output 	      L4D_WR_EN,
		output [4:0]  L4D_WR,

		output 	      L4E_WR_EN,
		output [4:0]  L4E_WR,

		output 	      L4F_WR_EN,
		output [4:0]  L4F_WR,

		output 	      L4G_WR_EN,
		output [4:0]  L4G_WR,

		output 	      L4H_WR_EN,
		output [4:0]  L4H_WR,

		output 	      L4I_WR_EN,
		output [4:0]  L4I_WR,

		output 	      L4J_WR_EN,
		output [4:0]  L4J_WR,

		output 	      L4K_WR_EN,
		output [4:0]  L4K_WR,

		output 	      L4L_WR_EN,
		output [4:0]  L4L_WR,

		//LEDs
		inout [3:0]   LED,
		
		//MONITORING PINS
		output [4:0]  MON,

		//PCI SIGNALS
		// Directional.
		input 	      PCI_CLK,
		inout 	      pci_rst, 
		input 	      pci_idsel,
		input 	      pci_gnt, 
		output 	      pci_req,
		// *Always* bidirectional. Shared bus.
		inout [31:0]  	pci_ad,
		inout 	      pci_perr, 
		inout				pci_par,
		inout 	      pci_trdy, 
		inout 	      pci_devsel, 
		inout 	      pci_stop, 
		
		inout [3:0]   	pci_cbe,
		inout 	      pci_frame, 
		inout 	      pci_irdy, 

		inout 	      pci_inta, 
		inout 	      pci_serr, 


		//TURF interface - comments on directionality if not SURF outputs
		output [7:0]  TD_P,
		output [7:0]  TD_N,
		output 	      SCLK_N,
		output 	      SCLK_P,
		
		// TURFbus control interface. Figure something out here.
		output 	      SREQ_neg, 
		input 	      TREQ_neg, 
		input 	      TCLK_N, 
		input 	      TCLK_P, 

		// PPS fanout from TURF.
		input 	      PPS_N, 
		input 	      PPS_P, 

		// Lock buffer. Digitize request comes via TURFbus.
		input [3:0]   HOLD,

		//Alternate path to (and from) TURF using transceiver
		/*
		input 	      TMGT_CLK_N,
		input 	      TMGT_CLK_P,
		output 	      TMGT_TX_N,
		output 	      TMGT_TX_P,
		input 	      TMGT_RX_N,
		input 	      TMGT_RX_P,
		 */

		// Local I2C bus, and monitoring path from
		// microcontroller.
		inout 	      UC_SCL, 
		inout 	      UC_SDA,
		
		// SPI.
		output			SPI_CS_neg,
		output			SPI_D0_MOSI,
		input 			SPI_D1_MISO,
		
		// Analog inputs
		input				MGT1V_P,
		input				MGT1V_N,
		input				MGT1P2_P,
		input				MGT1P2_N	
	 );
   
	wire [11:0] L4_RX;
	wire [11:0] L4_TX;
	wire [11:0] L4_CLK;
	wire [11:0] L4_TIMING;
	wire [7:0] TD = {8{1'b0}};
	generate
		genvar ii,jj;
		for (ii=0;ii<12;ii=ii+1) begin : ARCH
			IBUFDS u_rx_ibuf(.I(L4_RX_P[ii]),.IB(L4_RX_N[ii]),.O(L4_RX[ii]));
			IBUFDS u_timing_ibuf(.I(L4_TIMING_P[ii]),.IB(L4_TIMING_N[ii]),.O(L4_TIMING[ii]));
			OBUFDS u_tx_obuf(.I(L4_TX[ii]),.O(L4_TX_P[ii]),.OB(L4_TX_N[ii]));
			OBUFDS u_clk_obuf(.I(L4_CLK[ii]),.O(L4_CLK_P[ii]),.OB(L4_CLK_N[ii]));
		end
		for (jj=0;jj<8;jj=jj+1) begin : TURFBUS
			OBUFDS u_td_obuf(.I(TD[jj]),.OB(TD_N[jj]),.O(TD_P[jj]));
		end
	endgenerate

	wire FPGA_TURF_SST;
	wire FPGA_SST;
	IBUFDS u_turf_ibuf(.I(FPGA_TURF_SST_P),.IB(FPGA_TURF_SST_N),.O(FPGA_TURF_SST));
	OBUFDS u_sst_obuf(.I(FPGA_SST),.O(FPGA_SST_P),.OB(FPGA_SST_N));
	wire SCLK = 0;
	OBUFDS u_sclk_obuf(.I(SCLK),.O(SCLK_P),.OB(SCLK_N));

	wire PPS;
	IBUFDS u_pps_ibuf(.I(PPS_P),.IB(PPS_N),.O(PPS));

	// Debugging. There are 2 debugging busses, both 71 bits wide (using 2 block RAMs each).
	// 2 because we have 2 main clock domains.
	//
	// The debugging busses are multiplexed inside the main debug module. Adding more debugging
	// just means adding more ports to that module (and more select lines on the VIO).
	wire [70:0] wbc_debug;
	// global_debug is an 8 bit output async output path (it controls any global behavior that has no clock).
	// global_debug[0] is used for the WISHBONE clock selection.
	wire [7:0] global_debug;

	wire [70:0] lab4_debug;
	wire [70:0] rfp_debug;
	wire [70:0] lab4_i2c_debug;
	
	wire [70:0] pci_debug;
   // Internally there are three main busses: the 'control' WISHBONE bus, which has 3 masters and 4 slaves,
   // and the 'data' WISHBONE bus, which has 2 masters and 2 slaves, and the LAB4 I2C bus, which has
   // 12 slaves and 2 masters.
   // However, these are crossbared busses, so we have an utter bucket-ton of named wires here.
   // We will probably add a 4th master on the 'control' WISHBONE bus (an I2C-to-WISHBONE bridge to allow the uC
   // to pull out sensor data - an I2C to WISHBONE slave already exists).
   
   // Control WISHBONE bus clock. Probably the PCI clock.
   wire 		  wbc_clk;
   // Control WISHBONE bus reset.
   wire      wb_rst_out = 0;
   //% PPS. In WBC_CLK domain.
   wire      global_pps;
   //% PPS. In Sysclk domain.
   wire      global_pps_sysclk;
   //% External trigger (or whatever it's used for). In WBC_CLK domain.
   wire      global_ext_trig;
   //% External trigger. In Sysclk domain.
   wire      global_ext_trig_sysclk;   
      
   //% Internal LED control. Can be used by any module.
   wire [11:0] internal_led;
	assign internal_led = {12{1'b0}};
	
	// Right now no one is using them, so 
   //% Internal interrupts. Up to 31 can be used. 1 is used by SPI core.
   wire [30:0] 	    internal_interrupt;
	assign internal_interrupt[30:0] = {31{1'b0}};
	wire pci_interrupt;
	
   //% System clock (100 MHz).
   wire 	    sys_clk;
	//% Local clock (25 MHz).
	wire 		 local_clk_int;
	wire		 local_osc_en_int;
   //% WCLK enable
	wire [11:0] wclk_en;
	
	// WISHBONE control bus. These are all merged into a common bus in the wbc_intercon module.
	// pcic: PCI control master port WISHBONE bus.
   `WB_DEFINE( pcic, 32, 20, 4);
   // turfc: TURF control master port WISHBONE bus.
   `WB_DEFINE( turfc, 32, 20, 4);
   // hkmc: HK collector master port WISHBONE bus.
   `WB_DEFINE( hkmc, 32, 20, 4);
	// wbvio: VIO master port WISHBONE bus.
	`WB_DEFINE(wbvio, 32, 20, 4);
	
   // s4_id_ctrl: SURFv4 ID/Control slave port WISHBONE bus.
   `WB_DEFINE( s4_id_ctrl, 32, 16, 4);
   // hksc: HK collector slave port WISHBONE bus.
   `WB_DEFINE( hksc, 32, 16, 4);
	// lab4: LAB4 slave port WISHBONE bus.
	`WB_DEFINE( lab4, 32, 19, 4);
	// RFP: RFP slave port WISHBONE bus.
	`WB_DEFINE( rfp, 32, 19, 4);
  
	// WISHBONE data bus. These aren't merged anywhere yet. Still figuring out best methods.
	// pcid: PCI data slave port WISHBONE bus.
	`WB_DEFINE( pcid, 32, 32, 4);
	// turfd: TURF data slave port WISHBONE bus.
	`WB_DEFINE( turfd, 32, 32, 4);
	// Kill the PCID/TURFD busses. This just sets all the master signals to 0.
	`WB_KILL( pcid , 32, 32, 4);
	`WB_KILL( turfd , 32, 32, 4);

	// WISHBONE I2C bus. These are merged in the i2c_x12_top intercon module.
	// i2c_rfp: The RFP<->I2C WISHBONE bus.
   `WB_DEFINE( i2c_rfp, 8, 7, 1);
   // i2c_lab4: The LAB4<->I2C WISHBONE bus.
   `WB_DEFINE( i2c_lab4, 8, 7, 1);


	`PCI_TRIS(pci_rst);
	`PCI_TRIS(pci_inta);
	`PCI_TRIS(pci_req);
	`PCI_TRIS(pci_frame);
	`PCI_TRIS(pci_irdy);
	`PCI_TRIS(pci_devsel);
	`PCI_TRIS(pci_trdy);
	`PCI_TRIS(pci_stop);
	`PCI_TRIS(pci_par);
	`PCI_TRIS(pci_perr);
	`PCI_TRIS(pci_serr);
	`PCI_TRIS_VECTOR(pci_ad, 32);
	`PCI_TRIS_VECTOR(pci_cbe, 4);						

	// PCI bridge.
	pci_bridge32 u_pci(.pci_clk_i(PCI_CLK),
				`PCI_TRIS_CONNECT(pci_rst),
				.pci_req_o(pci_req_o),
				.pci_req_oe_o(pci_req_oe),
				.pci_gnt_i(pci_gnt),
				`PCI_TRIS_CONNECT(pci_inta),
				`PCI_TRIS_CONNECT(pci_frame),
				`PCI_TRIS_CONNECT(pci_irdy),
				.pci_idsel_i(pci_idsel),
				`PCI_TRIS_CONNECT(pci_devsel),
				`PCI_TRIS_CONNECT(pci_trdy),
				`PCI_TRIS_CONNECT(pci_stop),
				`PCI_TRIS_CONNECT(pci_ad),
				`PCI_TRIS_CONNECT(pci_cbe),
				`PCI_TRIS_CONNECT(pci_par),
				`PCI_TRIS_CONNECT(pci_perr),
				.pci_serr_o(pci_serr_o),
				.pci_serr_oe_o(pci_serr_oe),

				.wb_clk_i(wbc_clk),
				.wb_rst_o(wb_rst_in),
				.wb_rst_i(wb_rst_out),
				.wb_int_o(wb_int_in),
				.wb_int_i(pci_interrupt),

				`WBM_CONNECT(pcic, wbm),
				`WBS_CONNECT(pcid, wbs)
//				.wbm_cti_o(wbm_cti),
//				.wbm_bte_o(wbm_bte)
				);

	reg [31:0] pci_debug_data = {32{1'b0}};
	reg [19:0] pci_debug_adr = {20{1'b0}};
	reg [3:0] pci_debug_sel = {4{1'b0}};
	reg pci_debug_cyc = 0;
	reg pci_debug_stb = 0;
	reg pci_debug_ack = 0;
	reg pci_debug_we = 0;
	reg pci_debug_err = 0;
	reg pci_debug_rty = 0;
	
	always @(posedge wbc_clk) begin
		if (pcic_we_o) pci_debug_data <= pcic_dat_o;
		else pci_debug_data <= pcic_dat_i;
		
		pci_debug_adr <= pcic_adr_o;
		pci_debug_cyc <= pcic_cyc_o;
		pci_debug_sel <= pcic_sel_o;
		pci_debug_stb <= pcic_stb_o;
		pci_debug_we <= pcic_we_o;
		pci_debug_ack <= pcic_ack_i;
		pci_debug_err <= pcic_err_i;
		pci_debug_rty <= pcic_rty_i;
	end
   
	assign pci_debug[0 +: 32] = pci_debug_data;
	assign pci_debug[32 +: 20] = pci_debug_adr;
	assign pci_debug[52 +: 4] = pci_debug_sel;
	assign pci_debug[56] = pci_debug_cyc;
	assign pci_debug[57] = pci_debug_stb;
	assign pci_debug[58] = pci_debug_we;
	assign pci_debug[59] = pci_debug_ack;
	assign pci_debug[60] = pci_debug_err;
	assign pci_debug[61] = pci_debug_rty;	
	
	BUFGCTRL u_wbc_clk_mux(.I0(PCI_CLK),
								  .I1(local_clk_int),
								  .S0(!global_debug[0]),
								  .S1(global_debug[0]),
								  .IGNORE0(1'b0),
								  .IGNORE1(1'b0),
								  .CE0(1'b1),
								  .CE1(1'b1),
								  .O(wbc_clk));
	assign LOCAL_OSC_EN = global_debug[1]; //!(local_osc_en_int || global_debug[0]);

   // WISHBONE Control bus interconnect. This is the first stupid version, which does not handle registered WISHBONE transfers,
   // and is just a shared bus interconnect.
   wbc_intercon u_wbc_intercon(	.clk_i(wbc_clk),.rst_i(wbc_rst),
				`WBS_CONNECT(pcic, pcic),
				`WBS_CONNECT(turfc, turfc),
				`WBS_CONNECT(hkmc, hkmc),
				`WBS_CONNECT(wbvio, wbvio),
				`WBM_CONNECT(s4_id_ctrl, s4_id_ctrl),
				`WBM_CONNECT(hksc, hksc),
				`WBM_CONNECT(rfp, rfp),
				`WBM_CONNECT(lab4, lab4),
				.debug_o(wbc_debug));
   
   // TURFbus. This is the data path back to the TURF.
   // This also needs a slave port definition for the data side bus.
   // Also needs the top-level port connections to the TURFbus.
   turfbus u_turfbus( .wbm_clk_i(wbc_clk),
				.TCLK_P(TCLK_P),.TCLK_N(TCLK_N),
		      .wbm_rst_i(wbc_rst),		      
		      `WBM_CONNECT(turfc, wbm));
   
   // SURF4 ID and Control block. This allows for reading out device and firmware ID registers,
   // reprogramming the SPI flash, global ICE40 reset, LED control, and clock selection.
   // Also handles external trigger input/debounce.
   surf4_id_ctrl u_surf4_id_ctrl(.clk_i(wbc_clk),.rst_i(wbc_rst),
				 `WBS_CONNECT(s4_id_ctrl, wb),
				 // Interrupts.
				 .pci_interrupt_o(pci_interrupt),
				 .interrupt_i(internal_interrupt),
				 // Internal LEDs.
				 .internal_led_i(internal_led),
				 // System clock output.
				 .sys_clk_o(sys_clk),
				 // Local clock output (25 MHz).
				 .local_clk_o(local_clk_int),
				 // PPS generation, in both domains.
				 // Note that this may be a fake internal PPS
				 // if no external PPS has been detected.
				 .pps_o(global_pps),
				 .pps_sysclk_o(global_pps_sysclk),
				 // Ext trig generation, in both domains.
				 .ext_trig_o(global_ext_trig),
				 .ext_trig_sysclk_o(global_ext_trig_sysclk),
				 // WCLK control
				 .wclk_en_i(wclk_en),
				 // Ext trig port
				 .EXT_TRIG(EXT_TRIG),
				 // PPS port
				 .PPS(PPS),
				 // SPI ports
				 .MOSI(SPI_D0_MOSI),
				 .MISO(SPI_D1_MISO),
				 .CS_B(SPI_CS_neg),
				 // ICE40 ports
				 .ICE40_RESET(ICE40_RESET),
				 // LED ports
				 .LED(LED),
				 .FP_LED(FP_LED),
				 // Clock ports.
				 .LOCAL_CLK(LOCAL_CLK),
				 .LOCAL_OSC_EN(local_osc_en_int),
				 .FPGA_SST_SEL(FPGA_SST_SEL),
				 .FPGA_SST(FPGA_SST),
				 .FPGA_TURF_SST(FPGA_TURF_SST),
				 // WCLK
				 .L4_WCLK_P(L4_WCLK_P),
				 .L4_WCLK_N(L4_WCLK_N));
   
   // HK Collector. This contains internal sensors (through the XADC block), a few other statistics
   // (clock frequency), and it also handles reading out the HK data from the LAB4s and RFPs, packaging it up,
   // and transferring it back over the PCI bus via DMA. It could also transfer data to the TURF as well
   // although I don't think that will be used.
   //
   // Note that this means this has *three* WISHBONE ports. A slave control, a master control, and a master data.
   // We only implement 2 of the 3 right now (no WISHBONE data bus yet).
   surf4_hk_collector u_hk_collector(.clk_i(wbc_clk),.rst_i(wbc_rst),
				     `WBS_CONNECT(hksc, wbsc),
				     `WBM_CONNECT(hkmc, wbmc),
				     .pps_i(global_pps),
					  .MGT1V_P(MGT1V_P),
					  .MGT1V_N(MGT1V_N),
					  .MGT1P2_P(MGT1P2_P),
					  .MGT1P2_N(MGT1P2_N));
   
   // RFP module. This handles reading out and control over the RF power section.
   // This has two WISHBONE ports: a slave control, and a master i2c.
   surf4_rfp u_rfp(.clk_i(wbc_clk),.rst_i(wbc_rst),
		   `WBS_CONNECT(rfp, wbc),
		   `WBM_CONNECT(i2c_rfp, i2c),
		   .pps_i(global_pps),
			.debug_o(rfp_debug));
	
   // LAB4 module. This handles LAB4 control and readouts. This has *three* WISHBONE ports.
   // A slave control, for initialization, commanding, etc.
   // A master i2c, for actually talking to the DACs.
   // A master data, for sending the data out.
   lab4_top u_lab4(.wbc_clk_i(wbc_clk),.wbc_rst_i(wbc_rst),
		   `WBS_CONNECT(lab4, wbc),
		   `WBM_CONNECT(i2c_lab4, i2c),
			.i2c_debug_o(lab4_i2c_debug),
		   .sys_clk_i(sys_clk),
		   .pps_i(global_pps),
		   .pps_sysclk_i(global_pps_sysclk),
			.wclk_en_o(wclk_en),
			.debug_o(lab4_debug),
		   // ICE40 connections.
		   .L4_RX(L4_RX),
		   .L4_TX(L4_TX),
		   .L4_CLK(L4_CLK),
		   // MONTIMING inputs.
		   .L4_TIMING(L4_TIMING),
		   // Write port connections.
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
			.HOLD(HOLD)); //LM was missing before
   
   // Notes on the I2C WISHBONE bus:
   // This bus will consists of 12 OpenCores I2C controller modules interconnected via a crossbar switch, to allow both the RFP
   // and LAB4 modules to access the LAB4 I2C busses freely.
   // To manage access to the I2C bus without clashing, the modules need to check the BUSY, TIP, and IF bits in the Status register.
   // When both of those bits are low, a transaction can begin freely.
   // (Remember that cyc can be held arbitrarily long to claim the bus for uninterruptible transactions: e.g., between checking BUSY/TIP/IF
   // and beginning a new transaction).
   //
   // A PicoBlaze might be helpful here. Is this efficient? No, but it is quick, which is what we need.
   wire 	    i2c_clk = wbc_clk;
   wire 	    i2c_rst = 0;
	wire [23:0] i2c_debug;
   i2c_x12_top u_i2c_x12(.clk_i(i2c_clk),.rst_i(i2c_rst),
			 `WBS_CONNECT(i2c_rfp, wb1),
			 `WBS_CONNECT(i2c_lab4, wb0),
			 .SDA(L4_SDA),
			 .SCL(L4_SCL),
			 .debug_o(i2c_debug));

	surf4_debug u_debug(.wbc_clk_i(wbc_clk),
							  .clk0_i(wbc_clk),
							  .clk1_i(sys_clk),
							  `WBM_CONNECT(wbvio, wbvio),
							  .wbc_debug_i(pci_debug),
							  .ice_debug_i(lab4_debug),
							  .i2c_debug_i(i2c_debug),
							  .lab4_i2c_debug_i(lab4_i2c_debug),
							  .rfp_debug_i(rfp_debug),
							  .global_debug_o(global_debug));

	assign MON = {5{1'b0}};
	assign SREQ_neg = 1;
endmodule
