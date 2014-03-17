--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:59:39 03/10/2014
-- Design Name:   
-- Module Name:   C:/Users/Luca/Desktop/ANITA/SURF4_A7/par/tb_TX_RX.vhd
-- Project Name:  SURF4_A7
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TX_command_RX_data
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_TX_RX IS
END tb_TX_RX;
 
ARCHITECTURE behavior OF tb_TX_RX IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TX_command_RX_data
    PORT(
         CLK : IN  std_logic;
			do_command : in std_logic;
         command : IN  std_logic_vector(7 downto 0);
         arg1 : IN  std_logic_vector(7 downto 0);
         arg2 : IN  std_logic_vector(7 downto 0);
         arg3 : IN  std_logic_vector(7 downto 0);
         load_mem_data : IN  std_logic_vector(7 downto 0);
         load_mem_addr : OUT  std_logic_vector(7 downto 0);
         save_mem_data_ready : OUT  std_logic;
         save_mem_data : OUT  std_logic_vector(11 downto 0);
         save_mem_addr : OUT  std_logic_vector(7 downto 0);
         save_SPI_data : OUT  std_logic_vector(11 downto 0);
         save_SPI_data_ready : OUT  std_logic;
         FW_ID : OUT  std_logic_vector(11 downto 0);
         FW_ID_ready : OUT  std_logic;
         TX : OUT  std_logic;
         RX : IN  std_logic;
         done : OUT  std_logic;
         NACK : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal command : std_logic_vector(7 downto 0) := (others => '0');
   signal arg1 : std_logic_vector(7 downto 0) := (others => '0');
   signal arg2 : std_logic_vector(7 downto 0) := (others => '0');
   signal arg3 : std_logic_vector(7 downto 0) := (others => '0');
   signal load_mem_data : std_logic_vector(7 downto 0) := (others => '0');
   signal RX : std_logic := '0';

 	--Outputs
   signal load_mem_addr : std_logic_vector(7 downto 0);
   signal save_mem_data_ready : std_logic;
   signal save_mem_data : std_logic_vector(11 downto 0);
   signal save_mem_addr : std_logic_vector(7 downto 0);
   signal save_SPI_data : std_logic_vector(11 downto 0);
   signal save_SPI_data_ready : std_logic;
   signal FW_ID : std_logic_vector(11 downto 0);
   signal FW_ID_ready : std_logic;
   signal TX : std_logic;
   signal done : std_logic;
   signal NACK : std_logic;
   signal do_command : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
   type mem_arr is array(0 to 255) of std_logic_vector(7 downto 0);
	signal load_mem : mem_arr;
	
	signal char_in : std_logic_vector(7 downto 0);
	signal char_out : std_logic_vector(7 downto 0);
	signal cnt : std_logic_vector(7 downto 0);
   signal sync : std_logic := '0';
   signal new_char : std_logic;
	
	

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TX_command_RX_data PORT MAP (
          CLK => CLK,
			 do_command => do_command,
          command => command,
          arg1 => arg1,
          arg2 => arg2,
          arg3 => arg3,
          load_mem_data => load_mem_data,
          load_mem_addr => load_mem_addr,
          save_mem_data_ready => save_mem_data_ready,
          save_mem_data => save_mem_data,
          save_mem_addr => save_mem_addr,
          save_SPI_data => save_SPI_data,
          save_SPI_data_ready => save_SPI_data_ready,
          FW_ID => FW_ID,
          FW_ID_ready => FW_ID_ready,
          TX => TX,
          RX => RX,
          done => done,
          NACK => NACK
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
	   variable data_received : std_logic_vector(11 downto 0);

   begin		
      -- hold reset state for 100 ns.
		do_command <= '0';
		command <= x"00";
		arg1 <= x"00";
		arg2 <= x"00";
		arg3 <= x"00";
		RX <= '0';
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here
		do_command <= '1';
		command <= x"80";
		arg1 <= x"ff";
		arg2 <= x"04";
		arg3 <= x"05";
		wait for CLK_period;
		do_command <= '0';
		wait for CLK_period*100; --then ack
		RX <= '1';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;

		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;

--
--		RX <= '1'; --FW ID
--		wait for CLK_period;
--		RX <= '0';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;
--		RX <= '0';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;
--		RX <= '0';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;
--		RX <= '0';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;
--		RX <= '0';
--		wait for CLK_period;
--		RX <= '1';
--		wait for CLK_period;


--data_received:= x"0ff"; -- 255 bytes
--for j in 0 to 11 loop
--				RX <= data_received(j);
--				wait for CLK_period;
--			end loop;
--
--		for i in 0 to 254 loop
--			data_received:=conv_std_logic_vector(i,12);
--			for j in 0 to 11 loop
--				RX <= data_received(j);
--				wait for CLK_period;
--			end loop;
--		end loop;

		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;		
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '1';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
		RX <= '0';
		wait for CLK_period;
	
		wait for CLK_period*100; 
		
      wait;
   end process;
	
load_mem_data<=load_mem(CONV_INTEGER(load_mem_addr));

fill_mem: process
begin
	for i in 0 to 255 loop
		if conv_std_logic_vector(i,8) = x"CE" then
			load_mem(i)<=conv_std_logic_vector(205,8);
		else
			load_mem(i)<=conv_std_logic_vector(i,8);
		end if;
	end loop;
	wait;
end process;


recognize_start: process(CLK)
begin
if rising_edge(CLK) then
	new_char<='0';
	char_in<= TX & char_in(7 downto 1);
	if sync = '0' then 
		if char_in = x"FA" then 
			sync<= '1';
			cnt<= (others => '0');
			char_out<= char_in;
			new_char<='1';
		end if;
	else
		if cnt<7 then
			cnt<=cnt+1;
			if char_out = x"CE" then
				sync <= '0';
			end if;
		else
			cnt<= (others => '0');
			char_out<= char_in;
			new_char<='1';
		end if;
	end if;
			
			
end if;
end process;

END;
