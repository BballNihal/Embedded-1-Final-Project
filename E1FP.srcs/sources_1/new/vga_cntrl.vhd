library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_ctrl is
    Port (
        clk     : in std_logic;
        en      : in std_logic;
        hcount  : out std_logic_vector(9 downto 0);
        vcount  : out std_logic_vector(9 downto 0);
        vid     : out std_logic;
        hs      : out std_logic;
        vs      : out std_logic
    );
end vga_ctrl;

architecture Behavioral of vga_ctrl is

    signal hcounter : std_logic_vector(9 downto 0) := (others => '0');
    signal vcounter : std_logic_vector(9 downto 0) := (others => '0');

begin

    --pixel counters
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                if unsigned(hcounter) < 799 then
                    hcounter <= std_logic_vector(unsigned(hcounter) + 1);
                else
                    hcounter <= (others => '0');
                    if unsigned(vcounter) < 524 then
                        vcounter <= std_logic_vector(unsigned(vcounter) + 1);
                    else
                        vcounter <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    --signal generation
    process(hcounter, vcounter)
    begin
        if unsigned(hcounter) < 480 and unsigned(vcounter) < 480 then
            vid <= '1';
        else
            vid <= '0';
        end if;

        -- Horiztal sync
        if unsigned(hcounter) >= 656 and unsigned(hcounter) <= 751 then
            hs <= '0';
        else
            hs <= '1';
        end if;

        -- vsync
        if unsigned(vcounter) >= 490 and unsigned(vcounter) <= 491 then
            vs <= '0';
        else
            vs <= '1';
        end if;
    end process;

    --Output
    hcount <= hcounter;
    vcount <= vcounter;

end Behavioral;