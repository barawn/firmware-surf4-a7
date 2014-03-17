--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:54:46 03/11/2014
-- Design Name:   
-- Module Name:   C:/Users/Luca/Desktop/ANITA/SURF4_A7/par/tb_lab4_top.vhd
-- Project Name:  SURF4_A7
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lab4_top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_lab4_top IS
END tb_lab4_top;
 
ARCHITECTURE behavior OF tb_lab4_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lab4_top
    PORT(
         wbc_clk_i : IN  std_logic;
         wbc_rst_i : IN  std_logic;
         wbc_dat_o : OUT  std_logic_vector(31 downto 0);
         wbc_dat_i : IN  std_logic_vector(31 downto 0);
         wbc_adr_i : IN  std_logic_vector(18 downto 0);
         wbc_cyc_i : IN  std_logic;
         wbc_we_i : IN  std_logic;
         wbc_stb_i : IN  std_logic;
         wbc_ack_o : OUT  std_logic;
         wbc_rty_o : OUT  std_logic;
         wbc_err_o : OUT  std_logic;
         wbc_sel_i : IN  std_logic_vector(0 downto 0);
         sys_clk_i : IN  std_logic;
         pps_i : IN  std_logic;
         pps_sysclk_i : IN  std_logic;
         L4_RX : IN  std_logic_vector(11 downto 0);
         L4_TX : OUT  std_logic_vector(11 downto 0);
         L4_CLK : OUT  std_logic_vector(11 downto 0);
         L4_TIMING : IN  std_logic_vector(11 downto 0);
         L4_WCLK : OUT  std_logic_vector(11 downto 0);
         L4A_WR_EN : OUT  std_logic;
         L4A_WR : OUT  std_logic_vector(4 downto 0);
         L4B_WR_EN : OUT  std_logic;
         L4B_WR : OUT  std_logic_vector(4 downto 0);
         L4C_WR_EN : OUT  std_logic;
         L4C_WR : OUT  std_logic_vector(4 downto 0);
         L4D_WR_EN : OUT  std_logic;
         L4D_WR : OUT  std_logic_vector(4 downto 0);
         L4E_WR_EN : OUT  std_logic;
         L4E_WR : OUT  std_logic_vector(4 downto 0);
         L4F_WR_EN : OUT  std_logic;
         L4F_WR : OUT  std_logic_vector(4 downto 0);
         L4G_WR_EN : OUT  std_logic;
         L4G_WR : OUT  std_logic_vector(4 downto 0);
         L4H_WR_EN : OUT  std_logic;
         L4H_WR : OUT  std_logic_vector(4 downto 0);
         L4I_WR_EN : OUT  std_logic;
         L4I_WR : OUT  std_logic_vector(4 downto 0);
         L4J_WR_EN : OUT  std_logic;
         L4J_WR : OUT  std_logic_vector(4 downto 0);
         L4K_WR_EN : OUT  std_logic;
         L4K_WR : OUT  std_logic_vector(4 downto 0);
         L4L_WR_EN : OUT  std_logic;
         L4L_WR : OUT  std_logic_vector(4 downto 0);
         HOLD : IN  std_logic_vector(3 downto 0)
        );
    END COMPONENT;

component ICELAB_VHDL
port( 
 CLK_P : in std_logic;
	 CLK_N : in std_logic;

	 RX_P : in std_logic;
	 RX_N : in std_logic;

	 TX_P : out std_logic;
	 TX_N : out std_logic;
	      
	 REGCLR : out std_logic;
	 PT : out std_logic;

	 SIN : out std_logic;
	 SCLK : out std_logic;
	 UPDATE : out std_logic;
	 PCLK : out std_logic;

	RD : out std_logic_vector(4 downto 0);
	 RD_EN : out std_logic;
	 CLR : out std_logic;
	 RAMP : out std_logic;

	 DOE_P : in std_logic;
	 DOE_N : in std_logic;
    SRCLK_P: out std_logic;
	 SRCLK_N : out std_logic;
	 SS_INCR: out std_logic;
	 SR_SEL: out std_logic;
	 SEL_ANY : out std_logic;
	 LED: out std_logic
);
end component;


signal L4_CLK_in :  std_logic_vector(11 downto 0);


component diff_single is
port(
L4_CLK_in : in std_logic_vector(11 downto 0);
L4_CLK_P_out : out std_logic_vector(11 downto 0);
L4_CLK_N_out : out std_logic_vector(11 downto 0);
L4_RX_out : out std_logic_vector(11 downto 0);
L4_RX_P_in : in std_logic_vector(11 downto 0);
L4_RX_N_in : in std_logic_vector(11 downto 0);
L4_TX_in : in std_logic_vector(11 downto 0);
L4_TX_P_out : out std_logic_vector(11 downto 0);
L4_TX_N_out : out std_logic_vector(11 downto 0);
L4_TIMING_out : out std_logic_vector(11 downto 0);
L4_TIMING_P_in : in std_logic_vector(11 downto 0);
L4_TIMING_N_in : in std_logic_vector(11 downto 0);
L4_WCLK_in : in std_logic_vector(11 downto 0);
L4_WCLK_P_out : out std_logic_vector(11 downto 0);
L4_WCLK_N_out : out std_logic_vector(11 downto 0)
);
end component;


   --Inputs
   signal wbc_clk_i : std_logic := '0';
   signal wbc_rst_i : std_logic := '0';
   signal wbc_dat_i : std_logic_vector(31 downto 0) := (others => '0');
   signal wbc_adr_i : std_logic_vector(18 downto 0) := (others => '0');
   signal wbc_cyc_i : std_logic := '0';
   signal wbc_we_i : std_logic := '0';
   signal wbc_stb_i : std_logic := '0';
   signal wbc_sel_i : std_logic_vector(0 downto 0) := (others => '0');
   signal sys_clk_i : std_logic := '0';
   signal pps_i : std_logic := '0';
   signal pps_sysclk_i : std_logic := '0';
   signal L4_RX : std_logic_vector(11 downto 0) := (others => '0');
   signal L4_RX_N : std_logic_vector(11 downto 0) := (others => '0');
   signal L4_RX_P : std_logic_vector(11 downto 0) := (others => '0');
   signal L4_TIMING : std_logic_vector(11 downto 0) := (others => '0');
   signal HOLD : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal wbc_dat_o : std_logic_vector(31 downto 0);
   signal wbc_ack_o : std_logic;
   signal wbc_rty_o : std_logic;
   signal wbc_err_o : std_logic;
   signal L4_TX : std_logic_vector(11 downto 0);
   signal L4_TX_N : std_logic_vector(11 downto 0);
   signal L4_TX_P : std_logic_vector(11 downto 0);
--   signal L4_CLK : std_logic_vector(11 downto 0);
   signal L4_WCLK : std_logic_vector(11 downto 0);
   signal L4A_WR_EN : std_logic;
   signal L4A_WR : std_logic_vector(4 downto 0);
   signal L4B_WR_EN : std_logic;
   signal L4B_WR : std_logic_vector(4 downto 0);
   signal L4C_WR_EN : std_logic;
   signal L4C_WR : std_logic_vector(4 downto 0);
   signal L4D_WR_EN : std_logic;
   signal L4D_WR : std_logic_vector(4 downto 0);
   signal L4E_WR_EN : std_logic;
   signal L4E_WR : std_logic_vector(4 downto 0);
   signal L4F_WR_EN : std_logic;
   signal L4F_WR : std_logic_vector(4 downto 0);
   signal L4G_WR_EN : std_logic;
   signal L4G_WR : std_logic_vector(4 downto 0);
   signal L4H_WR_EN : std_logic;
   signal L4H_WR : std_logic_vector(4 downto 0);
   signal L4I_WR_EN : std_logic;
   signal L4I_WR : std_logic_vector(4 downto 0);
   signal L4J_WR_EN : std_logic;
   signal L4J_WR : std_logic_vector(4 downto 0);
   signal L4K_WR_EN : std_logic;
   signal L4K_WR : std_logic_vector(4 downto 0);
   signal L4L_WR_EN : std_logic;
   signal L4L_WR : std_logic_vector(4 downto 0);


--ICE i/o
--inputs
signal 	 CLK_P :  std_logic_vector(11 downto 0);
signal	 CLK_N :  std_logic_vector(11 downto 0);

signal	 RX_P :  std_logic_vector(11 downto 0);
signal	 RX_N :  std_logic_vector(11 downto 0);


signal	 DOE_P :  std_logic_vector(11 downto 0);
signal	 DOE_N :  std_logic_vector(11 downto 0);


--outputs
type	 RD_t is  array(0 to 11) of std_logic_vector(4 downto 0);

	      
signal	 REGCLR :  std_logic_vector(11 downto 0);
signal	 PT :  std_logic_vector(11 downto 0);

signal	 SIN :  std_logic_vector(11 downto 0);
signal	 SCLK :  std_logic_vector(11 downto 0);
signal	 UPDATE :  std_logic_vector(11 downto 0);
signal	 PCLK :  std_logic_vector(11 downto 0);

signal	 RD :  RD_t;
signal	 RD_EN :  std_logic_vector(11 downto 0);
signal	 CLR :  std_logic_vector(11 downto 0);
signal	 RAMP :  std_logic_vector(11 downto 0);

signal	 TX_P :  std_logic_vector(11 downto 0);
signal	 TX_N :  std_logic_vector(11 downto 0);

signal    SRCLK_P:  std_logic_vector(11 downto 0);
signal	 SRCLK_N :  std_logic_vector(11 downto 0);
signal	 SS_INCR:  std_logic_vector(11 downto 0);
signal	 SR_SEL:  std_logic_vector(11 downto 0);
signal	 SEL_ANY :  std_logic_vector(11 downto 0);
signal	 LED:  std_logic_vector(11 downto 0);

signal	 PCI_DATA_LOW:  std_logic_vector(15 downto 0);
signal	 PCI_DATA_HIGH:  std_logic_vector(15 downto 0);
--signal	 sample:  std_logic_vector(11 downto 0) := (others => '0');


   -- Clock period definitions
   constant L4_CLK_period : time := 10 ns;
   constant L4_WCLK_period : time := 10 ns;
   constant PCI_CLK_period : time := 30 ns; -- should be 30.303....
 
 	signal	 sample_s:  std_logic_vector(11 downto 0) := (others => '0');

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lab4_top PORT MAP (
          wbc_clk_i => wbc_clk_i,
          wbc_rst_i => wbc_rst_i,
          wbc_dat_o => wbc_dat_o,
          wbc_dat_i => wbc_dat_i,
          wbc_adr_i => wbc_adr_i,
          wbc_cyc_i => wbc_cyc_i,
          wbc_we_i => wbc_we_i,
          wbc_stb_i => wbc_stb_i,
          wbc_ack_o => wbc_ack_o,
          wbc_rty_o => wbc_rty_o,
          wbc_err_o => wbc_err_o,
          wbc_sel_i => wbc_sel_i,
          sys_clk_i => sys_clk_i,
          pps_i => pps_i,
          pps_sysclk_i => pps_sysclk_i,
          L4_RX => L4_RX,
          L4_TX => L4_TX,
          L4_CLK => open, -- generated separately
          L4_TIMING => L4_TIMING,
          L4_WCLK => open, -- generated separately
          L4A_WR_EN => L4A_WR_EN,
          L4A_WR => L4A_WR,
          L4B_WR_EN => L4B_WR_EN,
          L4B_WR => L4B_WR,
          L4C_WR_EN => L4C_WR_EN,
          L4C_WR => L4C_WR,
          L4D_WR_EN => L4D_WR_EN,
          L4D_WR => L4D_WR,
          L4E_WR_EN => L4E_WR_EN,
          L4E_WR => L4E_WR,
          L4F_WR_EN => L4F_WR_EN,
          L4F_WR => L4F_WR,
          L4G_WR_EN => L4G_WR_EN,
          L4G_WR => L4G_WR,
          L4H_WR_EN => L4H_WR_EN,
          L4H_WR => L4H_WR,
          L4I_WR_EN => L4I_WR_EN,
          L4I_WR => L4I_WR,
          L4J_WR_EN => L4J_WR_EN,
          L4J_WR => L4J_WR,
          L4K_WR_EN => L4K_WR_EN,
          L4K_WR => L4K_WR,
          L4L_WR_EN => L4L_WR_EN,
          L4L_WR => L4L_WR,
          HOLD => HOLD
        );
--connection between LAB4_top and ICELAB:

RX_P<= L4_TX_P;
RX_N<= L4_TX_N;
L4_RX_P<= TX_P;
L4_RX_N<= TX_N;

 
ICELAB_g : for i in 0 to 11 generate
ICELAB_u : ICELAB_VHDL port map(
	 CLK_P =>  CLK_P(i),
	 CLK_N => CLK_N(i) ,

	 RX_P => RX_P(i) ,
	 RX_N => RX_N(i) ,

	 TX_P => TX_P(i) ,
	 TX_N =>TX_N(i) ,
	      
	 REGCLR => REGCLR(i) ,
	 PT => PT(i) ,

	 SIN => SIN(i) ,
	 SCLK => SCLK(i) ,
	 UPDATE => UPDATE(i) ,
	 PCLK => PCLK(i) ,

	 RD => RD(i),
	 RD_EN => RD_EN(i) ,
	 CLR => CLR(i) ,
	 RAMP => RAMP(i) ,

	 DOE_P =>DOE_P(i) ,
	 DOE_N => DOE_N(i),
    SRCLK_P=> SRCLK_P(i) ,
	 SRCLK_N => SRCLK_N(i),
	 SS_INCR=> SS_INCR(i) ,
	 SR_SEL=> SR_SEL(i) ,
	 SEL_ANY => SEL_ANY(i) ,
	 LED=> LED(i)
);
end generate;

--
--ICELAB_0 : ICELAB port map(
--	 CLK_P =>  CLK_P(0),
--	 CLK_N => CLK_N(0) ,
--
--	 RX_P => RX_P(0) ,
--	 RX_N => RX_N(0) ,
--
--	 TX_P => TX_P(0) ,
--	 TX_N =>TX_N(0) ,
--	      
--	 REGCLR => REGCLR(0) ,
--	 PT => PT(0) ,
--
--	 SIN => SIN(0) ,
--	 SCLK => SCLK(0) ,
--	 UPDATE => UPDATE(0) ,
--	 PCLK => PCLK(0) ,
--
--	 RD => RD(0),
--	 RD_EN => RD_EN(0) ,
--	 CLR => CLR(0) ,
--	 RAMP => RAMP(0) ,
--
--	 DOE_P =>DOE_P(0) ,
--	 DOE_N => DOE_N(0),
--    SRCLK_P=> SRCLK_P(0) ,
--	 SRCLK_N => SRCLK_N(0),
--	 SS_INCR=> SS_INCR(0) ,
--	 SR_SEL=> SR_SEL(0) ,
--	 SEL_ANY => SEL_ANY(0) ,
--	 LED=> LED(0)
--);
--
--ICELAB_1 : ICELAB port map(
--CLK_P =>  '0',
--	 CLK_N => '1' ,
--
--	 RX_P => '0' ,
--	 RX_N => '1' ,
--
--	 TX_P => open ,
--	 TX_N =>open ,
--	      
--	 REGCLR =>open ,
--	 PT => open ,
--
--	 SIN => open ,
--	 SCLK => open ,
--	 UPDATE => open ,
--	 PCLK => open ,
--
--	 RD => open,
--	 RD_EN => open ,
--	 CLR => open ,
--	 RAMP => open ,
--
--	 DOE_P => '0' ,
--	 DOE_N => '1',
--    SRCLK_P=> open ,
--	 SRCLK_N =>open,
--	 SS_INCR=> open ,
--	 SR_SEL=> open ,
--	 SEL_ANY => open ,
--	 LED=> open
--);

--differential signal gen -- not all used for this simulation


diff_single_u : diff_single 
port map(
L4_CLK_in => L4_CLK_in,
L4_CLK_P_out => CLK_P,
L4_CLK_N_out => CLK_N,
L4_RX_out => L4_RX, 
L4_RX_P_in => L4_RX_P,
L4_RX_N_in => L4_RX_N,
L4_TX_in => L4_TX,
L4_TX_P_out => L4_TX_P,
L4_TX_N_out => L4_TX_N,
L4_TIMING_out => open,
L4_TIMING_P_in => x"000",
L4_TIMING_N_in => x"fff",
L4_WCLK_in => x"000",
L4_WCLK_P_out => open,
L4_WCLK_N_out => open
);

   -- Clock process definitions
   L4_CLK_process :process
   begin
		L4_CLK_in <= x"000";
		wait for L4_CLK_period/2;
		L4_CLK_in <= x"fff";
		wait for L4_CLK_period/2;
   end process;
-- 
--   L4_WCLK_process :process
--   begin
--		L4_WCLK <= '0';
--		wait for L4_WCLK_period/2;
--		L4_WCLK <= '1';
--		wait for L4_WCLK_period/2;
--   end process;
   PCI_CLK_process :process
   begin
		wbc_clk_i <= '0';
		wait for PCI_CLK_period/2;
		wbc_clk_i <= '1';
		wait for PCI_CLK_period/2;
   end process;
wbc_rst_i <= '0';
sys_clk_i<= L4_CLK_in(0);
wbc_sel_i <= "0";
PCI_DATA_HIGH <= wbc_dat_o(31 downto 16);
PCI_DATA_LOW <= wbc_dat_o(15 downto 0);
pps_i <= '0';
pps_sysclk_i <= '0';

   -- Stimulus process
   stim_proc: process -- uses the PCI clock
   begin		
      -- hold reset state for 100 ns.
		HOLD<="1101";
		wbc_dat_i<= x"00000000";
		wbc_adr_i<= '0' & x"0000" & "00"; -- MSb = command or memory read - address (as in write/2) - 2 blank bits
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';

      wait for 100 ns;	
		
      wait for PCI_CLK_period*10;
		-----------C/\Mem-uuuuu----command---PCIlow
		wbc_adr_i<= '1' & x"000" & "0010" & "00"; -- choice phase write command
		wbc_dat_i<= x"0000000" & "0111"; -- to see if it works
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='1';
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period*40;
		-----------C/\Mem-uuuuu----command---PCIlow
		wbc_adr_i<= '1' & x"000" & "0001" & "00"; -- loaded DAC write command
		wbc_dat_i<= x"00000001";
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='1';
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period*40;
		-----------C/\Mem-uuuuu----command---PCIlow
		wbc_adr_i<= '1' & x"000" & "0011" & "00"; -- choose RAM bank 0 write command
		wbc_dat_i<= x"00000000";
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='1';
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period*40;
		HOLD<="1111"; -- break before...
      wait for PCI_CLK_period;
		HOLD<="1011"; -- ...make - and trigger at the same time
		-----------C/\Mem-uuuuu----command---PCIlow
		wbc_adr_i<= '1' & x"000" & "0000" & "00"; -- trigger ASIC bank 01 write command
		wbc_dat_i<= x"00000001"; --choose bank 1
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='1';
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period*16000;		 -- and for now just make sure something happens.... memory should be written into
		for i in 0 to 511 loop -- *2 - an entire bank of 1024 samples - lower bank
		--------- C/\Mem---ASIC#-MBANK--BANK----------Sample#+-----------lowbitsPCI------        
		wbc_adr_i<= '0' &  x"0" & '0' & "01" & conv_std_logic_vector(i,9) & "00"; --  ASIC 0 bank 00 read memory
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='0'; -- read		
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period;
		end loop;
      wait for PCI_CLK_period*100;
		for i in 0 to 511 loop -- *2 - an entire bank of 1024 samples - lower bank
		--------- C/\Mem---ASIC#-MBANK--BANK----------Sample#+-----------lowbitsPCI------        
		wbc_adr_i<= '0' &  x"6" & '0' & "01" & conv_std_logic_vector(i,9) & "00"; --  ASIC 1 bank 00 read memory
		wbc_cyc_i<='1';
		wbc_stb_i<='1';
		wbc_we_i<='0'; -- read		
      wait for PCI_CLK_period;
		wbc_cyc_i<='0';
		wbc_stb_i<='0';
		wbc_we_i<='0';
      wait for PCI_CLK_period;
		end loop;

      -- insert stimulus here 

      wait;
   end process;
	
	rf_inputs: process
	variable	 sample:  std_logic_vector(11 downto 0) := (others => '0');
	variable	 ASIC_sample:  std_logic_vector(11 downto 0) := (others => '0');

	begin
		DOE_P<= (others => '0');
		DOE_N<= (others => '1'); 
		   wait for 100 ns;	
      wait for L4_CLK_period*2;
		while 1=1 loop
		sample := sample + 1;
		sample_s <= sample;
		for i in 11 downto 0 loop -- BIG endian for DOE?
		for j in 0 to 11 loop
		ASIC_sample := conv_std_logic_vector(j,4) & sample(7 downto 0);	
		DOE_P(j)<=ASIC_sample(i);
		DOE_N(j)<=not ASIC_sample(i);
		end loop;
      wait for L4_CLK_period;
		end loop;
		end loop;
	end process;
	
	PHAB_gen: process
	begin
	L4_TIMING<= (others => '0');
      wait for L4_CLK_period;
	L4_TIMING<= (others => '1');
      wait for L4_CLK_period;	
	end process;
END;
