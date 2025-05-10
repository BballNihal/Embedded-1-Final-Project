library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity oled_blue_fill is
    Port (
        clk_100mhz : in  STD_LOGIC;    -- Zybo's 100 MHz clock
        rst        : in  STD_LOGIC;    -- Reset button
        oled_dc    : out STD_LOGIC;    -- Data/Command
        oled_res   : out STD_LOGIC;    -- Reset (active low)
        oled_sclk  : out STD_LOGIC;    -- SPI Clock
        oled_sdin  : out STD_LOGIC;    -- SPI Data
        oled_cs    : out STD_LOGIC     -- Chip Select (active low)
    );
end oled_blue_fill;

architecture Behavioral of oled_blue_fill is
    type state_type is (
        INIT_RESET,
        INIT_COMMANDS,
        SET_WINDOW,
        SEND_PIXELS,
        DONE
    );
    
    signal state      : state_type := INIT_RESET;
    signal spi_clk    : STD_LOGIC := '0';
    signal spi_en     : STD_LOGIC := '0';
    signal spi_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal spi_busy   : STD_LOGIC := '0';
    signal spi_dc     : STD_LOGIC := '0';
    
    constant BLUE     : STD_LOGIC_VECTOR(15 downto 0) := x"001F"; -- R:0, G:0, B:31
    signal x          : integer range 0 to 95 := 0;
    signal y          : integer range 0 to 63 := 0;
    
    -- 10 MHz SPI clock (100MHz / 5)
    signal clk_div    : integer range 0 to 4 := 0;
    
begin

-- Clock divider for SPI (10 MHz from 100 MHz)
process(clk_100mhz)
begin
    if rising_edge(clk_100mhz) then
        if clk_div = 4 then
            spi_clk <= not spi_clk;
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
        end if;
    end if;
end process;

-- SPI Transmitter
process(spi_clk)
    variable bit_count : integer range 0 to 7 := 7;
begin
    if falling_edge(spi_clk) then
        if spi_en = '1' then
            oled_sdin <= spi_data(bit_count);
            if bit_count = 0 then
                spi_busy <= '1';
                bit_count := 7;
            else
                bit_count := bit_count - 1;
            end if;
        else
            bit_count := 7;
            spi_busy <= '0';
        end if;
    end if;
end process;

-- Main State Machine
process(clk_100mhz)
    variable init_step : integer := 0;
begin
    if rising_edge(clk_100mhz) then
        if rst = '1' then
            state <= INIT_RESET;
            oled_res <= '0';
            oled_cs <= '1';
            oled_dc <= '0';
        else
            case state is
                when INIT_RESET =>
                    oled_res <= '0';
                    if init_step < 100000 then -- 1ms reset pulse
                        init_step := init_step + 1;
                    else
                        oled_res <= '1';
                        state <= INIT_COMMANDS;
                    end if;

                when INIT_COMMANDS =>
                    oled_cs <= '0';
                    case init_step is
                        when 0 => spi_data <= x"AE"; spi_dc <= '0'; -- Display OFF
                        when 1 => spi_data <= x"A0"; spi_dc <= '0'; -- Set Remap
                                  -- RGB|COM Split|Scan Direction
                        when 2 => spi_data <= x"72"; spi_dc <= '1'; -- RGB=1, Split=1
                        when 3 => spi_data <= x"A1"; spi_dc <= '0'; -- Start Line
                        when 4 => spi_data <= x"00"; spi_dc <= '1';
                        when 5 => spi_data <= x"A2"; spi_dc <= '0'; -- Display Offset
                        when 6 => spi_data <= x"00"; spi_dc <= '1';
                        when 7 => spi_data <= x"A4"; spi_dc <= '0'; -- Normal Display
                        when 8 => spi_data <= x"A8"; spi_dc <= '0'; -- Set Mux Ratio
                        when 9 => spi_data <= x"3F"; spi_dc <= '1'; -- 63
                        when 10 => spi_data <= x"AD"; spi_dc <= '0'; -- Set Master Config
                        when 11 => spi_data <= x"8E"; spi_dc <= '1';
                        when 12 => spi_data <= x"B0"; spi_dc <= '0'; -- Power Save Mode
                        when 13 => spi_data <= x"00"; spi_dc <= '1'; -- Normal
                        when 14 => spi_data <= x"B3"; spi_dc <= '0'; -- Clock Div
                        when 15 => spi_data <= x"F0"; spi_dc <= '1'; -- 7:4 Osc, 3:0 Div
                        when 16 => spi_data <= x"8A"; spi_dc <= '0'; -- Precharge A
                        when 17 => spi_data <= x"64"; spi_dc <= '1'; -- 0.6*Vcc
                        when 18 => spi_data <= x"8B"; spi_dc <= '0'; -- Precharge B
                        when 19 => spi_data <= x"78"; spi_dc <= '1'; -- 0.6*Vcc
                        when 20 => spi_data <= x"8C"; spi_dc <= '0'; -- Precharge C
                        when 21 => spi_data <= x"64"; spi_dc <= '1';
                        when 22 => spi_data <= x"BE"; spi_dc <= '0'; -- VCOMH
                        when 23 => spi_data <= x"3E"; spi_dc <= '1'; -- 0.86*Vcc
                        when 24 => spi_data <= x"AF"; spi_dc <= '0'; -- Display ON
                        when others => state <= SET_WINDOW;
                    end case;
                    
                    if spi_busy = '0' then
                        spi_en <= '1';
                        oled_dc <= spi_dc;
                        init_step := init_step + 1;
                    else
                        spi_en <= '0';
                    end if;

                when SET_WINDOW =>
                    case init_step is
                        when 0 => spi_data <= x"15"; spi_dc <= '0'; -- Set Column
                        when 1 => spi_data <= x"00"; spi_dc <= '1'; -- Start
                        when 2 => spi_data <= x"5F"; spi_dc <= '1'; -- End (95)
                        when 3 => spi_data <= x"75"; spi_dc <= '0'; -- Set Row
                        when 4 => spi_data <= x"00"; spi_dc <= '1'; -- Start
                        when 5 => spi_data <= x"3F"; spi_dc <= '1'; -- End (63)
                        when 6 => spi_data <= x"5C"; spi_dc <= '0'; -- Write RAM
                        when others => state <= SEND_PIXELS;
                    end case;
                    
                    if spi_busy = '0' then
                        spi_en <= '1';
                        oled_dc <= spi_dc;
                        if init_step < 6 then
                            init_step := init_step + 1;
                        else
                            state <= SEND_PIXELS;
                            x <= 0;
                            y <= 0;
                        end if;
                    else
                        spi_en <= '0';
                    end if;

                when SEND_PIXELS =>
                    if spi_busy = '0' then
                        if y < 64 then
                            if x < 96 then
                                if spi_en = '0' then
                                    spi_data <= BLUE(15 downto 8); -- High byte
                                    spi_dc <= '1';
                                    spi_en <= '1';
                                else
                                    spi_data <= BLUE(7 downto 0); -- Low byte
                                    x <= x + 1;
                                end if;
                            else
                                x <= 0;
                                y <= y + 1;
                            end if;
                        else
                            state <= DONE;
                        end if;
                    else
                        spi_en <= '0';
                    end if;

                when DONE =>
                    oled_cs <= '1';
                    null;
            end case;
        end if;
    end if;
end process;

oled_sclk <= spi_clk when spi_en = '1' else '0';
end Behavioral;
