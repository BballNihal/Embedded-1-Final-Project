library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_read_mux is
    Port (
        -- Read request control
        project_reading  : in  std_logic;
        rotate_reading   : in  std_logic;

        -- Address inputs from modules
        project_addr     : in  std_logic_vector(14 downto 0);
        rotate_addr      : in  std_logic_vector(14 downto 0);

        -- Output to RAM Port B
        addrb            : out std_logic_vector(14 downto 0)
    );
end ram_read_mux;

architecture Behavioral of ram_read_mux is
begin
    process(project_reading, rotate_reading, project_addr, rotate_addr)
    begin
        if project_reading = '1' and rotate_reading = '0' then
            addrb <= project_addr;
        elsif rotate_reading = '1' and project_reading = '0' then
            addrb <= rotate_addr;
        else
            addrb <= (others => '0'); 
        end if;
    end process;
end Behavioral;
