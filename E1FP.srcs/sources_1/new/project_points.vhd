library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_points is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;

        -- 3-D point RAM (in Q8.8)
        ram3d_addr : out std_logic_vector(13 downto 0);
        ram3d_dout : in  std_logic_vector(47 downto 0);

        -- 2d point RAM (in ints)
        ram2d_addr : out std_logic_vector(13 downto 0);
        ram2d_din  : out std_logic_vector(31 downto 0);
        ram2d_we   : out std_logic;

        done    : out std_logic;
        reading : out std_logic
    );
end project_points;

architecture rtl of project_points is

    constant DEPTH        : integer := 11624;
    constant FOCAL_Q88    : integer := 256000;          -- 1000·256
    constant Z_OFFSET_Q88 : integer := 768;             -- 3·256 
    constant FRAC_BITS    : integer := 16;              -- Q16.16

    constant FOCAL_S48    : signed(47 downto 0) := to_signed(FOCAL_Q88,48);
    constant ROUND_BIAS48 : signed(47 downto 0) := to_signed(32768,48);


    component div_gen_0
        port (
            aclk   : in  std_logic;
            aclken : in  std_logic;
            -- dividend / divisor
            s_axis_dividend_tvalid : in  std_logic;
            s_axis_dividend_tdata  : in  std_logic_vector(63 downto 0);
            s_axis_divisor_tvalid  : in  std_logic;
            s_axis_divisor_tdata   : in  std_logic_vector(47 downto 0);
            -- quotient (80 bits)
            m_axis_dout_tvalid     : out std_logic;
            m_axis_dout_tdata      : out std_logic_vector(79 downto 0)
        );
    end component;

    type st_t is (
        IDLE,SUM_CENT,FINISH_CENT,
        LOAD_PT,
        EXT_U,MUL_U,EXT_V,MUL_V,
        FEED_DIV_U,WAIT_U,
        FEED_DIV_V,WAIT_V,
        ROUND,WRITE,NEXT_PT
    );
    signal st : st_t := IDLE;

    --centroid stuff
    signal addr           : unsigned(13 downto 0) := (others=>'0');
    signal x_sum,y_sum,z_sum : signed(31 downto 0) := (others=>'0');
    signal cx,cy,cz       : signed(15 downto 0);


    signal x_c,y_c,z_c    : signed(15 downto 0);
    signal x_c_ext,y_c_ext: signed(47 downto 0);
    signal u_tmp,v_tmp    : signed(47 downto 0);     -- Q16.16
    signal u_div_reg,v_div_reg : signed(47 downto 0);
    signal u_round,v_round     : signed(47 downto 0);

    --divider stuff
    signal div_tv     : std_logic := '0';
    signal div_divd   : std_logic_vector(63 downto 0);
    signal div_divs   : std_logic_vector(47 downto 0);
    signal div_ready  : std_logic;
    signal div_q      : std_logic_vector(79 downto 0);


    signal reading_r,done_r : std_logic := '0';
    signal trig,prev_en     : std_logic := '0';
begin

    -- divider ip stuff
    
    u_div : div_gen_0
        port map (
            aclk   => clk,
            aclken => '1',
            s_axis_dividend_tvalid => div_tv,
            s_axis_dividend_tdata  => div_divd,
            s_axis_divisor_tvalid  => div_tv,
            s_axis_divisor_tdata   => div_divs,
            m_axis_dout_tvalid     => div_ready,
            m_axis_dout_tdata      => div_q
        );



    process(clk)
        variable x,y,z : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst='1' then
                st        <= IDLE;
                addr      <= (others=>'0');
                ram2d_we  <= '0';
                reading_r <= '0';
                done_r    <= '0';
                trig      <= '0';
                x_sum     <= (others=>'0');
                y_sum     <= (others=>'0');
                z_sum     <= (others=>'0');
                div_tv    <= '0';

            else
                case st is
    ----------------------------------------------------------------------------
                when IDLE =>
                    ram2d_we  <= '0';
                    reading_r <= '0';
                    done_r    <= '0';
                    addr      <= (others=>'0');
                    x_sum     <= (others=>'0');
                    y_sum     <= (others=>'0');
                    z_sum     <= (others=>'0');
                    div_tv    <= '0';

                    if enable='1' and prev_en='0' and trig='0' then
                        reading_r <= '1';
                        trig      <= '1';
                        st        <= SUM_CENT;
                    end if;

                when SUM_CENT =>
                    x_sum <= x_sum + resize(signed(ram3d_dout(47 downto 32)),32);
                    y_sum <= y_sum + resize(signed(ram3d_dout(31 downto 16)),32);
                    z_sum <= z_sum + resize(signed(ram3d_dout(15 downto  0)),32);

                    if addr = to_unsigned(DEPTH-1,addr'length) then
                        st <= FINISH_CENT;
                    else
                        addr <= addr + 1;
                    end if;

                when FINISH_CENT =>
                    cx   <= resize(x_sum / DEPTH,16);
                    cy   <= resize(y_sum / DEPTH,16);
                    cz   <= resize(z_sum / DEPTH,16);
                    addr <= (others=>'0');
                    st   <= LOAD_PT;

    ----------------------------------------------------------------------------
                when LOAD_PT =>
                    x := signed(ram3d_dout(47 downto 32));
                    y := signed(ram3d_dout(31 downto 16));
                    z := signed(ram3d_dout(15 downto  0));

                    -- honestly centroid kinda pointless ts(this) is almost perfectly centered anyway
                    x_c <= x - cx;
                    y_c <= y - cy;
                    z_c <= z - cz + to_signed(Z_OFFSET_Q88,16);
                    st  <= EXT_U;

                when EXT_U =>
                    x_c_ext <= resize(x_c,48);
                    st      <= MUL_U;

                when MUL_U =>
                    u_tmp <= resize(x_c_ext * FOCAL_S48,48);    -- Q16.16
                    st    <= EXT_V;

                when EXT_V =>
                    y_c_ext <= resize(y_c,48);
                    st      <= MUL_V;

                when MUL_V =>
                    v_tmp <= resize(y_c_ext * FOCAL_S48,48);    -- Q16.16
                    st    <= FEED_DIV_U;

    ----------------------------------------------------------------------------

                when FEED_DIV_U =>
                    div_divd <= std_logic_vector( resize(u_tmp,64) sll FRAC_BITS );
                    div_divs <= std_logic_vector( resize(z_c,48)  sll 8 );
                    div_tv   <= '1';
                    st       <= WAIT_U;

                when WAIT_U =>
                    div_tv <= '0';
                    if div_ready = '1' then
                        -- take bits 63…16  (48-bit Q16.16)
                        u_div_reg <= signed(div_q(63 downto 16));
                        st        <= FEED_DIV_V;
                    end if;
                

                when FEED_DIV_V =>
                    div_divd <= std_logic_vector( resize(v_tmp,64) sll FRAC_BITS );
                    div_tv   <= '1';
                    st       <= WAIT_V;

                when WAIT_V =>
                    div_tv <= '0';
                    if div_ready = '1' then
                        v_div_reg <= signed(div_q(63 downto 16));
                        st        <= ROUND;
                    end if;

----------------------------------------------------------------------------------------

                when ROUND =>
                    u_round <= u_div_reg + ROUND_BIAS48;
                    v_round <= v_div_reg + ROUND_BIAS48;
                    st      <= WRITE;

                when WRITE =>
                    ram2d_din  <= std_logic_vector(u_round(31 downto 16)) &
                                  std_logic_vector(v_round(31 downto 16));
                    ram2d_addr <= std_logic_vector(addr);
                    ram2d_we   <= '1';
                    st         <= NEXT_PT;

                when NEXT_PT =>
--                    ram2d_we <= '0';
                    if addr = to_unsigned(DEPTH-1,addr'length) then
                        st        <= IDLE;
                        done_r    <= '1';
--                        reading_r <= '0';
                        trig      <= '0';
                    else
                        addr <= addr + 1;
                        st   <= LOAD_PT;
                    end if;

                end case;
                prev_en <= enable;
            end if; 
        end if;     
    end process;


    ram3d_addr <= std_logic_vector(addr);
    reading    <= reading_r;
    done       <= done_r;
end rtl;
