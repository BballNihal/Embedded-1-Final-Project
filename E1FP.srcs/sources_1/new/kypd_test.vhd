library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity kypd_test is
    Port (
        clk   : in  STD_LOGIC;
        input : in  STD_LOGIC_VECTOR(3 downto 0);
        led   : out STD_LOGIC
    );
end kypd_test;

architecture Behavioral of kypd_test is
    signal last_input : STD_LOGIC_VECTOR(3 downto 0);
    signal led_reg    : STD_LOGIC := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            last_input <= input;
            case input is
                when "0000" => led_reg <= '0';  -- '0'
                when "0001" => led_reg <= '0';  -- '1'
                when "0010" => led_reg <= '0';  -- '2'
                when "0011" => led_reg <= '0';  -- '3'
                when "0100" => led_reg <= '0';  -- '4'
                when "0101" => led_reg <= '0';  -- '5'
                when "0110" => led_reg <= '0';  -- '6'
                when "0111" => led_reg <= '0';  -- '7'
                when "1000" => led_reg <= '0';  -- '8'
                when "1001" => led_reg <= '0';  -- '9'
                when "1010" => led_reg <= '1';  -- 'A'
                when "1011" => led_reg <= '0';  -- 'B'
                when "1100" => led_reg <= '0';  -- 'C'
                when "1101" => led_reg <= '0';  -- 'D'
                when "1110" => led_reg <= '0';  -- 'E'
                when "1111" => led_reg <= '0';  -- 'F'
                when others => led_reg <= '0';  -- safety default
            end case;
        end if;
    end process;

    led <= led_reg;

end Behavioral;
