library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_pusher is
    port(
        clk   : in std_logic;
        en    : in std_logic;
        vs    : in std_logic;
        vid   : in std_logic;
        pixel : in std_logic_vector(7 downto 0);
        hcount: in std_logic_vector(9 downto 0);
        R     : out std_logic_vector(3 downto 0);
        B     : out std_logic_vector(3 downto 0);
        G     : out std_logic_vector(3 downto 0);
        addr  : out std_logic_vector(15 downto 0)
    );
end pixel_pusher;

architecture Behavioral of pixel_pusher is

    signal addrIn : std_logic_vector(15 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' and vid = '1' and unsigned(hcount) < 240 then
                --
                R <= pixel(7 downto 5) & "0";       -- 3 to 4
                G <= pixel(4 downto 2) & "0";      -- 3 to 4
                B <= pixel(1 downto 0) & "00";      -- 2 to 4
                addrIn <= std_logic_vector(unsigned(addrIn) + 1);
            else
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            end if;

            -- vsync reset
            if vs = '0' then
                addrIn <= (others => '0');
            end if;
        end if;
    end process;

    addr <= addrIn;

end Behavioral;