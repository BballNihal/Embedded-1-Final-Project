library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_points is
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;

        -- 3-D point RAM
        ram3d_addr  : out std_logic_vector(14 downto 0);
        ram3d_dout  : in  std_logic_vector(47 downto 0);

        -- 2-D point RAM
        ram2d_addr  : out std_logic_vector(14 downto 0);
        ram2d_din   : out std_logic_vector(31 downto 0);
        ram2d_we    : out std_logic;

        done        : out std_logic;
        reading     : out std_logic
    );
end project_points;

architecture Behavioral of project_points is
    ---------------------------------------------------------------------------
    -- Constants  (all Q8.8 unless noted)
    ---------------------------------------------------------------------------
    constant DEPTH        : integer := 23247;
    constant FOCAL_Q88    : integer := 256000;          -- 1000·256
    constant Z_OFFSET_Q88 : integer := 768;             -- 3·256
    constant FRAC_BITS    : integer := 16;              -- Q16.16 fractional field

    constant FOCAL_S48    : signed(47 downto 0) := to_signed(FOCAL_Q88, 48);
    constant ROUND_BIAS48 : signed(47 downto 0) := to_signed(32768, 48); -- 0x0000_8000

    ---------------------------------------------------------------------------
    -- FSM state
    ---------------------------------------------------------------------------
    type state_type is (
        IDLE, SUM_CENTROID, FINISH_CENTROID,
        LOAD_AND_CENTER,
        EXTEND_U, MULTIPLY_U,
        EXTEND_V, MULTIPLY_V,
        WAIT_DIVIDE, WAIT_DIVIDE_2, DIVIDE_AND_WRITE
    );
    signal state : state_type := IDLE;

    ---------------------------------------------------------------------------
    -- Accumulators / centroid registers
    ---------------------------------------------------------------------------
    signal addr                     : unsigned(14 downto 0) := (others => '0');
    signal x_sum, y_sum, z_sum      : signed(31 downto 0) := (others => '0');
    signal centroid_x, centroid_y,
           centroid_z               : signed(15 downto 0) := (others => '0');

    ---------------------------------------------------------------------------
    -- Working registers
    ---------------------------------------------------------------------------
    signal x_c, y_c, z_c            : signed(15 downto 0);
    signal x_c_ext, y_c_ext         : signed(47 downto 0);

    signal u_tmp, v_tmp             : signed(47 downto 0);  -- Q16.16
    signal u_num, v_num             : signed(63 downto 0);  -- Q32.32
    signal u_div, v_div             : signed(47 downto 0);  -- Q16.16
    signal u_round, v_round         : signed(47 downto 0);  -- Q16.16 (rounded)

    signal z_c_q1616, z_cn          : signed(47 downto 0);

    ---------------------------------------------------------------------------
    -- Control flags
    ---------------------------------------------------------------------------
    signal reading_reg, done_reg    : std_logic := '0';
    signal prev_enable, triggered   : std_logic := '0';
begin
    ---------------------------------------------------------------------------
    -- Main FSM
    ---------------------------------------------------------------------------
    process(clk)
        variable x, y, z : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= IDLE;
                addr        <= (others => '0');
                ram2d_we    <= '0';
                reading_reg <= '0';
                done_reg    <= '0';
                triggered   <= '0';
                x_sum       <= (others => '0');
                y_sum       <= (others => '0');
                z_sum       <= (others => '0');

            else
                case state is
                ----------------------------------------------------------------
                when IDLE =>
                    ram2d_we    <= '0';
                    reading_reg <= '0';
                    done_reg    <= '0';
                    addr        <= (others => '0');
                    x_sum       <= (others => '0');
                    y_sum       <= (others => '0');
                    z_sum       <= (others => '0');

                    if enable = '1' and prev_enable = '0' and triggered = '0' then
                        triggered   <= '1';
                        reading_reg <= '1';
                        state       <= SUM_CENTROID;
                    end if;

                ----------------------------------------------------------------
                when SUM_CENTROID =>
                    x_sum <= x_sum + resize(signed(ram3d_dout(47 downto 32)), 32);
                    y_sum <= y_sum + resize(signed(ram3d_dout(31 downto 16)), 32);
                    z_sum <= z_sum + resize(signed(ram3d_dout(15 downto  0)), 32);

                    if addr = to_unsigned(DEPTH - 1, addr'length) then
                        state <= FINISH_CENTROID;
                    else
                        addr  <= addr + 1;
                    end if;

                ----------------------------------------------------------------
                when FINISH_CENTROID =>
                    centroid_x <= resize(x_sum / DEPTH, 16);
                    centroid_y <= resize(y_sum / DEPTH, 16);
                    centroid_z <= resize(z_sum / DEPTH, 16);

                    addr  <= (others => '0');
                    state <= LOAD_AND_CENTER;

                ----------------------------------------------------------------
                when LOAD_AND_CENTER =>
                    x := signed(ram3d_dout(47 downto 32));
                    y := signed(ram3d_dout(31 downto 16));
                    z := signed(ram3d_dout(15 downto  0));

                    x_c <= x - centroid_x;
                    y_c <= y - centroid_y;
                    z_c <= z - centroid_z + to_signed(Z_OFFSET_Q88, 16);

                    state <= EXTEND_U;

                ----------------------------------------------------------------
                when EXTEND_U =>
                    x_c_ext <= resize(x_c, 48);
                    state   <= MULTIPLY_U;

                ----------------------------------------------------------------
                when MULTIPLY_U =>
                    u_tmp <= resize(x_c_ext * FOCAL_S48, 48);  -- Q16.16
                    state <= EXTEND_V;

                ----------------------------------------------------------------
                when EXTEND_V =>
                    y_c_ext <= resize(y_c, 48);
                    state   <= MULTIPLY_V;

                ----------------------------------------------------------------
                when MULTIPLY_V =>
                    v_tmp <= resize(y_c_ext * FOCAL_S48, 48);  -- Q16.16
                    state <= WAIT_DIVIDE;

                ----------------------------------------------------------------
                when WAIT_DIVIDE =>
                    z_cn  <= resize(z_c, 48);
                    state <= WAIT_DIVIDE_2;

                ----------------------------------------------------------------
                when WAIT_DIVIDE_2 =>
                    z_c_q1616 <= z_cn sll 8;                   -- Q16.16
                    state     <= DIVIDE_AND_WRITE;

                ----------------------------------------------------------------
                when DIVIDE_AND_WRITE =>
                    if z_c > 0 then
                        -- numerator shift to Q32.32
                        u_num <= resize(u_tmp, 64) sll FRAC_BITS;
                        v_num <= resize(v_tmp, 64) sll FRAC_BITS;

                        -- Q16.16 quotient
                        u_div <= resize(u_num / z_c_q1616, 48);
                        v_div <= resize(v_num / z_c_q1616, 48);

                        -- round-to-nearest (+0.5 LSB before dropping frac bits)
                        u_round <= u_div + ROUND_BIAS48;
                        v_round <= v_div + ROUND_BIAS48;

                        -- write integer part only
                        ram2d_din  <= std_logic_vector(
                                          u_round(31 downto 16) & v_round(31 downto 16)
                                      );
                        ram2d_addr <= std_logic_vector(addr);
                        ram2d_we   <= '1';
                    else
                        ram2d_we   <= '0';  -- divide-by-zero guard
                    end if;

                    if addr = to_unsigned(DEPTH - 1, addr'length) then
                        state       <= IDLE;
                        reading_reg <= '0';
                        done_reg    <= '1';
                        triggered   <= '0';
                    else
                        addr  <= addr + 1;
                        state <= LOAD_AND_CENTER;
                    end if;

                ----------------------------------------------------------------
                end case;
                prev_enable <= enable;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Port mirrors
    ---------------------------------------------------------------------------
    ram3d_addr <= std_logic_vector(addr);
    reading    <= reading_reg;
    done       <= done_reg;
end Behavioral;
