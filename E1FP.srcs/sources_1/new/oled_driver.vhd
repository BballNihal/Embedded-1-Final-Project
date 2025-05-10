library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity oled_driver is
    Port (
        clk         : in  std_logic;  -- System clock (25-100 MHz)
        rst         : in  std_logic;  -- Active-high reset

        pixel_x     : in  std_logic_vector(6 downto 0);  -- 0-95
        pixel_y     : in  std_logic_vector(5 downto 0);  -- 0-63
        pixel_color : in  std_logic_vector(15 downto 0); -- RGB565 (R5 G6 B5)
        pixel_we    : in  std_logic;

        -- OLED SPI pins
        oled_res    : out std_logic;
        oled_cs     : out std_logic;
        oled_dc     : out std_logic;
        oled_sclk   : out std_logic;
        oled_mosi   : out std_logic
    );
end oled_driver;

architecture Behavioral of oled_driver is

    type state_t is (
        INIT_RESET_LOW, INIT_RESET_HIGH, INIT_SEND, IDLE, SEND_CMD, SEND_DATA,
        WRITE_X_CMD, WRITE_X_VAL, WRITE_Y_CMD, WRITE_Y_VAL,
        WRITE_COLOR1, WRITE_COLOR2
    );

    signal state       : state_t := INIT_RESET_LOW;
    signal next_state  : state_t := IDLE;

    signal delay_count : integer := 0;
    signal bit_count   : integer range 0 to 7 := 0;
    signal shift_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal cmd_index   : integer range 0 to 10 := 0;

    type init_array is array (0 to 10) of std_logic_vector(7 downto 0);
    constant init_sequence : init_array := (
        x"AE",       -- Display OFF
        x"A0", x"72",-- Set remap
        x"A1", x"00",-- Display start line
        x"A2", x"00",-- Display offset
        x"A4",       -- Normal display
        x"AF",       -- Display ON
        x"15", x"00" -- Column range (dummy)
    );

    signal res     : std_logic := '1';
    signal cs      : std_logic := '1';
    signal dc      : std_logic := '0';
    signal sclk    : std_logic := '0';
    signal mosi    : std_logic := '0';

begin

    oled_res  <= res;
    oled_cs   <= cs;
    oled_dc   <= dc;
    oled_sclk <= sclk;
    oled_mosi <= mosi;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= INIT_RESET_LOW;
                delay_count <= 0;
                cmd_index <= 0;
                cs <= '1'; res <= '1';
            else
                case state is

                    when INIT_RESET_LOW =>
                        res <= '0';
                        delay_count <= delay_count + 1;
                        if delay_count > 100000 then
                            delay_count <= 0;
                            state <= INIT_RESET_HIGH;
                        end if;

                    when INIT_RESET_HIGH =>
                        res <= '1';
                        delay_count <= delay_count + 1;
                        if delay_count > 100000 then
                            delay_count <= 0;
                            state <= INIT_SEND;
                        end if;

                    when INIT_SEND =>
                        if cmd_index > 10 then
                            state <= IDLE;
                        else
                            shift_reg <= init_sequence(cmd_index);
                            dc <= '0'; cs <= '0'; bit_count <= 7;
                            state <= SEND_CMD;
                        end if;

                    when SEND_CMD =>
                        sclk <= '0';
                        mosi <= shift_reg(bit_count);
                        delay_count <= delay_count + 1;
                        if delay_count > 2 then
                            sclk <= '1';
                            delay_count <= 0;
                            if bit_count = 0 then
                                cs <= '1';
                                cmd_index <= cmd_index + 1;
                                state <= INIT_SEND;
                            else
                                bit_count <= bit_count - 1;
                            end if;
                        end if;

                    when IDLE =>
                        if pixel_we = '1' then
                            state <= WRITE_X_CMD;
                        end if;

                    when WRITE_X_CMD =>
                        shift_reg <= x"15"; -- Set column addr
                        dc <= '0'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= WRITE_X_VAL;

                    when WRITE_X_VAL =>
                        shift_reg <= std_logic_vector(resize(unsigned(pixel_x), 8));
                        dc <= '1'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= WRITE_Y_CMD;

                    when WRITE_Y_CMD =>
                        shift_reg <= x"75"; -- Set row addr
                        dc <= '0'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= WRITE_Y_VAL;

                    when WRITE_Y_VAL =>
                        shift_reg <= std_logic_vector(resize(unsigned(pixel_y), 8));
                        dc <= '1'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= WRITE_COLOR1;

                    when WRITE_COLOR1 =>
                        shift_reg <= pixel_color(15 downto 8); -- High byte
                        dc <= '1'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= WRITE_COLOR2;

                    when WRITE_COLOR2 =>
                        shift_reg <= pixel_color(7 downto 0); -- Low byte
                        dc <= '1'; cs <= '0'; bit_count <= 7;
                        state <= SEND_DATA;
                        next_state <= IDLE;

                    when SEND_DATA =>
                        sclk <= '0';
                        mosi <= shift_reg(bit_count);
                        delay_count <= delay_count + 1;
                        if delay_count > 2 then
                            sclk <= '1';
                            delay_count <= 0;
                            if bit_count = 0 then
                                cs <= '1';
                                state <= next_state;
                            else
                                bit_count <= bit_count - 1;
                            end if;
                        end if;

                    when others =>
                        state <= INIT_RESET_LOW;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
