--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package RX_TX_definitions is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--


constant WILKINSON_CONVERT : std_logic_vector(7 downto 0) := x"01" ;
constant DAC_LOAD : std_logic_vector(7 downto 0) := x"02";
constant GENERAL_CONTROL : std_logic_vector(7 downto 0) := x"04";
constant READOUT : std_logic_vector(7 downto 0) := x"08";
constant FIRMWARE_ID : std_logic_vector(7 downto 0) := x"10";
constant SPI_LOAD : std_logic_vector(7 downto 0) := x"20";
constant SPI_EXECUTE : std_logic_vector(7 downto 0) := x"40";
constant REBOOT : std_logic_vector(7 downto 0) := x"80";


end RX_TX_definitions;

package body RX_TX_definitions is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end RX_TX_definitions;
