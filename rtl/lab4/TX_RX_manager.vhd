----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:53:03 03/17/2014 
-- Design Name: 
-- Module Name:    TX_RX_manager - Behavioral 
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

entity TX_RX_manager is
port(
CLK : in std_logic;
preempt : in std_logic;
preempt_out : out std_logic;
do_OTHER_command :in std_logic;
common_command_OTHERS :in std_logic_vector(7 downto 0);
LAB4_choice : in std_logic_vector(3 downto 0);
DAC_address : in std_logic_vector(11 downto 0);
DAC_value : in std_logic_vector(11 downto 0);
general_control_value : in std_logic_vector(7 downto 0);
SPI_N_words : in std_logic_vector(7 downto 0);
REBOOT_address : in std_logic_vector(7 downto 0);
TX_do_command : out std_logic_vector(11 downto 0);
--TX_command : out std_logic_vector(7 downto 0);
TX_arg1 : out std_logic_vector(7 downto 0);
TX_arg2 : out std_logic_vector(7 downto 0);
TX_arg3 : out std_logic_vector(7 downto 0);
RX_done : in std_logic_vector(11 downto 0);
RX_NACK: in std_logic_vector(11 downto 0);
others_done : out std_logic
);
end TX_RX_manager;

architecture Behavioral of TX_RX_manager is

type state_t is (IDLE, DO_DAC_LOAD, DO_GENERAL_CONTROL, DO_FIRMWARE_ID, DO_SPI_LOAD,  DO_SPI_EXECUTE, DO_REBOOT, WAIT_FOR_ACK, WAIT_FOR_FWID, DONE);
signal state : state_t := IDLE;


signal TX_do_command_internal : std_logic_vector(15 downto 0);

begin
TX_do_command <= TX_do_command_internal(11 downto 0);
process(CLK)
begin
if rising_edge(CLK) then
	preempt_out <= '0';
	TX_do_command_internal <= (others => '0');
	case state is
		when IDLE => if do_OTHER_command = '1' and preempt = '0' then -- no information given for a preempted signal - simply discarded
							preempt_out <='1';
--							common_command_OTHERS_latched <= common_command_OTHERS;
							case common_command_OTHERS is
								when DAC_LOAD => state <= DO_DAC_LOAD;
								when GENERAL_CONTROL => state <= DO_GENERAL_CONTROL;
								when FIRMWARE_ID => state <= DO_FIRMWARE_ID;
								when SPI_LOAD => state <= DO_SPI_LOAD;
								when SPI_EXECUTE => state <= DO_SPI_EXECUTE;
								when REBOOT => state <= DO_REBOOT;
								when others => state <= IDLE; -- unrecognized commands are ignored
							end case;
						 end if;
		when DO_DAC_LOAD => TX_arg1<= DAC_address(11 downto 4);-- Mapping according to Patrick
								  TX_arg2<= DAC_address(3 downto 0) & DAC_value(11 downto 8);-- Mapping according to Patrick									
								  TX_arg3<= DAC_address(7 downto 0); -- Mapping according to Patrick
--								  TX_command<= common_command_OTHERS_latched;
								  if LAB4_choice = "1111" then
										TX_do_command_internal <= (others => '1');
								  else
										TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- note that 12 through 15 will not do anything
								  end if;
								  preempt_out <='1';
								  state <= WAIT_FOR_ACK;
		when DO_GENERAL_CONTROL => TX_arg1<= general_control_value;
--								  TX_command<= common_command_OTHERS_latched;
								  if LAB4_choice = "1111" then
										TX_do_command_internal <= (others => '1');
								  else
										TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- note that 12 through 15 will not do anything
								  end if;
								  preempt_out <='1';
								  state <= WAIT_FOR_ACK;
		when DO_FIRMWARE_ID => 
--								  TX_command<= common_command_OTHERS_latched;
								  TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- broadcast makes no sense here - write only one FWID
								  preempt_out <='1';
								  state <= WAIT_FOR_FWID;
		when DO_SPI_LOAD => TX_arg1<= SPI_N_words;
--								  TX_command<= common_command_OTHERS_latched;
								  if LAB4_choice = "1111" then
										TX_do_command_internal <= (others => '1');
								  else
										TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- note that 12 through 15 will not do anything
								  end if;
								  preempt_out <='1';
								  state <= WAIT_FOR_ACK;
		when DO_SPI_EXECUTE => TX_arg1<= SPI_N_words;
--								  TX_command<= common_command_OTHERS_latched;
								  if LAB4_choice = "1111" then
										TX_do_command_internal <= (others => '1');
								  else
										TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- note that 12 through 15 will not do anything
								  end if;
								  preempt_out <='1';
								  state <= WAIT_FOR_ACK;
		when DO_REBOOT => TX_arg1<= REBOOT_address;
--								  TX_command<= common_command_OTHERS_latched;
								  if LAB4_choice = "1111" then
										TX_do_command_internal <= (others => '1');
								  else
										TX_do_command_internal(conv_integer(LAB4_choice)) <= '1'; -- note that 12 through 15 will not do anything
								  end if;
								  preempt_out <='1';
								  state <= WAIT_FOR_ACK;
		when WAIT_FOR_ACK => if LAB4_choice = "1111" then
										if RX_done(0) = '1' then -- if broadcast, check only the first
											state <= IDLE;
											others_done <= '1';
										elsif RX_NACK(0) = '1' then
											state <= IDLE;
										end if;
									else
										if RX_done(conv_integer(LAB4_choice)) = '1' then
											state <= IDLE;
											others_done <= '1';
										elsif RX_NACK(conv_integer(LAB4_choice)) = '1' then
											state <= IDLE;
										end if;
									end if;
									others_done <= '1';
								   preempt_out <='1';
		when WAIT_FOR_FWID => if RX_done(conv_integer(LAB4_choice)) = '1' then --no different from WAIT_FOR_ACK as the FWID is exported
										state <= IDLE;
										others_done <= '1';
									elsif RX_NACK(conv_integer(LAB4_choice)) = '1' then
										state <= IDLE;
									end if;
								   preempt_out <='1';
		when OTHERS => state <= IDLE;
	end case;
end if;
end process;

end Behavioral;

