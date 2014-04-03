----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:25:46 02/13/2013 
-- Design Name: 
-- Module Name:    read_master - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.RX_TX_definitions.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity read_master_SURF is
port(
CLK : in std_logic;
--start_read
trigger : in std_logic;

others_in_process : in std_logic;
readout_in_process : out std_logic;
-- interface with write_master
--curr_bank : in std_logic_vector(1 downto 0);
low_bank_A : in std_logic_vector(2 downto 0); -- need to try to see if this indicates the last or the first written and modify the mapping of digitize_address as a consequence 
low_bank_B : in std_logic_vector(2 downto 0);
low_bank_C : in std_logic_vector(2 downto 0);
low_bank_D : in std_logic_vector(2 downto 0);
held_banks : in std_logic_vector(3 downto 0);
desired_bank : in std_logic_vector(1 downto 0);
-- communication with RX_TX
TX_do_command : out std_logic_vector(11 downto 0);
TX_command : out std_logic_vector(7 downto 0);
TX_arg1 : out std_logic_vector(7 downto 0);
RX_done : in std_logic_vector(11 downto 0);
RX_NACK: in std_logic_vector(11 downto 0);
read_done : out std_logic;
--PData_out  : out std_logic_vector(11 downto 0);
digitize_address : out std_logic_vector(4 downto 0) -- real block address - common to all 12 chips
--new_window_readout_start : out std_logic -- to inform histogram that a new window is started now - just for debugging
);
end read_master_SURF;

architecture Behavioral of read_master_SURF is

signal internal_digitize_address :  std_logic_vector(4 downto 0);
signal low :  std_logic_vector(2 downto 0);
signal start_low :  std_logic_vector(2 downto 0);
signal bank :  std_logic_vector(1 downto 0);






type state_t is (IDLE, SET_WINDOW, DIGITIZE, WAIT_FOR_DIGITIZE, RDOUT, WAIT_FOR_RDOUT, DONE);
signal state : state_t := IDLE;


begin

digitize_address <= internal_digitize_address;

internal_digitize_address<= bank & low;
process(CLK)
begin
if rising_edge(CLK) then
	read_done <= '0';
	TX_do_command <= x"000";
	case state is
		when IDLE => if trigger = '1' and held_banks(conv_integer(desired_bank)) = '1' and others_in_process = '0' then state <= SET_WINDOW; -- this refuses to digitize if writing is still taking place 
									bank <= desired_bank; 
									readout_in_process <='1';
									case desired_bank is
									when "00" => 	low <= low_bank_A;-- start from the first after most recent written
														start_low <= low_bank_A;
									when "01" => 	low <= low_bank_B;-- start from the first after most recent written
														start_low <= low_bank_B;
									when "10" => 	low <= low_bank_C;-- start from the first after most recent written
														start_low <= low_bank_C;
									when "11" => 	low <= low_bank_D;-- start from the first after most recent written
														start_low <= low_bank_D;
									when others => 	low <= low_bank_A;-- start from the first after most recent written
														start_low <= low_bank_A;
									end case;
						 end if;
									readout_in_process <='0';
		when SET_WINDOW => low <= low +1;-- start from the first after most recent written
									readout_in_process <='1';
									state <= DIGITIZE;
		when DIGITIZE => TX_do_command <= x"fff";
								TX_command<= WILKINSON_CONVERT;
								TX_arg1 <= "000" & internal_digitize_address;
								state <= WAIT_FOR_DIGITIZE;
									readout_in_process <='1';
		when WAIT_FOR_DIGITIZE => if RX_done(0) = '1' then --looking only at 0 
											state <= RDOUT; 
										  elsif RX_NACK(0) = '1' then --retry if NACK. -- still looking only at 0
											state <= DIGITIZE;
										  end if;
									readout_in_process <='1';
		when RDOUT => TX_do_command <= x"fff";
						  TX_command<= READOUT;
						  state <= WAIT_FOR_RDOUT;
									readout_in_process <='1';
		when WAIT_FOR_RDOUT => if RX_done(0) = '1' then --looking only at 0 
											if low = start_low then state <= DONE;
											else state <= SET_WINDOW;
											end if;
										  elsif RX_NACK(0) = '1' then --retry if NACK.  -- still looking only at 0
											state <= RDOUT;
										  end if;
									readout_in_process <='1';
		when DONE => state <= IDLE; read_done<='1';
		when others => state <= IDLE;
	end case;
end if;
end process;


end Behavioral;

