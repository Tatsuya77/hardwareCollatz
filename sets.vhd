library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package sets is

    type set is record
        peak : std_logic_vector(17 downto 0);
        start : std_logic_vector(9 downto 0);
        len  : std_logic_vector(7 downto 0);
    end record;
    type sets is array(0 to 3) of set;
    

 end package sets;
