library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity point_rotate is
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;
        enable2 : in  std_logic;
        key_in  : in  std_logic_vector(3 downto 0);  -- "1010" triggers rotation z for now

        -- RAM Port B (Read)
        ram_raddr : out std_logic_vector(14 downto 0);
        ram_dout  : in  std_logic_vector(47 downto 0);

        -- RAM Port A (Write)
        ram_waddr : out std_logic_vector(14 downto 0);
        ram_din   : out std_logic_vector(47 downto 0);
        ram_we    : out std_logic;

        -- Control
        done      : out std_logic;
        writing   : out std_logic;
        reading   : out std_logic 
    );
end point_rotate;

architecture Behavioral of point_rotate is
    constant DEPTH : integer := 23247;

    -- Q8.8 Fixed-point constants
    constant COS_7 : signed(15 downto 0) := to_signed(254, 16);  -- cos(7) × 256
    constant SIN_7 : signed(15 downto 0) := to_signed(31, 16);   -- sin(5) × 256

    signal addr         : unsigned(14 downto 0) := (others => '0');
    signal rotating     : std_logic := '0';
    signal triggered    : std_logic := '0';
    signal dones        : std_logic := '0';

    -- Pipeline stage registers
    signal x, y, z          : signed(15 downto 0);
    signal x_ext, y_ext     : signed(31 downto 0);
    signal x_cos, y_sin     : signed(47 downto 0);
    signal x_rot_tmp        : signed(47 downto 0);
    signal y_cos, x_sin     : signed(47 downto 0);
    signal y_rot_tmp        : signed(47 downto 0);
    signal x_final, y_final : signed(15 downto 0);

    -- Pipeline control
    signal stage            : integer range 0 to 8 := 0;
    signal counter          : integer range 0 to 10 := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                addr      <= (others => '0');
                rotating  <= '0';
                triggered <= '0';
                dones     <= '0';
                ram_we    <= '0';
                writing   <= '0';
                reading   <= '0';  
                stage     <= 0;
            elsif enable = '1' and key_in = "1010" and rotating = '0' and dones = '0' and triggered = '0' then
                rotating  <= '1';
                triggered <= '1';
                addr      <= (others => '0');
                stage     <= 7;
                dones     <= '0';
            elsif enable = '0' then
                triggered <= '0';
            elsif rotating = '1' then
                case stage is
                    when 0 =>
                        x <= signed(ram_dout(47 downto 32));
                        y <= signed(ram_dout(31 downto 16));
                        z <= signed(ram_dout(15 downto 0));  
                        stage <= 1;

                    when 1 =>
                        x_ext <= resize(x, 32);
                        y_ext <= resize(y, 32);
                        --reading <= '0';  
                        stage <= 2;

                    when 2 =>
                        x_cos <= resize(x_ext * resize(COS_7, 32), 48);
                        y_sin <= resize(y_ext * resize(SIN_7, 32), 48);
                        x_sin <= resize(x_ext * resize(SIN_7, 32), 48);
                        y_cos <= resize(y_ext * resize(COS_7, 32), 48);
                        stage <= 3;

                    when 3 =>
                        x_rot_tmp <= x_cos - y_sin;
                        y_rot_tmp <= x_sin + y_cos;
                        ram_we    <= '1';
                        writing   <= '1';
                        ram_waddr <= std_logic_vector(addr);
                        stage <= 4;

                    when 4 =>
                        x_final <= resize(x_rot_tmp(23 downto 8), 16);
                        y_final <= resize(y_rot_tmp(23 downto 8), 16);
                        stage <= 5;

                    when 5 =>
                        ram_din   <= std_logic_vector(x_final & y_final & z);
                        if addr = to_unsigned(DEPTH - 1, addr'length) then
                            ram_we  <= '0';
                            stage <= 8;
                        else
                            addr <= addr + 1;
                            stage <= 6;
                        end if;
                        

                    when 6 =>
                        
                        stage <= 0; 
                    
                    when 7 =>
                        reading <= '1';
                        stage <= 0;
                        
                    when 8 => 
                    
                        if counter < 10 then
                            counter <= counter +1;
                            stage <= 8;
                        else
                            rotating <= '0';
                            dones    <= '1';
                        end if;
                        
                        
                end case;
                
            elsif enable2 = '1' then
                dones <= '0';
                triggered <= '0';
                
            else
                ram_we  <= '0';
                writing <= '0';
--                addr    <= (others => '0');
                reading <= '0';  
            end if;
        end if;
    end process;

    -- Continuous outputs
    ram_raddr <= std_logic_vector(addr);
    done      <= dones;

end Behavioral;
