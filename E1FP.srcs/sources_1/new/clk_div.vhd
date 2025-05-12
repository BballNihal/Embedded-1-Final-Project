----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/22/2025 11:37:29 AM
-- Design Name: 
-- Module Name: clk_div - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.numeric_std.ALL;
  
entity clk_div is
    port ( 
        clk : in std_logic;
        div : out std_logic);
end clk_div;
  
architecture Behavioral of clk_div is
    signal count: integer:=0;
    signal tmp : std_logic;
begin
  
process(clk)
begin
    if rising_edge(clk) then
        count <=count+1;
        if (count = 4) then
            count <= 0;
            tmp <= '1';
        else tmp <= '0';
        end if;
    end if;
end process;
div <= tmp;
    
end Behavioral;
