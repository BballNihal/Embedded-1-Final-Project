library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_write_mux is
    Port (
        -- Write request signals from two modules
        init_writing     : in std_logic;
        init_we          : in std_logic;
        init_addr        : in std_logic_vector(13 downto 0);
        init_din         : in std_logic_vector(47 downto 0);

        rotate_writing   : in std_logic;
        rotate_we        : in std_logic;
        rotate_addr      : in std_logic_vector(13 downto 0);
        rotate_din       : in std_logic_vector(47 downto 0);

        -- Output to RAM Port A
        wea              : out std_logic;
        addra            : out std_logic_vector(13 downto 0);
        dina             : out std_logic_vector(47 downto 0)
    );
end ram_write_mux;

architecture Behavioral of ram_write_mux is
begin
    process(init_writing, init_we, init_addr, init_din, rotate_we, rotate_addr, rotate_din)
    begin
        if init_writing = '1' and rotate_writing = '0' then
            wea   <= init_we;
            addra <= init_addr;
            dina  <= init_din;
        elsif rotate_writing = '1' and init_writing = '0' then
            wea   <= rotate_we;
            addra <= rotate_addr;
            dina  <= rotate_din;
        else
            wea   <= '0';
            addra <= (others => '0');
            dina  <= (others => '0');
        end if;
    end process;
end Behavioral;
