----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:45:36 03/07/2014 
-- Design Name: 
-- Module Name:    TX_command - Behavioral 
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
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TX_command_RX_data is
port(
CLK : in std_logic;
do_command : in std_logic;
command : in std_logic_vector(7 downto 0);
arg1 :in std_logic_vector(7 downto 0);
arg2 :in std_logic_vector(7 downto 0);
arg3 :in std_logic_vector(7 downto 0);
load_mem_data :in std_logic_vector(7 downto 0);
load_mem_addr :out std_logic_vector(7 downto 0);
save_mem_data_ready :out std_logic;
save_mem_data :out std_logic_vector(11 downto 0);
save_mem_addr :out std_logic_vector(6 downto 0);
save_SPI_data :out std_logic_vector(11 downto 0);
save_SPI_data_ready :out std_logic;
FW_ID : out std_logic_vector(11 downto 0);
FW_ID_ready :out std_logic;
TX :out std_logic;
RX :in std_logic;
done :out std_logic;
NACK :out std_logic
);
end TX_command_RX_data;

architecture Behavioral of TX_command_RX_data is
constant SOF_byte : std_logic_vector(7 downto 0) := x"FA";
constant EOF_byte : std_logic_vector(7 downto 0) := x"CE";
constant ACK_TEMPLATE : std_logic_vector(11 downto 0) := x"533";
constant ACK_TEMPLATE2 : std_logic_vector(11 downto 0) := x"355";
constant NUM_SAMPLES_minus1 : std_logic_vector(11 downto 0) := x"07F"; -- 128 samples or 1 "window"


type state_t is (IDLE, SEND_SOF, SEND_COMMAND, SEND_ARG1, SEND_ARG2, SEND_ARG3, SEND_MEM, SEND_EOF, WAIT_FOR_ACK, PARSE_ACK, RECEIVE_DATA, PARSE_END_ACK,
		RECEIVE_SPI_NWORDS, RECEIVE_ID, RECEIVE_SPI);
signal state : state_t;

signal command_type : std_logic_vector(7 downto 0);
signal argnum : std_logic_vector(7 downto 0);
signal counter : std_logic_vector(7 downto 0); -- needs to count up to 20 at least.
signal memval : std_logic_vector(7 downto 0);
signal load_mem_addr_int : std_logic_vector(7 downto 0);
signal save_mem_addr_int : std_logic_vector(6 downto 0) := (others => '0');


signal wait_for_ack_counter : std_logic_vector(15 downto 0) := (others =>'0'); -- Will it be enough?
constant  MAX_WAIT : std_logic_vector(15 downto 0) := x"FFFF"; -- Will it be enough?
signal ack_word : std_logic_vector(23 downto 0);
signal current_data : std_logic_vector(11 downto 0);
signal NUM_SPI : std_logic_vector(11 downto 0);
signal FW_ID_int : std_logic_vector(11 downto 0);

signal arg1_int : std_logic_vector(7 downto 0);
signal arg2_int : std_logic_vector(7 downto 0);
signal arg3_int : std_logic_vector(7 downto 0);


begin

load_mem_addr <= load_mem_addr_int;
save_mem_addr <= save_mem_addr_int - 1; --to realign
FW_ID <= FW_ID_int;

process(CLK)
begin
if rising_edge(CLK) then
	NACK <='0';
	done <='0';	
	save_mem_data_ready <= '0';
	save_SPI_data_ready <= '0';
	FW_ID_ready <= '0';
	TX <= '0';
case state is
when IDLE => if do_command = '1' then 
						command_type <= command;
						arg1_int <= arg1;
						arg2_int <= arg2;
						arg3_int <= arg3;
						ack_word <=  "0000" & command & ACK_TEMPLATE; -- simplified ack - supposes only one command outstanding
						case command is
							when x"01" => argnum<= x"01";
							when x"02" => argnum<= x"03";
							when x"04" => argnum<= x"01";
							when x"08" => argnum<= x"00";
							when x"10" => argnum<= x"00";
							when x"20" => if arg1>0 then argnum<= x"02"; else argnum <= x"01"; end if;-- at least 1 argument to be considered, even if 0 samples
							when x"40" => argnum<= x"01";
							when x"80" => argnum<= x"01";
							when others => argnum<= x"00";
						end case;
						state <= SEND_SOF;
						counter<=(others => '0');
				 end if;
when SEND_SOF => if counter < 7 then
						counter <= counter +1;
					  else 
						state <= SEND_COMMAND;	
						counter<=(others => '0');
					  end if;
						TX <=SOF_byte(CONV_INTEGER(counter)); --this would be little endian....
when SEND_COMMAND => 
					  if counter = 6 and command = x"20" then 
						load_mem_addr_int <= (others => '0'); -- address needs to be updated at least 1 cycle before reading 
					  end if;
					  if counter < 7 then
						counter <= counter +1;
					  else 
						if (argnum = 0) then
						state <= SEND_EOF;	
						else 
						state <= SEND_ARG1;		
						memval <= load_mem_data;
						end if;
						counter<=(others => '0');
					  end if;
					  	load_mem_addr_int <= (others => '0'); -- to make sure the next stage starts with a clean addressing.
						TX <=command_type(CONV_INTEGER(counter)); --this would be little endian....
when SEND_ARG1 => if counter < 7 then
								counter <= counter +1;
						else
							if (argnum < 2) then
								state <= SEND_EOF;	
							elsif command_type=x"20" then
								state <= SEND_MEM;	
								memval <= load_mem_data;
							else
								state <= SEND_ARG2;								
							end if;
							counter<=(others => '0');
						end if;
						TX <=arg1_int(CONV_INTEGER(counter)); --this would be little endian....
when SEND_ARG2 => if counter < 7 then
								counter <= counter +1;
						else
							if (argnum < 3) then
								state <= SEND_EOF;	
							else
								state <= SEND_ARG3;
							end if;
							counter<=(others => '0');
						end if;
							TX <=arg2_int(CONV_INTEGER(counter)); --this would be little endian....
when SEND_ARG3 => if counter < 7 then
								counter <= counter +1;
						else
							state <= SEND_EOF;			
							counter<=(others => '0');
						end if;
						TX <=arg3_int(CONV_INTEGER(counter)); --this would be little endian....
when SEND_MEM => 	if counter = 6 then
							load_mem_addr_int <= load_mem_addr_int + 1;
						end if;
						if counter < 7 then
							counter <= counter +1;
						elsif load_mem_addr_int < arg1 then
							memval <= load_mem_data;
							counter<=(others => '0');												
						else
							state <= SEND_EOF;		
							counter<=(others => '0');
						end if;
							TX <=memval(CONV_INTEGER(counter)); --this would be little endian....
when SEND_EOF => if counter < 7 then
						counter <= counter +1;
					  else 
						state <= WAIT_FOR_ACK;	
						counter<=(others => '0');
					  end if;
					  TX <=EOF_byte(CONV_INTEGER(counter)); --this would be little endian....
when WAIT_FOR_ACK => if RX = '1' then
								state <= PARSE_ACK;
								counter<="00000001"; -- as first  bit already received
							elsif wait_for_ack_counter < MAX_WAIT then
								wait_for_ack_counter <= wait_for_ack_counter + 1;
							else
								NACK <='1';
								state <= IDLE;	
							end if;
when PARSE_ACK => if counter < 23 then -- 12 plus command (0-padded? How?)
							counter <= counter +1;
							if RX /= ack_word(CONV_INTEGER(counter)) then
								NACK <='1';
								state <= IDLE;	
							end if;
						else
							if RX /= ack_word(CONV_INTEGER(counter)) then
								NACK <='1';
							state <= IDLE;	
							else
							  case command_type is
									when x"01" => state <= PARSE_END_ACK; 
									when x"02" => state <= PARSE_END_ACK; 
									when x"04" => state <= PARSE_END_ACK; 
									when x"08" =>  state <= RECEIVE_DATA;	
														save_mem_addr_int <= (others => '0'); 
									when x"10" => state <= RECEIVE_ID;
									when x"20" => state <= PARSE_END_ACK; 
									when x"40" => state <= RECEIVE_SPI_NWORDS;
									when x"80" => state <= PARSE_END_ACK; 
									when others => state <= PARSE_END_ACK; 
								end case;	
								counter<=(others => '0');								
							end if;
						end if;
when RECEIVE_DATA => if counter < 11 then
								counter <= counter +1;
								current_data <= RX & current_data(11 downto 1);
								if save_mem_addr_int > 0 and counter = x"00" then 
									save_mem_data <= current_data; 
									save_mem_data_ready <= '1';
								end if;
								if counter = x"01" then 
									save_mem_addr_int <= save_mem_addr_int + 1; -- so it gets incremented after it gets sampled
								end if;
--							elsif save_mem_addr_int < NUM_SAMPLES_minus1 + 1 then
							elsif save_mem_addr_int > "0000000" then -- done entire list - wraparound
								current_data <= RX & current_data(11 downto 1);
								counter<=(others => '0');												
							else
								save_mem_data <= RX & current_data(11 downto 1); 
								save_mem_data_ready <= '1';
								state <= PARSE_END_ACK;		
								counter<=(others => '0');
						end if;
when PARSE_END_ACK => if counter < 11 then -- only last character
							counter <= counter +1;
							if RX /= ACK_TEMPLATE2(CONV_INTEGER(counter)) then
								NACK <='1';
								state <= IDLE;	
							end if;
						else
							if RX /= ACK_TEMPLATE2(CONV_INTEGER(counter)) then
								NACK <='1';
							state <= IDLE;	
							else
								state <= IDLE;	
								done <= '1';
							end if;
						end if;

when RECEIVE_SPI_NWORDS => if counter < 11 then
							counter <= counter +1;
							NUM_SPI <= RX & NUM_SPI(11 downto 1);												
						else
							NUM_SPI <= RX & NUM_SPI(11 downto 1);
							if RX & NUM_SPI(11 downto 1) > 0 then
								state <= RECEIVE_SPI;		
							else
								state <= PARSE_END_ACK;		
							end if;
							save_mem_addr_int <= (others => '0');
							counter<=(others => '0');
						end if;



when RECEIVE_ID => if counter < 11 then
							counter <= counter +1;
							FW_ID_int <= RX & FW_ID_int(11 downto 1);												
						else
							state <= PARSE_END_ACK;		
							FW_ID_int <= RX & FW_ID_int(11 downto 1);												
							FW_ID_ready <= '1';
							counter<=(others => '0');
						end if;

--redo everything as below to save ALL data!!
when RECEIVE_SPI => 
						if counter < 11 then
							counter <= counter +1;
							current_data <= RX & current_data(11 downto 1);
							if save_mem_addr_int > 0 and counter = x"00" then 
								save_SPI_data <= current_data; 
								save_SPI_data_ready <= '1';
							end if;
							if counter = x"01" then 
								save_mem_addr_int <= save_mem_addr_int + 1; -- so it gets incremented after it gets sampled
							end if;
						elsif save_mem_addr_int < NUM_SPI then
							current_data <= RX & current_data(11 downto 1);
							counter<=(others => '0');												
						else
							state <= PARSE_END_ACK;	
							save_SPI_data <= RX & current_data(11 downto 1);
							save_SPI_data_ready <= '1';
							counter<=(others => '0');
						end if;

when others => state <= IDLE;

end case;
end if;

end process;

end Behavioral;

