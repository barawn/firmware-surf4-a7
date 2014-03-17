----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:38:08 02/12/2013 
-- Design Name: 
-- Module Name:    write_master - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: The module writes in 4 different banks, and switches bank immediately 
--						as a new read is issued (should be trigger?). The transition window
--						might get corrupted - on both banks. Future versions will take care
--						of this.
--						When all 4 windows are "read" (or triggered on) writing ceases, te resume as soon as at
--						least one read is over.
--						Exact synchronization with PHAB requires tuning of extra delays, 
--						and should be done with the HW
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity write_master_SURF is
port(
CLK : in std_logic;
load_internal_done : in std_logic; -- this is meant to be used as a start for the write - controlled through the PCI bus
													-- allows the system to take data only after an internal synchronization that will
													-- have to follow the setting of internal dac registers.
PHAB : in std_logic_vector(11 downto 0);
HOLD : in std_logic_vector(3 downto 0);
WR_Ena : out std_logic_vector(11 downto 0) := (others => '0');
WR_S : out std_logic_vector(4 downto 0);
start_read_0 : out std_logic_vector(2 downto 0);
start_read_1 : out std_logic_vector(2 downto 0);
start_read_2 : out std_logic_vector(2 downto 0);
start_read_3: out std_logic_vector(2 downto 0);
curr_bank : out std_logic_vector(1 downto 0);
curr_low : out std_logic_vector(2 downto 0);
choice_phase_debug : in std_logic_vector(4 downto 0)
);
end write_master_SURF;

architecture Behavioral of write_master_SURF is
signal initialize_done : std_logic := '0'; -- used only at the beginning, to make sure 
signal synchronized : std_logic := '0';    -- the timing registers are been set, 		
														 -- and PHAB indicates the correct phase
														 -- Requires that the first updating has PHAB!!!
signal PHAB_register : std_logic_vector(1 downto 0) := "00";
signal used_banks : std_logic_vector(2 downto 0) := "000";
signal WR_S_high : std_logic_vector(1 downto 0) := "00"; -- bank number - starts writing at 0 and increment any time a read
																		  -- occurs
signal WR_S_low : std_logic_vector(2 downto 0) := "000"; -- extended so the last bit follows the internal writing
--type  start_read_array_t is array (0 to 3) of std_logic_vector(2 downto 0); 
--signal start_read_array : start_read_array_t := (others => "000"); 

signal counter : std_logic_vector(3 downto 0) := "0010"; -- "divide"  to adapt the write to the clock
signal read_start_prolonged : std_logic := '0';

signal WR_S1 : std_logic_vector(4 downto 0);
signal WR_S2 : std_logic_vector(4 downto 0);
signal WR_S3 : std_logic_vector(4 downto 0);
signal WR_S4 : std_logic_vector(4 downto 0);
signal WR_S5 : std_logic_vector(4 downto 0);
signal WR_S6 : std_logic_vector(4 downto 0);
signal WR_S7 : std_logic_vector(4 downto 0);
signal WR_S8 : std_logic_vector(4 downto 0);
signal WR_S9 : std_logic_vector(4 downto 0);
signal WR_S10 : std_logic_vector(4 downto 0);
signal WR_S11 : std_logic_vector(4 downto 0);
signal WR_S12 : std_logic_vector(4 downto 0);
signal WR_S13 : std_logic_vector(4 downto 0);
signal WR_S14 : std_logic_vector(4 downto 0);
signal WR_S15 : std_logic_vector(4 downto 0);
signal WR_S16 : std_logic_vector(4 downto 0);
signal WR_S17 : std_logic_vector(4 downto 0);
signal WR_S18 : std_logic_vector(4 downto 0);
signal WR_S19 : std_logic_vector(4 downto 0);
signal WR_S20 : std_logic_vector(4 downto 0);



signal WR_S1_f : std_logic_vector(4 downto 0);
signal WR_S2_f : std_logic_vector(4 downto 0);
signal WR_S3_f : std_logic_vector(4 downto 0);
signal WR_S4_f : std_logic_vector(4 downto 0);
signal WR_S5_f : std_logic_vector(4 downto 0);
signal WR_S6_f : std_logic_vector(4 downto 0);
signal WR_S7_f : std_logic_vector(4 downto 0);
signal WR_S8_f : std_logic_vector(4 downto 0);
signal WR_S9_f : std_logic_vector(4 downto 0);
signal WR_S10_f : std_logic_vector(4 downto 0);
signal WR_S11_f : std_logic_vector(4 downto 0);
signal WR_S12_f : std_logic_vector(4 downto 0);
signal WR_S13_f : std_logic_vector(4 downto 0);
signal WR_S14_f : std_logic_vector(4 downto 0);
signal WR_S15_f : std_logic_vector(4 downto 0);
signal WR_S16_f : std_logic_vector(4 downto 0);
signal WR_S17_f : std_logic_vector(4 downto 0);
signal WR_S18_f : std_logic_vector(4 downto 0);
signal WR_S19_f : std_logic_vector(4 downto 0);
signal WR_S20_f : std_logic_vector(4 downto 0);

begin

process(CLK)
begin
if rising_edge(CLK) then
	PHAB_register(0)<= PHAB(0); -- using only the first PHAB to get synch  writes
	PHAB_register(1)<= PHAB_register(0);
end if;

end process;

process(CLK)
begin
if rising_edge(CLK) then 
	if load_internal_done = '1' then initialize_done <='1'; end if;
end if;
end process;


process(CLK)
begin
if rising_edge(CLK) then
--	WR_Ena <= (others => '0');
	if initialize_done = '1' and synchronized = '0' then  -- look only at LAB4A for synch - all should be in lockstep
		if PHAB_register = "01" then -- check which guarantees correct alignment
			synchronized <= '1';
		end if;
	elsif synchronized = '1'  then
--		if counter = 9 then -- this for 2.56Gsa/s
--		if counter = 5 then -- this for 4.266Gsa/s
		if counter = 7 then -- this for 3.2Gsa/s
			if HOLD ="1111" then WR_Ena <=(others => '0'); else WR_Ena <=(others => '1'); end if; -- so the WRADDR keeps being synchronized
			WR_S_low <= WR_S_low + 1;
			counter <= (others => '0');
		else
			counter <= counter +1;
		end if;
	end if;
end if;
end process;




--process(CLK)
--begin
--if rising_edge(CLK) then
--	if read_start= '1' then
--		read_start_prolonged <='1';
----	elsif counter = 9 then -- this for 2.56Gsa/s
----	elsif counter = 5 then -- this for 4.266Gsa/s
--	elsif counter = 7 then -- this for 3.2Gsa/s
--		read_start_prolonged <='0';
--	end if;
--end if;
--end process;
	
--process(CLK)
--begin
--if rising_edge(CLK) then
----	if read_start_prolonged = '1' and counter = 9 then -- this for 2.56Gsa/s
----	if read_start_prolonged = '1' and counter = 5 then -- this for 4.266Gsa/s
--	if read_start_prolonged = '1' and counter = 7 then -- this for 3.2Gsa/s
--		used_banks <= used_banks + 1;
--		WR_S_high <= WR_S_high +1;
--		start_read_array(conv_integer(WR_S_high +1)) <= WR_S_low;
--	elsif read_done = '1' then
--		used_banks <= used_banks - 1;
--	end if;
--end if;

--end process;
process(CLK)
begin
if rising_edge(CLK) then
	case WR_S_high is
	when "00" => if HOLD(0) = '1' then 
							start_read_0<=WR_S_low;
							if HOLD(1) = '0' then
								WR_S_high<= "01";
							elsif HOLD(2) = '0' then
								WR_S_high<= "10";
							elsif HOLD(3) = '0' then
								WR_S_high<= "11";
							end if; -- if HOLD = "1111" WREN should be 0
					 end if;
	when "01" => if HOLD(1) = '1' then 
							start_read_1<=WR_S_low;
							if HOLD(2) = '0' then
								WR_S_high<= "10";
							elsif HOLD(3) = '0' then
								WR_S_high<= "11";
							elsif HOLD(0) = '0' then
								WR_S_high<= "00";
							end if; -- if HOLD = "1111" WREN should be 0
					 end if;
	when "10" => if HOLD(2) = '1' then 
							start_read_2<=WR_S_low;
							if HOLD(3) = '0' then
								WR_S_high<= "11";
							elsif HOLD(0) = '0' then
								WR_S_high<= "00";
							elsif HOLD(1) = '0' then
								WR_S_high<= "01";
							end if; -- if HOLD = "1111" WREN should be 0
					 end if;
	when "11" => if HOLD(3) = '1' then 
							start_read_3<=WR_S_low;
							if HOLD(0) = '0' then
								WR_S_high<= "00";
							elsif HOLD(1) = '0' then
								WR_S_high<= "01";
							elsif HOLD(2) = '0' then
								WR_S_high<= "10";
							end if; -- if HOLD = "1111" WREN should be 0
					 end if;
	when others => WR_S_high <= "00";		
	end case;
end if;
end process;

WR_S1<=WR_S_high & WR_S_low;

process(CLK)
begin
if rising_edge(CLK) then
WR_S2<=WR_S1;
WR_S3<=WR_S2;
WR_S4<=WR_S3;
WR_S5<=WR_S4;
WR_S6<=WR_S5;
WR_S7<=WR_S6;
WR_S8<=WR_S7;
WR_S9<=WR_S8;
WR_S10<=WR_S9;
WR_S11<=WR_S10;
WR_S12<=WR_S11;
WR_S13<=WR_S12;
WR_S14<=WR_S13;
WR_S15<=WR_S14;
WR_S16<=WR_S15;
WR_S17<=WR_S16;
WR_S18<=WR_S17;
WR_S19<=WR_S18;
WR_S20<=WR_S19;
end if;
end process;

process(CLK)
begin
if falling_edge(CLK) then
WR_S2_f<=WR_S1;
WR_S3_f<=WR_S2;
WR_S4_f<=WR_S3;
WR_S5_f<=WR_S4;
WR_S6_f<=WR_S5;
WR_S7_f<=WR_S6;
WR_S8_f<=WR_S7;
WR_S9_f<=WR_S8;
WR_S10_f<=WR_S9;
WR_S11_f<=WR_S10;
WR_S12_f<=WR_S11;
WR_S13_f<=WR_S12;
WR_S14_f<=WR_S13;
WR_S15_f<=WR_S14;
WR_S16_f<=WR_S15;
WR_S17_f<=WR_S16;
WR_S18_f<=WR_S17;
WR_S19_f<=WR_S18;
WR_S20_f<=WR_S19;
end if;
end process;

process(choice_phase_debug, WR_S1, WR_S2, WR_S3, WR_S4,
WR_S5, WR_S6, WR_S7, WR_S8,
WR_S9, WR_S10, WR_S11, WR_S12,
WR_S13, WR_S14, WR_S15, WR_S16,
WR_S17, WR_S18, WR_S19, WR_S20,
WR_S1_f, WR_S2_f, WR_S3_f, WR_S4_f,
WR_S5_f, WR_S6_f, WR_S7_f, WR_S8_f,
WR_S9_f, WR_S10_f, WR_S11_f, WR_S12_f,
WR_S13_f, WR_S14_f, WR_S15_f, WR_S16_f,
WR_S17_f, WR_S18_f, WR_S19_f, WR_S20_f
)
begin
case choice_phase_debug is 
--when "00000" => WR_S<=WR_S1; --old - with 2.56Gsa/s
--when "00001" => WR_S<=WR_S2;
--when "00010" => WR_S<=WR_S3;
--when "00011" => WR_S<=WR_S4;
--when "00100" => WR_S<=WR_S5;
--when "00101" => WR_S<=WR_S6;
--when "00110" => WR_S<=WR_S7;
--when "00111" => WR_S<=WR_S8;
--when "01000" => WR_S<=WR_S9;
--when "01001" => WR_S<=WR_S10;
--when "01010" => WR_S<=WR_S11;
--when "01011" => WR_S<=WR_S12;
--when "01100" => WR_S<=WR_S13;
--when "01101" => WR_S<=WR_S14;
--when "01110" => WR_S<=WR_S15;
--when "01111" => WR_S<=WR_S16;
--when "10000" => WR_S<=WR_S17;
--when "10001" => WR_S<=WR_S18;
--when "10010" => WR_S<=WR_S19;
--when "10011" => WR_S<=WR_S20;
when "00000" => WR_S<=WR_S1; --new - with 3.2 and 4.2 Gsa/s
when "00001" => WR_S<=WR_S1_f;
when "00010" => WR_S<=WR_S2;
when "00011" => WR_S<=WR_S2_f;
when "00100" => WR_S<=WR_S3;
when "00101" => WR_S<=WR_S3_f;
when "00110" => WR_S<=WR_S4;
when "00111" => WR_S<=WR_S4_f;
when "01000" => WR_S<=WR_S5;
when "01001" => WR_S<=WR_S5_f;
when "01010" => WR_S<=WR_S6;
when "01011" => WR_S<=WR_S6_f;
when "01100" => WR_S<=WR_S6;
when "01101" => WR_S<=WR_S6_f;
when "01110" => WR_S<=WR_S7;
when "01111" => WR_S<=WR_S7_f;
when "10000" => WR_S<=WR_S8;
when "10001" => WR_S<=WR_S8_f;
when "10010" => WR_S<=WR_S9;
when "10011" => WR_S<=WR_S9_f;
when others => WR_S<=WR_S1;
end case;
end process;


curr_low <= WR_S_low;
curr_bank <= WR_S_high;

end Behavioral;

