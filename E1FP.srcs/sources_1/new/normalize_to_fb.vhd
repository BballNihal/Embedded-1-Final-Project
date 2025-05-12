library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity normalize_to_fb is
    generic (
        DEPTH_3D  : integer := 11624;
        FB_W      : integer := 240;
        FB_H      : integer := 240;
        FRAC_BITS : integer := 16              -- Q16.16
    );
    port (
        clk   : in  std_logic;                 -- pixel clock (25-40 MHz)
        rst   : in  std_logic;
        enable: in  std_logic;

        ram2d_addr : out std_logic_vector(13 downto 0);
        ram2d_dout : in  std_logic_vector(31 downto 0);

        fb_addr : out std_logic_vector(15 downto 0); -- 0-57 599
        fb_din  : out std_logic_vector(7 downto 0);
        fb_we   : out std_logic;

        done    : out std_logic
    );
end normalize_to_fb;

architecture rtl of normalize_to_fb is

    --fsm
    type state_t is (
        IDLE, CLEAR_FB,
        FIND_MINMAX, RANGING, DIV_W, DIV_H, SELECTING, OFFSET_PREP,
        FETCH, DIFF, MUL, REG_MUL, ADD_OFF, CLAMP, ADDR_CALC, WRITE_FB,
        FINISHED
    );
    signal st : state_t := IDLE;

    -- i am counting i am counting i am faded
    signal pt_idx : unsigned(13 downto 0) := (others => '0');
    signal fb_idx : unsigned(15 downto 0) := (others => '0');

    -- BRAM read buffer
    signal u_buf16, v_buf16 : signed(15 downto 0);
    signal data_valid       : std_logic := '0';


    -- i am scaling 
    constant S32_MIN : signed(31 downto 0) := to_signed(-2**31,32);
    constant S32_MAX : signed(31 downto 0) := to_signed( 2**31-1,32);

    signal min_u32, min_v32 : signed(31 downto 0) := S32_MAX;
    signal max_u32, max_v32 : signed(31 downto 0) := S32_MIN;

    signal range_u32, range_v32      : signed(31 downto 0);
    signal scale_w_q1616, scale_h_q1616, scale_q1616 : signed(31 downto 0);

    signal off_x_int, off_y_int      : signed(15 downto 0);


    signal diff_x32, diff_y32          : signed(31 downto 0);
    signal mul_x_q1616, mul_y_q1616    : signed(31 downto 0);  
    signal pix_x_pre, pix_y_pre        : signed(15 downto 0);
    signal pix_x_reg, pix_y_reg        : signed(15 downto 0);

    --addr
    signal addr_calcu : unsigned(31 downto 0);

    constant ONE_Q1616 : signed(31 downto 0) := to_signed(2**FRAC_BITS,32);
    constant WHITE     : std_logic_vector(7 downto 0) := x"FF";
    constant FB_W_U16  : unsigned(15 downto 0) := to_unsigned(FB_W,16);
begin
    ---------------------------------------------------------------------------
    process(clk)
        variable scaled_max_x, scaled_max_y : signed(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                st         <= IDLE;
                fb_we      <= '0';
                done       <= '0';
                ram2d_addr <= (others => '0');
                fb_addr    <= (others => '0');
                data_valid <= '0';

            else
                case st is
                ----------------------------------------------------------------
                when IDLE =>
                    fb_we <= '0';  done <= '0';
                    if enable = '1' then
                        min_u32 <= S32_MAX;  max_u32 <= S32_MIN;
                        min_v32 <= S32_MAX;  max_v32 <= S32_MIN;
                        pt_idx  <= (others => '0');
                        fb_idx  <= (others => '0');
                        fb_we   <= '1';
                        fb_din  <= (others => '0');
                        ram2d_addr <= (others => '0');
                        data_valid  <= '0';
                        st <= CLEAR_FB;
                    end if;

                ----------------------------------------------------------------
                when CLEAR_FB =>
                    fb_addr <= std_logic_vector(fb_idx);
                    if fb_idx = to_unsigned(FB_W*FB_H-1, fb_idx'length) then
                        fb_we <= '0';
                        st    <= FIND_MINMAX;
                    else
                        fb_idx <= fb_idx + 1;
                    end if;

                ----------------------------------------------------------------
                when FIND_MINMAX =>
                    -- registered BRAM output
                    u_buf16 <= signed(ram2d_dout(31 downto 16));
                    v_buf16 <= signed(ram2d_dout(15 downto 0));

                    if data_valid = '1' then
                        if resize(u_buf16,32) < min_u32 then min_u32 <= resize(u_buf16,32); end if;
                        if resize(u_buf16,32) > max_u32 then max_u32 <= resize(u_buf16,32); end if;
                        if resize(v_buf16,32) < min_v32 then min_v32 <= resize(v_buf16,32); end if;
                        if resize(v_buf16,32) > max_v32 then max_v32 <= resize(v_buf16,32); end if;

                        if pt_idx = to_unsigned(DEPTH_3D-1, pt_idx'length) then
                            data_valid <= '0';
                            st <= RANGING;
                        end if;
                    end if;

                    pt_idx     <= pt_idx + 1;
                    ram2d_addr <= std_logic_vector(pt_idx + 1);
                    data_valid <= '1';

                ----------------------------------------------------------------
                when RANGING =>
                    range_u32 <= max_u32 - min_u32;
                    range_v32 <= max_v32 - min_v32;
                    st        <= DIV_W;

                when DIV_W =>
                    if range_u32 = 0 then
                        scale_w_q1616 <= ONE_Q1616;
                    else
                        scale_w_q1616 <= (to_signed(FB_W,32) sll FRAC_BITS) / range_u32;
                    end if;
                    st <= DIV_H;

                when DIV_H =>
                    if range_v32 = 0 then
                        scale_h_q1616 <= ONE_Q1616;
                    else
                        scale_h_q1616 <= (to_signed(FB_H,32) sll FRAC_BITS) / range_v32;
                    end if;
                    st <= SELECTING;

                when SELECTING =>
                    if scale_w_q1616 < scale_h_q1616 then
                        scale_q1616 <= scale_w_q1616;
                    else
                        scale_q1616 <= scale_h_q1616;
                    end if;
                    st <= OFFSET_PREP;

                ----------------------------------------------------------------
                when OFFSET_PREP =>
                    scaled_max_x := resize(range_u32 * scale_q1616,32) srl FRAC_BITS;
                    scaled_max_y := resize(range_v32 * scale_q1616,32) srl FRAC_BITS;

                    off_x_int <= to_signed((FB_W-1) - to_integer(scaled_max_x),16) / 2;
                    off_y_int <= to_signed((FB_H-1) - to_integer(scaled_max_y),16) / 2;

                    pt_idx      <= (others => '0');
                    ram2d_addr  <= (others => '0');
                    fb_we       <= '1';
                    fb_din      <= WHITE;
                    data_valid  <= '0';
                    st <= FETCH;

                ----------------------------------------------------------------

                when FETCH =>
                    u_buf16 <= signed(ram2d_dout(31 downto 16));
                    v_buf16 <= signed(ram2d_dout(15 downto 0));
                    pt_idx     <= pt_idx + 1;
                    ram2d_addr <= std_logic_vector(pt_idx + 1);
                    fb_we      <= '0';
                    data_valid <= '1';
                    st <= DIFF;

                when DIFF =>
                    diff_x32 <= resize(u_buf16,32) - min_u32;
                    diff_y32 <= resize(v_buf16,32) - min_v32;
                    st <= MUL;

                when MUL =>
                    -- 32 × 32 multiply
                    mul_x_q1616 <= resize(diff_x32 * scale_q1616,32);
                    mul_y_q1616 <= resize(diff_y32 * scale_q1616,32);
                    st <= REG_MUL;

                when REG_MUL =>                     
                    st <= ADD_OFF;

                when ADD_OFF =>
                    pix_x_pre <= resize(mul_x_q1616(31 downto FRAC_BITS),16) + off_x_int;
                    pix_y_pre <= resize(mul_y_q1616(31 downto FRAC_BITS),16) + off_y_int;
                    st <= CLAMP;

                when CLAMP =>
                    -- clip to 0 … 239
                    if pix_x_pre < 0 then
                        pix_x_reg <= to_signed(0,16);
                    elsif pix_x_pre > to_signed(FB_W-1,16) then
                        pix_x_reg <= to_signed(FB_W-1,16);
                    else
                        pix_x_reg <= pix_x_pre;
                    end if;

                    if pix_y_pre < 0 then
                        pix_y_reg <= to_signed(0,16);
                    elsif pix_y_pre > to_signed(FB_H-1,16) then
                        pix_y_reg <= to_signed(FB_H-1,16);
                    else
                        pix_y_reg <= pix_y_pre;
                    end if;
                    st <= ADDR_CALC;

                when ADDR_CALC =>
                    addr_calcu <= unsigned(pix_y_reg) * FB_W_U16 + unsigned(pix_x_reg);
                    st <= WRITE_FB;

                when WRITE_FB =>
                    fb_addr <= std_logic_vector(addr_calcu(15 downto 0));
                    fb_we   <= '1';

                    if pt_idx = to_unsigned(DEPTH_3D-1, pt_idx'length) then
                        st <= FINISHED;
                    else
                        st <= FETCH;
                    end if;

                ----------------------------------------------------------------
                when FINISHED =>
                    fb_we <= '0';
                    done  <= '1';
                    if enable = '0' then
                        st <= IDLE;
                    end if;

                end case;
            end if; 
        end if;   
    end process;
end rtl;
