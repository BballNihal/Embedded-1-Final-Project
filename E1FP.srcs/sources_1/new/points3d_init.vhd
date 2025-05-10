library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity points3d_init is
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- ROM interface
        rom_dout : in  std_logic_vector(47 downto 0);
        rom_addr : out std_logic_vector(14 downto 0);  -- fixed width

        -- RAM interface
        ram_din  : out std_logic_vector(47 downto 0);
        ram_addr : out std_logic_vector(14 downto 0);  -- fixed width
        ram_we   : out std_logic;

        -- Status output
        done     : out std_logic;
        writing  : out std_logic
    );
end points3d_init;

architecture Behavioral of points3d_init is
    constant ROM_DEPTH : integer := 23247;  -- Set to actual point count
    signal addr_counter : unsigned(14 downto 0) := (others => '0');  -- fixed width
    signal copying      : std_logic := '0';
    signal dones    :   std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                addr_counter <= (others => '0');
                copying      <= '1';  -- Start copy after reset
                dones        <= '0';
                ram_we       <= '0';
                writing      <= '0';
            elsif copying = '1' and dones = '0' then
                -- Write ROM data to RAM
                ram_we   <= '1';
                ram_din  <= rom_dout;
                ram_addr <= std_logic_vector(addr_counter);
                writing <= '1';

--                ram_we   <= '1';
--                ram_din  <= "000000010000000000000001000000000000000100000000";
--                ram_addr <= std_logic_vector(addr_counter);
--                writing <= '1';

                if addr_counter = to_unsigned(ROM_DEPTH - 1, addr_counter'length) then
                    copying <= '0';
                    dones    <= '1';
                    ram_we  <= '0';
                else
                    addr_counter <= addr_counter + 1;
                end if;
            else
                ram_we <= '0';  -- idle state
                writing <= '0';
            end if;
        end if;
    end process;

    -- Drive ROM address
    done <= dones;
    rom_addr <= std_logic_vector(addr_counter);

end Behavioral;
