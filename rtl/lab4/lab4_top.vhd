----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:34:02 03/06/2014 
-- Design Name: 
-- Module Name:    lab4_top - Behavioral 
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
use IEEE.STD_LOGIC_unsigned.ALL;

use work.RX_TX_definitions.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab4_top is
port(
--WB bus connections
wbc_clk_i : in std_logic;
wbc_rst_i : in std_logic;			
wbc_dat_o : out std_logic_vector(31 downto 0);	
wbc_dat_i : in std_logic_vector(31 downto 0);			
wbc_adr_i : in std_logic_vector(18 downto 0);	
wbc_cyc_i : in std_logic;			
wbc_we_i : in std_logic;				
wbc_stb_i : in std_logic;			
wbc_ack_o : out std_logic;		
wbc_rty_o : out std_logic;			
wbc_err_o : out std_logic;			
wbc_sel_i: in std_logic_vector(0 downto 0);
sys_clk_i : in std_logic;
pps_i : in std_logic; 
pps_sysclk_i : in std_logic;
-- ICE40 connections.
L4_RX : in std_logic_vector(11 downto 0);
L4_TX : out std_logic_vector(11 downto 0);
L4_CLK : out std_logic_vector(11 downto 0);
-- MONTIMING inputs.
L4_TIMING : in std_logic_vector(11 downto 0);
-- WCLK outputs.
L4_WCLK : out std_logic_vector(11 downto 0);
-- Write port connections.
L4A_WR_EN : out std_logic;
L4A_WR : out std_logic_vector(4 downto 0);
L4B_WR_EN : out std_logic;
L4B_WR : out std_logic_vector(4 downto 0);
L4C_WR_EN : out std_logic;
L4C_WR : out std_logic_vector(4 downto 0);
L4D_WR_EN : out std_logic;
L4D_WR : out std_logic_vector(4 downto 0);
L4E_WR_EN : out std_logic;
L4E_WR : out std_logic_vector(4 downto 0);
L4F_WR_EN : out std_logic;
L4F_WR : out std_logic_vector(4 downto 0);
L4G_WR_EN : out std_logic;
L4G_WR : out std_logic_vector(4 downto 0);
L4H_WR_EN : out std_logic;
L4H_WR : out std_logic_vector(4 downto 0);
L4I_WR_EN : out std_logic;
L4I_WR : out std_logic_vector(4 downto 0);
L4J_WR_EN : out std_logic;
L4J_WR : out std_logic_vector(4 downto 0);
L4K_WR_EN : out std_logic;
L4K_WR : out std_logic_vector(4 downto 0);
L4L_WR_EN : out std_logic;
L4L_WR : out std_logic_vector(4 downto 0);
HOLD : in std_logic_vector(3 downto 0)
);
end lab4_top;
  
architecture Behavioral of lab4_top is

COMPONENT lab4_ram_new
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
  
component write_master_SURF  
port(
CLK : in std_logic;
load_internal_done : in std_logic;
PHAB : in std_logic_vector(11 downto 0);
HOLD : in std_logic_vector(3 downto 0);
WR_Ena : out std_logic_vector(11 downto 0);
WR_S : out std_logic_vector(4 downto 0);
start_read_0 : out std_logic_vector(2 downto 0);
start_read_1 : out std_logic_vector(2 downto 0);
start_read_2 : out std_logic_vector(2 downto 0);
start_read_3: out std_logic_vector(2 downto 0);
curr_bank : out std_logic_vector(1 downto 0);
curr_low : out std_logic_vector(2 downto 0);
choice_phase_debug : in std_logic_vector(4 downto 0)
);
end component;

component read_master_SURF 
port(
CLK : in std_logic;
--start_read
trigger : in std_logic;
-- interface with write_master
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
-- finished digitization and readout - togglable from command
read_done : out std_logic;
--PData_out  : out std_logic_vector(11 downto 0);
digitize_address : out std_logic_vector(4 downto 0) -- real block address - common to all 12 chips
--new_window_readout_start : out std_logic -- to inform histogram that a new window is started now - just for debugging
);
end component;


component TX_command_RX_data 
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
end component;


component TX_RX_manager is
port(
CLK : in std_logic;
preempt : in std_logic;
preempt_out : out std_logic;
do_other_command :in std_logic;
common_command_OTHERS :in std_logic_vector(7 downto 0);
LAB4_choice : in std_logic_vector(3 downto 0);
DAC_address : in std_logic_vector(11 downto 0);
DAC_value : in std_logic_vector(11 downto 0);
general_control_value : in std_logic_vector(7 downto 0);
SPI_N_words : in std_logic_vector(7 downto 0);
REBOOT_address : in std_logic_vector(7 downto 0);
TX_do_command : out std_logic_vector(11 downto 0);
TX_command : out std_logic_vector(7 downto 0);
TX_arg1 : out std_logic_vector(7 downto 0);
TX_arg2 : out std_logic_vector(7 downto 0);
TX_arg3 : out std_logic_vector(7 downto 0);
RX_done : in std_logic_vector(11 downto 0);
RX_NACK: in std_logic_vector(11 downto 0);
others_done : out std_logic
);
end component;


COMPONENT SPI_mem
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
end component;
 
signal logic_one: std_logic := '1';
signal en_SPI_wr: std_logic;
signal wea_SPI:  std_logic_vector(0 downto 0);

signal data_SP_wr :  std_logic_vector(7 downto 0);
signal addr_SP_wr :  std_logic_vector(7 downto 0);


signal general_control_value :  std_logic_vector(7 downto 0);


signal LAB4_choice: std_logic_vector(3 downto 0);
signal DAC_address: std_logic_vector(11 downto 0);
signal DAC_value: std_logic_vector(11 downto 0);

signal LAB4_last_choice_done: std_logic_vector(3 downto 0); --used to indicate that the defacto last command finalized contains
																				-- info about the LAB4 chip indicated (1111 if a readout is still in progress)


signal do_other_command: std_logic;


signal do_command: std_logic_vector(11 downto 0);
signal do_command_READ: std_logic_vector(11 downto 0);
signal do_command_OTHERS: std_logic_vector(11 downto 0);

type arr_12_7 is array(0 to 11) of std_logic_vector(6 downto 0);
type arr_12_12 is array(0 to 11) of std_logic_vector(11 downto 0);
signal common_command : std_logic_vector(7 downto 0);
signal common_command_READ : std_logic_vector(7 downto 0);
signal common_command_OTHERS: std_logic_vector(7 downto 0);

signal common_arg1_READ : std_logic_vector(7 downto 0);
signal common_arg1_OTHERS : std_logic_vector(7 downto 0);
signal common_arg1 : std_logic_vector(7 downto 0);


signal common_arg2 : std_logic_vector(7 downto 0);
signal common_arg3 : std_logic_vector(7 downto 0);
signal load_mem_data : std_logic_vector(7 downto 0);
signal load_mem_addr : std_logic_vector(7 downto 0);
signal save_mem_data_ready: std_logic_vector(11 downto 0);
signal save_SPI_data_ready: std_logic_vector(11 downto 0);
signal FW_ID_ready: std_logic_vector(11 downto 0);
signal done: std_logic_vector(11 downto 0);
signal NACK: std_logic_vector(11 downto 0);


signal save_mem_addr_low : arr_12_7;
signal save_mem_data : arr_12_12;
signal save_SPI_data : arr_12_12;
signal FW_ID : arr_12_12;



type memdout_t is array(0 to 11) of std_logic_vector(31 downto 0);
signal memdout : memdout_t;

signal sample : std_logic_vector(11 downto 0);
signal memdin : std_logic_vector(15 downto 0);


signal memwradrr : std_logic_vector(15 downto 0);
signal memrdadrr : std_logic_vector(15 downto 0);
signal labwr_adr : std_logic_vector(15 downto 0);

signal wren : std_logic_vector(11 downto 0);
 

signal sel_mem_bank : std_logic;
signal digitize_load : std_logic;
signal digitize_load_sys : std_logic;
signal start_pulse_digitize : std_logic;

signal load_internal_done : std_logic := '0';
signal L4_WR_EN_all : std_logic_vector(11 downto 0);
signal WR_S : std_logic_vector(4 downto 0);
signal start_read_0 : std_logic_vector(2 downto 0);
signal start_read_1 : std_logic_vector(2 downto 0);
signal start_read_2 : std_logic_vector(2 downto 0);
signal start_read_3 : std_logic_vector(2 downto 0);
signal curr_bank : std_logic_vector(1 downto 0);
signal curr_low : std_logic_vector(2 downto 0);
signal choice_phase_debug : std_logic_vector(4 downto 0) := (others =>'0');
signal wbc_int_addr : std_logic_vector(16 downto 0);

signal read_done : std_logic;
signal others_done : std_logic;

signal digitize_address :  std_logic_vector(4 downto 0); -- actual block address, common for all chips
signal new_window_readout_start :  std_logic; -- to inform histogram that a new window is started now - just for debugging

signal low_bank_A : std_logic_vector(2 downto 0);
signal low_bank_B : std_logic_vector(2 downto 0);
signal low_bank_C : std_logic_vector(2 downto 0);
signal low_bank_D : std_logic_vector(2 downto 0);
signal common_write_address : std_logic_vector(11 downto 0); -- common address for all LAB4Bs - duplicated in the memories
signal addra : std_logic_vector(12 downto 0); -- common address for all LAB4Bs - duplicated in the memories extra bit to spaecify bank


signal data_bank : std_logic_vector(0 downto 0);
signal desired_bank : std_logic_vector(1 downto 0);

signal wbc_dat_o_c :  std_logic_vector(31 downto 0);	

signal wbc_command_delayed :  std_logic; 
signal digitize_load_old :  std_logic; 
signal digitize_load_level :  std_logic; 
signal read_done_latch :  std_logic; 
signal enb :  std_logic; 

type wren_a_t is array(0 to 11) of std_logic_vector(0 downto 0);
signal wren_a :  wren_a_t;

type dina_t is array(0 to 11) of std_logic_vector(15 downto 0);
signal dina :  dina_t;


signal SPI_N_words : std_logic_vector(7 downto 0);
signal REBOOT_address : std_logic_vector(7 downto 0);
signal FIRMWARE_ID_value : std_logic_vector(7 downto 0);

signal readout_in_process : std_logic := '0';-- read-related TX/RX (WILKINSON and READOUT)
signal others_in_process : std_logic := '0'; -- general controls, SPI, reboot. 


														

begin

 wbc_int_addr <= wbc_adr_i(18 downto 2);

process(wbc_clk_i)
begin
if(rising_edge(wbc_clk_i)) then
	digitize_load <='0';
	digitize_load_old <= digitize_load_level;
	digitize_load_level<='0';
	if digitize_load_level = '1' and digitize_load_old = '0' then digitize_load<='1'; end if; -- uses edge - not necessary as it is already a pulse
	if read_done = '1' then read_done_latch<= '1'; end if; 
	if((wbc_cyc_i and wbc_stb_i and wbc_we_i) = '1') then
		if(wbc_int_addr(16 downto 15)="10") then -- MSbs choose between data memory and commands
			case wbc_int_addr(3 downto 0) is -- still discards the 2 LSbs?
				when "0000" => digitize_load_level<='1'; --  command - digitize and load - might decide to store in different locations later
									desired_bank <= wbc_dat_i(1 downto 0); -- which bank you want - internally it checks whether it is currently written into and refuses
				when "0001" => load_internal_done<=wbc_dat_i(0); --  command - should be used to indicate that internal and external DACs as well
																		-- as input clocks to the LAB chips are set correctly, and it is possible 
																		-- to synchronize the LAB chip phases together.
				when "0010" =>	choice_phase_debug<=wbc_dat_i(4 downto 0); -- command - adjust the phase of WRADDR with respect to PHAB - needs to be issued
																							 -- BEFORE the load_internal_done is set
				when "0011" =>	data_bank<=wbc_dat_i(0 downto 0); -- command - select the data bank to use (there are 2 now) -- in the future this might be automatic
--				when "0100" =>	-- this command is actually covered by readout that is self-resetting
				when "1000" => common_command_OTHERS<= REBOOT; --reboot - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- if "1111" it will broadcast the write
									REBOOT_address<=wbc_dat_i(7 downto 0); -- only LSbs used?
								   do_OTHER_command<='1'; 
				when "1001" => common_command_OTHERS<= DAC_LOAD; --DAC_LOAD - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- if "1111" it will broadcast the write
									DAC_address<=wbc_dat_i(11 downto 0); -- DAC address in the LSBs
									DAC_value<=wbc_dat_i(31 downto 20); -- DAC value in  the MSbs
									do_OTHER_command<='1'; 
				when "1010" => common_command_OTHERS<= GENERAL_CONTROL; --GENERAL_CONTROL - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- if "1111" it will broadcast the write
								   general_control_value<=wbc_dat_i(7 downto 0); 
									do_OTHER_command<='1';
				when "1011" => common_command_OTHERS<= FIRMWARE_ID; --FIRMWARE_ID - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- in this case broadcast makes no sense
									do_OTHER_command<='1'; -- requires a write AND a read on the same address 
				when "1100" => common_command_OTHERS<= SPI_LOAD; --SPI_LOAD - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- if "1111" it will broadcast the write
									SPI_N_words <=  wbc_dat_i(7 downto 0);  -- used as first agument for SPI load (# bytes)
									-- needs to connect!!!
									do_OTHER_command<='1'; -- the "write space" with "11" as MSbs is used to hold 256 bytes for this command -- needs to be initialized before issueing this
				when "1100" => common_command_OTHERS<= SPI_EXECUTE; --SPI_EXECUTE - works only if no read is in session - make sure triggering is preempted
								   LAB4_choice<=wbc_dat_i(15 downto 12); -- if "1111" it will broadcast the write
									SPI_N_words <=  wbc_dat_i(7 downto 0);  -- used as first argument for SPI execute (# bytes to read)
									do_OTHER_command<='1'; -- note: now the "verify" info about the programming done is not used											
				when others => NULL;
			end case;
				if(wbc_int_addr(16 downto 15)="11") then -- MSbs choose SPI image memory
					addr_SP_wr<=wbc_int_addr(7 downto 0); -- only 7 bits - 256 SPI bytes at a time
					data_SP_wr<=wbc_dat_i(7 downto 0); 
				end if;
			end if;
	elsif((wbc_cyc_i and wbc_stb_i and not wbc_we_i) = '1') then
		if(wbc_int_addr(16)='1') then -- MSb chooses between data memory and commands
			case wbc_int_addr(3 downto 0) is -- still discards the 2 LSbs?
				when "0000" => wbc_dat_o_c <= x"0000000" & "00" & desired_bank; -- which bank was most recently requested
				when "0001" => wbc_dat_o_c<= (0=> load_internal_done, others => '0'); --  command - should be used to indicate that internal and external DACs as well
																		-- as input clocks to the LAB chips are set correctly, and it is possible 
																		-- to synchronize the LAB chip phases together.
				when "0010" =>	wbc_dat_o_c <= x"000000" & "000" & choice_phase_debug; -- command - adjust the phase of WRADDR with respect to PHAB - needs to be issued
																							 -- BEFORE the load_internal_done is set
				when "0011" =>	wbc_dat_o_c <= x"0000000" & "000" & data_bank; -- command - select the data bank to use (there are 2 now) -- in the future this might be automatic
				when "0100" =>	wbc_dat_o_c<= (0=> read_done_latch, others => '0'); read_done_latch <= '0'; -- read and resets the read_done latch that indicates last readout is finished	
				when "1011" => wbc_dat_o_c<= LAB4_last_choice_done & FIRMWARE_ID_value; --FIRMWARE_ID value: corresponds to the last read - if not finished reading, it will have "1111"
				when others => NULL;
			end case;		
		end if;
	end if;
	wbc_command_delayed <= wbc_int_addr(16);
end if;
end process;


process(wbc_clk_i)
begin
if(rising_edge(wbc_clk_i)) then
	wbc_ack_o <= wbc_cyc_i and wbc_stb_i;
end if;
end process;

-- for 32 bit words
--wren(0) <= (wbc_cyc_i and wbc_stb_i and wbc_we_i) and not labwr_adr(0);
--wren(1) <= (wbc_cyc_i and wbc_stb_i and wbc_we_i) and not labwr_adr(0);
--wren(2) <= (wbc_cyc_i and wbc_stb_i and wbc_we_i) and labwr_adr(0);
--wren(3) <= (wbc_cyc_i and wbc_stb_i and wbc_we_i) and labwr_adr(0);

-- for 16 bit words
--wren(0) <= (wbc_cyc_i and wbc_stb_i and wbc_we_i);
--memdin <= sample;

---- for 32 bit words
--with labwr_adr(0) select
--memdin <= X"0000" & X"0000" & sample when  '0',
--			sample & X"0000" & X"0000" when  '1';
--sel_mem_bank <= '0';
--memwradrr <= sel_mem_bank & labwr_adr(15 downto 1);
--memrdadrr <= sel_mem_bank & wbc_adr_i(15 downto 1); -- now only 65536 samples read - sel_mem_bank set to 0;

-- for 16 bit words
--memwradrr <= labwr_adr;
--memrdadrr <= wbc_adr_i;


--memdin <= "0000" & sample;
wren <= save_mem_data_ready; -- from TX_RX controller
process(wren, save_mem_data)
begin
for i in 0 to 11 loop
wren_a(i)<= (0 => wren(i));
dina(i) <= "0000" & save_mem_data(i);
end loop;
end process;

addra<= data_bank & common_write_address;
enb <= wbc_cyc_i and wbc_stb_i and not wbc_adr_i(18);
gen_lab_data_mem: for i in 0 to 11 generate
inst_lab_data_mem: lab4_ram_new port map(
  clka => sys_clk_i, -- port A is the WRITE port clocked with the system - 100MHz - clock
--  wea=> wren(i), 
  wea=> wren_a(i), 
  addra => addra, -- input [12 : 0] addra
  dina => dina(i), -- input [15 : 0] dina
  clkb => wbc_clk_i, -- input clkb
  enb => enb,
  addrb=>wbc_adr_i(13 downto 2), -- The actual address has 4 more bits - for the selection of the asic
  doutb=>  memdout(i) -- output [31 : 0] doutb
);
end generate;

--  for 32 bit words
with wbc_command_delayed select -- delayed as the output of command readout is synchronously updated at the same time wbc_adr_i(18) becomes 1. 
										  -- also  for memory readout the address is updated at least one clock cycle before by f the synch update of wbc_ack_o 
wbc_dat_o <= memdout(conv_integer(wbc_adr_i(17 downto 14))) when '0', --top 4 bits to select the asic
				 wbc_dat_o_c when others;
				 
-- for 16 bit words
--wbc_dat_o <= memdout(15 downto 0);
				
--SPI memory - dual ported distributed

en_SPI_wr <= wbc_cyc_i and wbc_stb_i and wbc_adr_i(18) and wbc_adr_i(17);

wea_SPI <= (0 => en_SPI_wr);
SPI_mem_u : SPI_mem
  PORT MAP (
    clka => wbc_clk_i, -- write from wbc
    wea => wea_SPI,
    addra => addr_SP_wr,
    dina => data_SP_wr,
    clkb => sys_clk_i,  -- read from sys
    addrb => load_mem_addr,
    doutb => load_mem_data
  );
 
L4A_WR_EN <= L4_WR_EN_all(0);
L4B_WR_EN <= L4_WR_EN_all(1);
L4C_WR_EN <= L4_WR_EN_all(2);
L4D_WR_EN <= L4_WR_EN_all(3);

L4E_WR_EN <= L4_WR_EN_all(4);
L4F_WR_EN <= L4_WR_EN_all(5);
L4G_WR_EN <= L4_WR_EN_all(6);
L4H_WR_EN <= L4_WR_EN_all(7);

L4I_WR_EN <= L4_WR_EN_all(8);
L4J_WR_EN <= L4_WR_EN_all(9);
L4K_WR_EN <= L4_WR_EN_all(10);
L4L_WR_EN <= L4_WR_EN_all(11);
 
L4A_WR <= WR_S;
L4B_WR <= WR_S;
L4C_WR <= WR_S;
L4D_WR <= WR_S;
L4E_WR <= WR_S;
L4F_WR <= WR_S;
L4G_WR <= WR_S;
L4H_WR <= WR_S;
L4I_WR <= WR_S;
L4J_WR <= WR_S;
L4K_WR <= WR_S;
L4L_WR <= WR_S;

write_master_SURF_u : write_master_SURF
port map(
CLK => sys_clk_i,
load_internal_done => load_internal_done, 
PHAB => L4_TIMING,
HOLD => HOLD,
WR_Ena => L4_WR_EN_all,
WR_S => WR_S,
start_read_0 => start_read_0,
start_read_1 => start_read_1,
start_read_2 => start_read_2,
start_read_3 => start_read_3,
curr_bank => curr_bank,
curr_low => curr_low,
choice_phase_debug => choice_phase_debug
);

-- domain crossing for digitize load - simple self-resetting flop
process(digitize_load, digitize_load_sys)
begin
if(digitize_load_sys = '1') then
	start_pulse_digitize<='0';
elsif rising_edge(digitize_load) then 
	start_pulse_digitize<='1';
end if;
end process;


process(digitize_load, sys_clk_i)
begin
if rising_edge(sys_clk_i) then 
	digitize_load_sys<= start_pulse_digitize;
end if;
end process;

-- note: need to add the information on where the write has switched banks, as that is the last - either it is exported and read with the data, or
-- used to write in the memory sequentially low_bank_X
read_master_SURF_u : read_master_SURF 
port map(
CLK => sys_clk_i,
--start_read
trigger => digitize_load_sys, -- careful with domain - used in the fast domain, but comes from wbc clock domain... safer to add domain crossing and acks
-- interface with write_master
--curr_low => curr_low, --superseded by 5 signals below
--curr_bank => curr_bank,
low_bank_A => start_read_0, -- need to try to see if this indicates the last or the first written and modify the mapping of digitize_address as a consequence 
low_bank_B => start_read_1,
low_bank_C => start_read_2,
low_bank_D => start_read_3,

held_banks => HOLD, -- need to know which banks to digitize
desired_bank => desired_bank,
-- controls to/from TX_command_RX_data
TX_do_command => do_command_READ,
TX_command => common_command_READ, --now only read_master issues commands - need to be preempt other blocks to do so (e.g. PCI trying to set DACs, for example).
										-- for safety these should be done while vetoing the trigger?
TX_arg1 => common_arg1_READ,
RX_done => done, --when this is issued, either the digitization or the data transfer is over - data writing in local mem is controlled by the TX_command_RX_data
RX_NACK => NACK,
read_done => read_done, -- used to indicate that new data is available - should be used to set a parameter in control space for PCI/TURF to poll
digitize_address => digitize_address -- now used to indicate the block of memory (higher bits - total memory = 4096 samples = 12 bits - single block = 128 -> 7 bits ->
												--  needs 5 bits here composed of bank position, plus sequence mapped  with low_bank_A+1 <-> 0, low_bank_A <-> 7)
--new_window_readout_start => new_window_readout_start -- to inform histogram that a new window is started now - just for debugging
);

common_write_address<= digitize_address & save_mem_addr_low(0); -- all the addresses are identical, so use only one of them

TX_RX_gen : for i in 0 to 11 generate
TX_command_RX_data_u:	TX_command_RX_data 
port map(
CLK => sys_clk_i,
do_command => do_command(i), --memory gets duplicated x12, so each readout can proceed in parallel
command => common_command, -- command is always common though - we expect to issue the same command for all chips, or individually choose one chip (for FW programmiong, for example)
arg1 => common_arg1,
arg2 => common_arg2,
arg3 => common_arg3,
load_mem_data => load_mem_data, -- as FW programming is done separately, use a single memory to write the data.
load_mem_addr => load_mem_addr,
save_mem_data_ready => save_mem_data_ready(i), -- used as wren for the individual memories - block position is indicated by 
save_mem_data => save_mem_data(i),  -- all individual memories
save_mem_addr => save_mem_addr_low(i), -- all individual memories  - sample position in block
save_SPI_data => save_SPI_data(i), -- needs to decide where this goes: probably one location only, and this is multiplexed, as we are writing one FW at a time.
save_SPI_data_ready => save_SPI_data_ready(i), --same as above - only one active all the time.
FW_ID => FW_ID(i), --same as above - only one active all the time. 
FW_ID_ready => FW_ID_ready(i), --same as above - only one active all the time.
TX => L4_TX(i),
RX => L4_RX(i),
done => done(i), -- either observe only one, or all of them - if a NACK occurs, retransmit? Possibly add a reset signal to each TX_RX to guarantee "good" start.
NACK => NACK(i)
);
end generate;

process(sys_clk_i)
begin
	if rising_edge(sys_clk_i) then
		if FW_ID_ready(conv_integer(LAB4_choice)) = '1' then
			FIRMWARE_ID_value<=FW_ID(conv_integer(LAB4_choice));
			LAB4_last_choice_done <= LAB4_choice;
		end if;
	end if;
end process;

process(others_in_process, do_command_READ, common_command_READ, do_command_OTHERS, common_command_OTHERS)
begin
if others_in_process = '1' then 
		do_command<=do_command_OTHERS;
		common_command<=common_command_OTHERS;
		common_arg1 <= common_arg1_OTHERS;
else -- default - reads
		do_command<=do_command_READ;
		common_command<=common_command_READ;
		common_arg1 <= common_arg1_READ;
end if;		
end process;


TX_RX_manager_u : TX_RX_manager
port map
(CLK => sys_clk_i,
preempt => readout_in_process,
preempt_out => others_in_process,
do_OTHER_command => do_OTHER_command,
common_command_OTHERS => common_command_OTHERS,
LAB4_choice => LAB4_choice,
DAC_address => DAC_address,
DAC_value => DAC_value,
general_control_value => general_control_value,
SPI_N_words => SPI_N_words,
REBOOT_address => REBOOT_address,
TX_do_command => do_command_OTHERS,
--TX_command : out std_logic_vector(7 downto 0);
TX_arg1 => common_arg1_OTHERS,
TX_arg2 => common_arg2,
TX_arg3 => common_arg3,
RX_done => done,
RX_NACK => NACK,
others_done => others_done
);

end Behavioral;

