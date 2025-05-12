library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tester is
    Port (
        clk   : in  STD_LOGIC;
        input : in  STD_LOGIC_VECTOR(3 downto 0);
        led   : out STD_LOGIC
    );
end tester kypd_test;

architecture Behavioral of tester is
    signal last_input : STD_LOGIC_VECTOR(3 downto 0);
    signal led_reg    : STD_LOGIC := '0';
begin

end Behavioral;