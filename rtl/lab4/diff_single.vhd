----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:46:18 03/06/2014 
-- Design Name: 
-- Module Name:    diff_single - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity diff_single is
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
end diff_single;

architecture Behavioral of diff_single is

begin

gen_OBUFDS_L4_CLK: for i in 0 to 11 generate
OBUFDS_L4_CLK : OBUFDS
generic map (
IOSTANDARD => "LVDS_25") -- Specify the output I/O standard
port map (
O => L4_CLK_P_out(i), -- Diff_p output (connect directly to top-level port)
OB => L4_CLK_N_out(i), -- Diff_n output (connect directly to top-level port)
I => L4_CLK_in(i)-- Buffer input
);
end generate;


gen_IBUFD_L4_RX: for i in 0 to 11 generate
IBUFDS_L4_RX : IBUFDS
generic map (
IOSTANDARD => "LVDS_25")
port map (
O => L4_RX_out(i), -- Clock buffer output
I => L4_RX_P_in(i), -- Diff_p clock buffer input (connect to top-level port)
IB => L4_RX_N_in(i) -- Diff_n clock buffer input (connect directly to toplevel port)
);
end generate;

gen_OBUFDS_L4_TX: for i in 0 to 11 generate
OBUFDS_L4_TX : OBUFDS
generic map (
IOSTANDARD => "LVDS_25") -- Specify the output I/O standard
port map (
O => L4_TX_P_out(i), -- Diff_p output (connect directly to top-level port)
OB => L4_TX_N_out(i), -- Diff_n output (connect directly to top-level port)
I => L4_TX_in(i)-- Buffer input
);
end generate;


gen_IBUFD_L4_TIMING: for i in 0 to 11 generate
IBUFDS_L4_TIMING : IBUFDS
generic map (
IOSTANDARD => "LVDS_25")
port map (
O => L4_TIMING_out(i), -- Clock buffer output
I => L4_TIMING_P_in(i), -- Diff_p clock buffer input (connect to top-level port)
IB => L4_TIMING_N_in(i) -- Diff_n clock buffer input (connect directly to toplevel port)
);
end generate;


gen_OBUFDS_L4_WCLK: for i in 0 to 11 generate
OBUFDS_L4_WCLK : OBUFDS
generic map (
IOSTANDARD => "LVDS_25") -- Specify the output I/O standard
port map (
O => L4_WCLK_P_out(i), -- Diff_p output (connect directly to top-level port)
OB => L4_WCLK_N_out(i), -- Diff_n output (connect directly to top-level port)
I => L4_WCLK_in(i)-- Buffer input
);
end generate;


end Behavioral;

