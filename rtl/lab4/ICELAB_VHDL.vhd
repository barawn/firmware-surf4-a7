----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:44:14 03/13/2014 
-- Design Name: 
-- Module Name:    ICELAB_VHDL - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity ICELAB_VHDL is
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
end ICELAB_VHDL;

architecture Behavioral of ICELAB_VHDL is

component ICELAB
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
begin


ICELAB_u : ICELAB port map(
CLK_P   ,
	 CLK_N   ,

	 RX_P   ,
	 RX_N   ,

	 TX_P   ,
	 TX_N  ,
	      
	 REGCLR  ,
	 PT   ,

	 SIN   ,
	 SCLK   ,
	 UPDATE   ,
	 PCLK   ,

	 RD  ,
	 RD_EN   ,
	 CLR   ,
	 RAMP   ,

	 DOE_P   ,
	 DOE_N  ,
    SRCLK_P  ,
	 SRCLK_N ,
	 SS_INCR  ,
	 SR_SEL  ,
	 SEL_ANY   ,
	 LED 
);


end Behavioral;

