library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debounce is
    Port ( clk   : in  STD_LOGIC;
           btn   : in  STD_LOGIC;
           dbnc  : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is
    signal shift_reg : STD_LOGIC_VECTOR(1 downto 0);  
    signal counter   : INTEGER := 0;  
    signal stable_btn : STD_LOGIC;
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            shift_reg <= shift_reg(0) & btn;  
            
            stable_btn <= shift_reg(1);  

            if stable_btn = '1' then
                if counter < 2499999 then
                    counter <= counter + 1;
                end if;
            else
                counter <= 0; 
            end if;

            if counter = 2499999 then 
                dbnc <= '1';
            else
                dbnc <= '0';
            end if;
        end if;
    end process;

end Behavioral;
