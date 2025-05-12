library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity point_rotate is 
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic;
        enable2 : in  std_logic;
        key_in  : in  std_logic_vector(3 downto 0);  

        -- read port initial
        ram_raddr : out std_logic_vector(13 downto 0);
        ram_dout  : in  std_logic_vector(47 downto 0);

        -- write port rotated NO MORE FLOATING POINT DRIFT yippie!!!
        ram_waddr : out std_logic_vector(13 downto 0);
        ram_din   : out std_logic_vector(47 downto 0);
        ram_we    : out std_logic;

        -- Control
        done      : out std_logic;
        writing   : out std_logic;
        reading   : out std_logic 
    );
end point_rotate;

architecture Behavioral of point_rotate is
    constant DEPTH : integer := 11624;

    -- cos/sin thank you chad!
    constant COS_0 : signed(15 downto 0) := to_signed(256, 16); -- cos(0°) * 256
    constant COS_5 : signed(15 downto 0) := to_signed(255, 16);  -- cos(5) × 256
    constant COS_10 : signed(15 downto 0) := to_signed(252, 16); -- cos(10) * 256
    constant COS_15 : signed(15 downto 0) := to_signed(247, 16); --cos(25) * 256
    constant COS_20  : signed(15 downto 0) := to_signed( 241, 16); -- cos(20)  * 256
    constant COS_25  : signed(15 downto 0) := to_signed( 232, 16); -- cos(25)  * 256
    constant COS_30  : signed(15 downto 0) := to_signed( 222, 16); -- cos(30)  * 256
    constant COS_35  : signed(15 downto 0) := to_signed( 210, 16); -- cos(35)  * 256
    constant COS_40  : signed(15 downto 0) := to_signed( 196, 16); -- cos(40)  * 256
    constant COS_45  : signed(15 downto 0) := to_signed( 181, 16); -- cos(45)  * 256
    constant COS_50  : signed(15 downto 0) := to_signed( 165, 16); -- cos(50)  * 256
    constant COS_55  : signed(15 downto 0) := to_signed( 147, 16); -- cos(55)  * 256
    constant COS_60  : signed(15 downto 0) := to_signed( 128, 16); -- cos(60)  * 256
    constant COS_65  : signed(15 downto 0) := to_signed( 108, 16); -- cos(65)  * 256
    constant COS_70  : signed(15 downto 0) := to_signed(  88, 16); -- cos(70)  * 256
    constant COS_75  : signed(15 downto 0) := to_signed(  66, 16); -- cos(75)  * 256
    constant COS_80  : signed(15 downto 0) := to_signed(  44, 16); -- cos(80)  * 256
    constant COS_85  : signed(15 downto 0) := to_signed(  22, 16); -- cos(85)  * 256
    constant COS_90  : signed(15 downto 0) := to_signed(   0, 16); -- cos(90)  * 256
    constant COS_95  : signed(15 downto 0) := to_signed( -22, 16); -- cos(95)  * 256
    constant COS_100 : signed(15 downto 0) := to_signed( -44, 16); -- cos(100) * 256
    constant COS_105 : signed(15 downto 0) := to_signed( -66, 16); -- cos(105) * 256
    constant COS_110 : signed(15 downto 0) := to_signed( -88, 16); -- cos(110) * 256
    constant COS_115 : signed(15 downto 0) := to_signed(-108, 16); -- cos(115) * 256
    constant COS_120 : signed(15 downto 0) := to_signed(-128, 16); -- cos(120) * 256
    constant COS_125 : signed(15 downto 0) := to_signed(-147, 16); -- cos(125) * 256
    constant COS_130 : signed(15 downto 0) := to_signed(-165, 16); -- cos(130) * 256
    constant COS_135 : signed(15 downto 0) := to_signed(-181, 16); -- cos(135) * 256
    constant COS_140 : signed(15 downto 0) := to_signed(-196, 16); -- cos(140) * 256
    constant COS_145 : signed(15 downto 0) := to_signed(-210, 16); -- cos(145) * 256
    constant COS_150 : signed(15 downto 0) := to_signed(-222, 16); -- cos(150) * 256
    constant COS_155 : signed(15 downto 0) := to_signed(-232, 16); -- cos(155) * 256
    constant COS_160 : signed(15 downto 0) := to_signed(-241, 16); -- cos(160) * 256
    constant COS_165 : signed(15 downto 0) := to_signed(-247, 16); -- cos(165) * 256
    constant COS_170 : signed(15 downto 0) := to_signed(-252, 16); -- cos(170) * 256
    constant COS_175 : signed(15 downto 0) := to_signed(-255, 16); -- cos(175) * 256
    constant COS_180 : signed(15 downto 0) := to_signed(-256, 16); -- cos(180) * 256
    constant COS_185 : signed(15 downto 0) := to_signed(-255, 16); -- cos(185) * 256
    constant COS_190 : signed(15 downto 0) := to_signed(-252, 16); -- cos(190) * 256
    constant COS_195 : signed(15 downto 0) := to_signed(-247, 16); -- cos(195) * 256
    constant COS_200 : signed(15 downto 0) := to_signed(-241, 16); -- cos(200) * 256
    constant COS_205 : signed(15 downto 0) := to_signed(-232, 16); -- cos(205) * 256
    constant COS_210 : signed(15 downto 0) := to_signed(-222, 16); -- cos(210) * 256
    constant COS_215 : signed(15 downto 0) := to_signed(-210, 16); -- cos(215) * 256
    constant COS_220 : signed(15 downto 0) := to_signed(-196, 16); -- cos(220) * 256
    constant COS_225 : signed(15 downto 0) := to_signed(-181, 16); -- cos(225) * 256
    constant COS_230 : signed(15 downto 0) := to_signed(-165, 16); -- cos(230) * 256
    constant COS_235 : signed(15 downto 0) := to_signed(-147, 16); -- cos(235) * 256
    constant COS_240 : signed(15 downto 0) := to_signed(-128, 16); -- cos(240) * 256
    constant COS_245 : signed(15 downto 0) := to_signed(-108, 16); -- cos(245) * 256
    constant COS_250 : signed(15 downto 0) := to_signed( -88, 16); -- cos(250) * 256
    constant COS_255 : signed(15 downto 0) := to_signed( -66, 16); -- cos(255) * 256
    constant COS_260 : signed(15 downto 0) := to_signed( -44, 16); -- cos(260) * 256
    constant COS_265 : signed(15 downto 0) := to_signed( -22, 16); -- cos(265) * 256
    constant COS_270 : signed(15 downto 0) := to_signed(   0, 16); -- cos(270) * 256
    constant COS_275 : signed(15 downto 0) := to_signed(  22, 16); -- cos(275) * 256
    constant COS_280 : signed(15 downto 0) := to_signed(  44, 16); -- cos(280) * 256
    constant COS_285 : signed(15 downto 0) := to_signed(  66, 16); -- cos(285) * 256
    constant COS_290 : signed(15 downto 0) := to_signed(  88, 16); -- cos(290) * 256
    constant COS_295 : signed(15 downto 0) := to_signed( 108, 16); -- cos(295) * 256
    constant COS_300 : signed(15 downto 0) := to_signed( 128, 16); -- cos(300) * 256
    constant COS_305 : signed(15 downto 0) := to_signed( 147, 16); -- cos(305) * 256
    constant COS_310 : signed(15 downto 0) := to_signed( 165, 16); -- cos(310) * 256
    constant COS_315 : signed(15 downto 0) := to_signed( 181, 16); -- cos(315) * 256
    constant COS_320 : signed(15 downto 0) := to_signed( 196, 16); -- cos(320) * 256
    constant COS_325 : signed(15 downto 0) := to_signed( 210, 16); -- cos(325) * 256
    constant COS_330 : signed(15 downto 0) := to_signed( 222, 16); -- cos(330) * 256
    constant COS_335 : signed(15 downto 0) := to_signed( 232, 16); -- cos(335) * 256
    constant COS_340 : signed(15 downto 0) := to_signed( 241, 16); -- cos(340) * 256
    constant COS_345 : signed(15 downto 0) := to_signed( 247, 16); -- cos(345) * 256
    constant COS_350 : signed(15 downto 0) := to_signed( 252, 16); -- cos(350) * 256
    constant COS_355 : signed(15 downto 0) := to_signed( 255, 16); -- cos(355) * 256
    constant COS_360 : signed(15 downto 0) := to_signed( 256, 16); -- cos(360) * 256

    constant SIN_0 : signed(15 downto 0) := to_signed(   0, 16); -- sin(0°) * 2566
    constant SIN_5   : signed(15 downto 0) := to_signed(  22, 16); -- sin(5°)   * 256
    constant SIN_10  : signed(15 downto 0) := to_signed(  44, 16); -- sin(10°)  * 256
    constant SIN_15  : signed(15 downto 0) := to_signed(  66, 16); -- sin(15°)  * 256
    constant SIN_20  : signed(15 downto 0) := to_signed(  88, 16); -- sin(20°)  * 256
    constant SIN_25  : signed(15 downto 0) := to_signed( 108, 16); -- sin(25°)  * 256
    constant SIN_30  : signed(15 downto 0) := to_signed( 128, 16); -- sin(30°)  * 256
    constant SIN_35  : signed(15 downto 0) := to_signed( 147, 16); -- sin(35°)  * 256
    constant SIN_40  : signed(15 downto 0) := to_signed( 165, 16); -- sin(40°)  * 256
    constant SIN_45  : signed(15 downto 0) := to_signed( 181, 16); -- sin(45°)  * 256
    constant SIN_50  : signed(15 downto 0) := to_signed( 196, 16); -- sin(50°)  * 256
    constant SIN_55  : signed(15 downto 0) := to_signed( 210, 16); -- sin(55°)  * 256
    constant SIN_60  : signed(15 downto 0) := to_signed( 222, 16); -- sin(60°)  * 256
    constant SIN_65  : signed(15 downto 0) := to_signed( 232, 16); -- sin(65°)  * 256
    constant SIN_70  : signed(15 downto 0) := to_signed( 241, 16); -- sin(70°)  * 256
    constant SIN_75  : signed(15 downto 0) := to_signed( 247, 16); -- sin(75°)  * 256
    constant SIN_80  : signed(15 downto 0) := to_signed( 252, 16); -- sin(80°)  * 256
    constant SIN_85  : signed(15 downto 0) := to_signed( 255, 16); -- sin(85°)  * 256
    constant SIN_90  : signed(15 downto 0) := to_signed( 256, 16); -- sin(90°)  * 256
    constant SIN_95  : signed(15 downto 0) := to_signed( 255, 16); -- sin(95°)  * 256
    constant SIN_100 : signed(15 downto 0) := to_signed( 252, 16); -- sin(100°) * 256
    constant SIN_105 : signed(15 downto 0) := to_signed( 247, 16); -- sin(105°) * 256
    constant SIN_110 : signed(15 downto 0) := to_signed( 241, 16); -- sin(110°) * 256
    constant SIN_115 : signed(15 downto 0) := to_signed( 232, 16); -- sin(115°) * 256
    constant SIN_120 : signed(15 downto 0) := to_signed( 222, 16); -- sin(120°) * 256
    constant SIN_125 : signed(15 downto 0) := to_signed( 210, 16); -- sin(125°) * 256
    constant SIN_130 : signed(15 downto 0) := to_signed( 196, 16); -- sin(130°) * 256
    constant SIN_135 : signed(15 downto 0) := to_signed( 181, 16); -- sin(135°) * 256
    constant SIN_140 : signed(15 downto 0) := to_signed( 165, 16); -- sin(140°) * 256
    constant SIN_145 : signed(15 downto 0) := to_signed( 147, 16); -- sin(145°) * 256
    constant SIN_150 : signed(15 downto 0) := to_signed( 128, 16); -- sin(150°) * 256
    constant SIN_155 : signed(15 downto 0) := to_signed( 108, 16); -- sin(155°) * 256
    constant SIN_160 : signed(15 downto 0) := to_signed(  88, 16); -- sin(160°) * 256
    constant SIN_165 : signed(15 downto 0) := to_signed(  66, 16); -- sin(165°) * 256
    constant SIN_170 : signed(15 downto 0) := to_signed(  44, 16); -- sin(170°) * 256
    constant SIN_175 : signed(15 downto 0) := to_signed(  22, 16); -- sin(175°) * 256
    constant SIN_180 : signed(15 downto 0) := to_signed(   0, 16); -- sin(180°) * 256
    constant SIN_185 : signed(15 downto 0) := to_signed( -22, 16); -- sin(185°) * 256
    constant SIN_190 : signed(15 downto 0) := to_signed( -44, 16); -- sin(190°) * 256
    constant SIN_195 : signed(15 downto 0) := to_signed( -66, 16); -- sin(195°) * 256
    constant SIN_200 : signed(15 downto 0) := to_signed( -88, 16); -- sin(200°) * 256
    constant SIN_205 : signed(15 downto 0) := to_signed(-108, 16); -- sin(205°) * 256
    constant SIN_210 : signed(15 downto 0) := to_signed(-128, 16); -- sin(210°) * 256
    constant SIN_215 : signed(15 downto 0) := to_signed(-147, 16); -- sin(215°) * 256
    constant SIN_220 : signed(15 downto 0) := to_signed(-165, 16); -- sin(220°) * 256
    constant SIN_225 : signed(15 downto 0) := to_signed(-181, 16); -- sin(225°) * 256
    constant SIN_230 : signed(15 downto 0) := to_signed(-196, 16); -- sin(230°) * 256
    constant SIN_235 : signed(15 downto 0) := to_signed(-210, 16); -- sin(235°) * 256
    constant SIN_240 : signed(15 downto 0) := to_signed(-222, 16); -- sin(240°) * 256
    constant SIN_245 : signed(15 downto 0) := to_signed(-232, 16); -- sin(245°) * 256
    constant SIN_250 : signed(15 downto 0) := to_signed(-241, 16); -- sin(250°) * 256
    constant SIN_255 : signed(15 downto 0) := to_signed(-247, 16); -- sin(255°) * 256
    constant SIN_260 : signed(15 downto 0) := to_signed(-252, 16); -- sin(260°) * 256
    constant SIN_265 : signed(15 downto 0) := to_signed(-255, 16); -- sin(265°) * 256
    constant SIN_270 : signed(15 downto 0) := to_signed(-256, 16); -- sin(270°) * 256
    constant SIN_275 : signed(15 downto 0) := to_signed(-255, 16); -- sin(275°) * 256
    constant SIN_280 : signed(15 downto 0) := to_signed(-252, 16); -- sin(280°) * 256
    constant SIN_285 : signed(15 downto 0) := to_signed(-247, 16); -- sin(285°) * 256
    constant SIN_290 : signed(15 downto 0) := to_signed(-241, 16); -- sin(290°) * 256
    constant SIN_295 : signed(15 downto 0) := to_signed(-232, 16); -- sin(295°) * 256
    constant SIN_300 : signed(15 downto 0) := to_signed(-222, 16); -- sin(300°) * 256
    constant SIN_305 : signed(15 downto 0) := to_signed(-210, 16); -- sin(305°) * 256
    constant SIN_310 : signed(15 downto 0) := to_signed(-196, 16); -- sin(310°) * 256
    constant SIN_315 : signed(15 downto 0) := to_signed(-181, 16); -- sin(315°) * 256
    constant SIN_320 : signed(15 downto 0) := to_signed(-165, 16); -- sin(320°) * 256
    constant SIN_325 : signed(15 downto 0) := to_signed(-147, 16); -- sin(325°) * 256
    constant SIN_330 : signed(15 downto 0) := to_signed(-128, 16); -- sin(330°) * 256
    constant SIN_335 : signed(15 downto 0) := to_signed(-108, 16); -- sin(335°) * 256
    constant SIN_340 : signed(15 downto 0) := to_signed( -88, 16); -- sin(340°) * 256
    constant SIN_345 : signed(15 downto 0) := to_signed( -66, 16); -- sin(345°) * 256
    constant SIN_350 : signed(15 downto 0) := to_signed( -44, 16); -- sin(350°) * 256
    constant SIN_355 : signed(15 downto 0) := to_signed( -22, 16); -- sin(355°) * 256
    constant SIN_360 : signed(15 downto 0) := to_signed(   0, 16); -- sin(360°) * 256
    
    signal z_angle_cos : signed(15 downto 0) := (others => '0');
    signal z_angle_sin : signed(15 downto 0) := (others => '0');
    signal y_angle_cos : signed(15 downto 0) := (others => '0');
    signal y_angle_sin : signed(15 downto 0) := (others => '0');
    signal x_angle_cos : signed(15 downto 0) := (others => '0');
    signal x_angle_sin : signed(15 downto 0) := (others => '0');
   
    signal addr         : unsigned(13 downto 0) := (others => '0');
    signal rotating     : std_logic := '0';
    signal triggered    : std_logic := '0';
    signal dones        : std_logic := '0';
    
    signal z_rotate     : integer := 0;
    signal y_rotate     : integer := 0;
    signal x_rotate     : integer := 0;
    
    

    -- Pipeline stage registers
    signal x, y, z          : signed(15 downto 0);
    signal x_ext, y_ext, z_ext     : signed(31 downto 0);
    signal x_cos, y_sin, z_sin     : signed(47 downto 0);
    signal y_cos, x_sin, z_cos     : signed(47 downto 0);
    
    signal y_finalx, z_finalx, x_finaly, z_finaly, x_finalz, y_finalz   : signed(15 downto 0);
    signal y_rotx, z_rotx, x_roty, z_roty, x_rotz, y_rotz : signed(47 downto 0);
    signal rotatedx, rotatedy : std_logic_vector(47 downto 0);
    
    signal stage            : integer range 0 to 23 := 0;
    signal counter          : integer range 0 to 10 := 0;
begin

    process(clk)
        variable new_x, new_y, new_z : integer;
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
                x_rotate <= 0;
                y_rotate <= 0;
                z_rotate <= 0;
            elsif enable = '1' and (key_in = "1010" or key_in = "1011" or key_in = "1100" or key_in = "0011" or key_in = "0110" or key_in = "1001" or key_in = "1101") and rotating = '0' and dones = '0' and triggered = '0' then
    
                new_x := x_rotate;
                new_y := y_rotate;
                new_z := z_rotate;
    
                -- axis stepping
                if   key_in = "1010" then
                    new_z := new_z + 5;
                elsif key_in = "1011" then
                    new_y := new_y + 5;
                elsif key_in = "1100" then
                    new_x := new_x + 5;
                elsif key_in = "0011" then
                    new_z := new_z - 5;
                elsif key_in = "0110" then
                    new_y := new_y - 5;
                elsif key_in = "1001" then
                    new_x := new_x - 5;
                elsif key_in = "1101" then
                    new_x := 0;
                    new_y := 0;
                    new_z := 0;   
                end if;
    
                --wrapping around
                if   new_z > 360 then
                    new_z := 5;
                elsif new_z < 0 then
                    new_z := 355;
                end if;
    
                if   new_y > 360 then
                    new_y := 5;
                elsif new_y < 0 then
                    new_y := 355;
                end if;
    
                if   new_x > 360 then
                    new_x := 5;
                elsif new_x < 0 then
                    new_x := 355;
                end if;
    
                --updating signals
                x_rotate <= new_x;
                y_rotate <= new_y;
                z_rotate <= new_z;
    
                rotating  <= '1';
                triggered <= '1';
                addr      <= (others => '0');
                stage     <= 0;
                dones     <= '0';
            elsif enable = '0' then
                triggered <= '0';
            elsif rotating = '1' then
                case stage is
                    when 0 =>  --selecting z angle val
                        case z_rotate is
                            when 0   =>
                                z_angle_cos <= COS_0;
                                z_angle_sin <= SIN_0;
                            when 5   =>
                                z_angle_cos <= COS_5;
                                z_angle_sin <= SIN_5;
                            when 10  =>
                                z_angle_cos <= COS_10;
                                z_angle_sin <= SIN_10;
                            when 15  =>
                                z_angle_cos <= COS_15;
                                z_angle_sin <= SIN_15;
                            when 20  =>
                                z_angle_cos <= COS_20;
                                z_angle_sin <= SIN_20;
                            when 25  =>
                                z_angle_cos <= COS_25;
                                z_angle_sin <= SIN_25;
                            when 30  =>
                                z_angle_cos <= COS_30;
                                z_angle_sin <= SIN_30;
                            when 35  =>
                                z_angle_cos <= COS_35;
                                z_angle_sin <= SIN_35;
                            when 40  =>
                                z_angle_cos <= COS_40;
                                z_angle_sin <= SIN_40;
                            when 45  =>
                                z_angle_cos <= COS_45;
                                z_angle_sin <= SIN_45;
                            when 50  =>
                                z_angle_cos <= COS_50;
                                z_angle_sin <= SIN_50;
                            when 55  =>
                                z_angle_cos <= COS_55;
                                z_angle_sin <= SIN_55;
                            when 60  =>
                                z_angle_cos <= COS_60;
                                z_angle_sin <= SIN_60;
                            when 65  =>
                                z_angle_cos <= COS_65;
                                z_angle_sin <= SIN_65;
                            when 70  =>
                                z_angle_cos <= COS_70;
                                z_angle_sin <= SIN_70;
                            when 75  =>
                                z_angle_cos <= COS_75;
                                z_angle_sin <= SIN_75;
                            when 80  =>
                                z_angle_cos <= COS_80;
                                z_angle_sin <= SIN_80;
                            when 85  =>
                                z_angle_cos <= COS_85;
                                z_angle_sin <= SIN_85;
                            when 90  =>
                                z_angle_cos <= COS_90;
                                z_angle_sin <= SIN_90;
                            when 95  =>
                                z_angle_cos <= COS_95;
                                z_angle_sin <= SIN_95;
                            when 100 =>
                                z_angle_cos <= COS_100;
                                z_angle_sin <= SIN_100;
                            when 105 =>
                                z_angle_cos <= COS_105;
                                z_angle_sin <= SIN_105;
                            when 110 =>
                                z_angle_cos <= COS_110;
                                z_angle_sin <= SIN_110;
                            when 115 =>
                                z_angle_cos <= COS_115;
                                z_angle_sin <= SIN_115;
                            when 120 =>
                                z_angle_cos <= COS_120;
                                z_angle_sin <= SIN_120;
                            when 125 =>
                                z_angle_cos <= COS_125;
                                z_angle_sin <= SIN_125;
                            when 130 =>
                                z_angle_cos <= COS_130;
                                z_angle_sin <= SIN_130;
                            when 135 =>
                                z_angle_cos <= COS_135;
                                z_angle_sin <= SIN_135;
                            when 140 =>
                                z_angle_cos <= COS_140;
                                z_angle_sin <= SIN_140;
                            when 145 =>
                                z_angle_cos <= COS_145;
                                z_angle_sin <= SIN_145;
                            when 150 =>
                                z_angle_cos <= COS_150;
                                z_angle_sin <= SIN_150;
                            when 155 =>
                                z_angle_cos <= COS_155;
                                z_angle_sin <= SIN_155;
                            when 160 =>
                                z_angle_cos <= COS_160;
                                z_angle_sin <= SIN_160;
                            when 165 =>
                                z_angle_cos <= COS_165;
                                z_angle_sin <= SIN_165;
                            when 170 =>
                                z_angle_cos <= COS_170;
                                z_angle_sin <= SIN_170;
                            when 175 =>
                                z_angle_cos <= COS_175;
                                z_angle_sin <= SIN_175;
                            when 180 =>
                                z_angle_cos <= COS_180;
                                z_angle_sin <= SIN_180;
                            when 185 =>
                                z_angle_cos <= COS_185;
                                z_angle_sin <= SIN_185;
                            when 190 =>
                                z_angle_cos <= COS_190;
                                z_angle_sin <= SIN_190;
                            when 195 =>
                                z_angle_cos <= COS_195;
                                z_angle_sin <= SIN_195;
                            when 200 =>
                                z_angle_cos <= COS_200;
                                z_angle_sin <= SIN_200;
                            when 205 =>
                                z_angle_cos <= COS_205;
                                z_angle_sin <= SIN_205;
                            when 210 =>
                                z_angle_cos <= COS_210;
                                z_angle_sin <= SIN_210;
                            when 215 =>
                                z_angle_cos <= COS_215;
                                z_angle_sin <= SIN_215;
                            when 220 =>
                                z_angle_cos <= COS_220;
                                z_angle_sin <= SIN_220;
                            when 225 =>
                                z_angle_cos <= COS_225;
                                z_angle_sin <= SIN_225;
                            when 230 =>
                                z_angle_cos <= COS_230;
                                z_angle_sin <= SIN_230;
                            when 235 =>
                                z_angle_cos <= COS_235;
                                z_angle_sin <= SIN_235;
                            when 240 =>
                                z_angle_cos <= COS_240;
                                z_angle_sin <= SIN_240;
                            when 245 =>
                                z_angle_cos <= COS_245;
                                z_angle_sin <= SIN_245;
                            when 250 =>
                                z_angle_cos <= COS_250;
                                z_angle_sin <= SIN_250;
                            when 255 =>
                                z_angle_cos <= COS_255;
                                z_angle_sin <= SIN_255;
                            when 260 =>
                                z_angle_cos <= COS_260;
                                z_angle_sin <= SIN_260;
                            when 265 =>
                                z_angle_cos <= COS_265;
                                z_angle_sin <= SIN_265;
                            when 270 =>
                                z_angle_cos <= COS_270;
                                z_angle_sin <= SIN_270;
                            when 275 =>
                                z_angle_cos <= COS_275;
                                z_angle_sin <= SIN_275;
                            when 280 =>
                                z_angle_cos <= COS_280;
                                z_angle_sin <= SIN_280;
                            when 285 =>
                                z_angle_cos <= COS_285;
                                z_angle_sin <= SIN_285;
                            when 290 =>
                                z_angle_cos <= COS_290;
                                z_angle_sin <= SIN_290;
                            when 295 =>
                                z_angle_cos <= COS_295;
                                z_angle_sin <= SIN_295;
                            when 300 =>
                                z_angle_cos <= COS_300;
                                z_angle_sin <= SIN_300;
                            when 305 =>
                                z_angle_cos <= COS_305;
                                z_angle_sin <= SIN_305;
                            when 310 =>
                                z_angle_cos <= COS_310;
                                z_angle_sin <= SIN_310;
                            when 315 =>
                                z_angle_cos <= COS_315;
                                z_angle_sin <= SIN_315;
                            when 320 =>
                                z_angle_cos <= COS_320;
                                z_angle_sin <= SIN_320;
                            when 325 =>
                                z_angle_cos <= COS_325;
                                z_angle_sin <= SIN_325;
                            when 330 =>
                                z_angle_cos <= COS_330;
                                z_angle_sin <= SIN_330;
                            when 335 =>
                                z_angle_cos <= COS_335;
                                z_angle_sin <= SIN_335;
                            when 340 =>
                                z_angle_cos <= COS_340;
                                z_angle_sin <= SIN_340;
                            when 345 =>
                                z_angle_cos <= COS_345;
                                z_angle_sin <= SIN_345;
                            when 350 =>
                                z_angle_cos <= COS_350;
                                z_angle_sin <= SIN_350;
                            when 355 =>
                                z_angle_cos <= COS_355;
                                z_angle_sin <= SIN_355;
                            when 360 =>
                                z_angle_cos <= COS_360;
                                z_angle_sin <= SIN_360;
                            when others =>
                                z_angle_cos <= COS_0;
                                z_angle_sin <= SIN_0;
                        end case;
                        
                        stage <= 1;

                    when 1 =>
                        -- Y axis
                        case y_rotate is
                            when 0   =>
                                y_angle_cos <= COS_0;   y_angle_sin <= SIN_0;
                            when 5   =>
                                y_angle_cos <= COS_5;   y_angle_sin <= SIN_5;
                            when 10  =>
                                y_angle_cos <= COS_10;  y_angle_sin <= SIN_10;
                            when 15  =>
                                y_angle_cos <= COS_15;  y_angle_sin <= SIN_15;
                            when 20  =>
                                y_angle_cos <= COS_20;  y_angle_sin <= SIN_20;
                            when 25  =>
                                y_angle_cos <= COS_25;  y_angle_sin <= SIN_25;
                            when 30  =>
                                y_angle_cos <= COS_30;  y_angle_sin <= SIN_30;
                            when 35  =>
                                y_angle_cos <= COS_35;  y_angle_sin <= SIN_35;
                            when 40  =>
                                y_angle_cos <= COS_40;  y_angle_sin <= SIN_40;
                            when 45  =>
                                y_angle_cos <= COS_45;  y_angle_sin <= SIN_45;
                            when 50  =>
                                y_angle_cos <= COS_50;  y_angle_sin <= SIN_50;
                            when 55  =>
                                y_angle_cos <= COS_55;  y_angle_sin <= SIN_55;
                            when 60  =>
                                y_angle_cos <= COS_60;  y_angle_sin <= SIN_60;
                            when 65  =>
                                y_angle_cos <= COS_65;  y_angle_sin <= SIN_65;
                            when 70  =>
                                y_angle_cos <= COS_70;  y_angle_sin <= SIN_70;
                            when 75  =>
                                y_angle_cos <= COS_75;  y_angle_sin <= SIN_75;
                            when 80  =>
                                y_angle_cos <= COS_80;  y_angle_sin <= SIN_80;
                            when 85  =>
                                y_angle_cos <= COS_85;  y_angle_sin <= SIN_85;
                            when 90  =>
                                y_angle_cos <= COS_90;  y_angle_sin <= SIN_90;
                            when 95  =>
                                y_angle_cos <= COS_95;  y_angle_sin <= SIN_95;
                            when 100 =>
                                y_angle_cos <= COS_100; y_angle_sin <= SIN_100;
                            when 105 =>
                                y_angle_cos <= COS_105; y_angle_sin <= SIN_105;
                            when 110 =>
                                y_angle_cos <= COS_110; y_angle_sin <= SIN_110;
                            when 115 =>
                                y_angle_cos <= COS_115; y_angle_sin <= SIN_115;
                            when 120 =>
                                y_angle_cos <= COS_120; y_angle_sin <= SIN_120;
                            when 125 =>
                                y_angle_cos <= COS_125; y_angle_sin <= SIN_125;
                            when 130 =>
                                y_angle_cos <= COS_130; y_angle_sin <= SIN_130;
                            when 135 =>
                                y_angle_cos <= COS_135; y_angle_sin <= SIN_135;
                            when 140 =>
                                y_angle_cos <= COS_140; y_angle_sin <= SIN_140;
                            when 145 =>
                                y_angle_cos <= COS_145; y_angle_sin <= SIN_145;
                            when 150 =>
                                y_angle_cos <= COS_150; y_angle_sin <= SIN_150;
                            when 155 =>
                                y_angle_cos <= COS_155; y_angle_sin <= SIN_155;
                            when 160 =>
                                y_angle_cos <= COS_160; y_angle_sin <= SIN_160;
                            when 165 =>
                                y_angle_cos <= COS_165; y_angle_sin <= SIN_165;
                            when 170 =>
                                y_angle_cos <= COS_170; y_angle_sin <= SIN_170;
                            when 175 =>
                                y_angle_cos <= COS_175; y_angle_sin <= SIN_175;
                            when 180 =>
                                y_angle_cos <= COS_180; y_angle_sin <= SIN_180;
                            when 185 =>
                                y_angle_cos <= COS_185; y_angle_sin <= SIN_185;
                            when 190 =>
                                y_angle_cos <= COS_190; y_angle_sin <= SIN_190;
                            when 195 =>
                                y_angle_cos <= COS_195; y_angle_sin <= SIN_195;
                            when 200 =>
                                y_angle_cos <= COS_200; y_angle_sin <= SIN_200;
                            when 205 =>
                                y_angle_cos <= COS_205; y_angle_sin <= SIN_205;
                            when 210 =>
                                y_angle_cos <= COS_210; y_angle_sin <= SIN_210;
                            when 215 =>
                                y_angle_cos <= COS_215; y_angle_sin <= SIN_215;
                            when 220 =>
                                y_angle_cos <= COS_220; y_angle_sin <= SIN_220;
                            when 225 =>
                                y_angle_cos <= COS_225; y_angle_sin <= SIN_225;
                            when 230 =>
                                y_angle_cos <= COS_230; y_angle_sin <= SIN_230;
                            when 235 =>
                                y_angle_cos <= COS_235; y_angle_sin <= SIN_235;
                            when 240 =>
                                y_angle_cos <= COS_240; y_angle_sin <= SIN_240;
                            when 245 =>
                                y_angle_cos <= COS_245; y_angle_sin <= SIN_245;
                            when 250 =>
                                y_angle_cos <= COS_250; y_angle_sin <= SIN_250;
                            when 255 =>
                                y_angle_cos <= COS_255; y_angle_sin <= SIN_255;
                            when 260 =>
                                y_angle_cos <= COS_260; y_angle_sin <= SIN_260;
                            when 265 =>
                                y_angle_cos <= COS_265; y_angle_sin <= SIN_265;
                            when 270 =>
                                y_angle_cos <= COS_270; y_angle_sin <= SIN_270;
                            when 275 =>
                                y_angle_cos <= COS_275; y_angle_sin <= SIN_275;
                            when 280 =>
                                y_angle_cos <= COS_280; y_angle_sin <= SIN_280;
                            when 285 =>
                                y_angle_cos <= COS_285; y_angle_sin <= SIN_285;
                            when 290 =>
                                y_angle_cos <= COS_290; y_angle_sin <= SIN_290;
                            when 295 =>
                                y_angle_cos <= COS_295; y_angle_sin <= SIN_295;
                            when 300 =>
                                y_angle_cos <= COS_300; y_angle_sin <= SIN_300;
                            when 305 =>
                                y_angle_cos <= COS_305; y_angle_sin <= SIN_305;
                            when 310 =>
                                y_angle_cos <= COS_310; y_angle_sin <= SIN_310;
                            when 315 =>
                                y_angle_cos <= COS_315; y_angle_sin <= SIN_315;
                            when 320 =>
                                y_angle_cos <= COS_320; y_angle_sin <= SIN_320;
                            when 325 =>
                                y_angle_cos <= COS_325; y_angle_sin <= SIN_325;
                            when 330 =>
                                y_angle_cos <= COS_330; y_angle_sin <= SIN_330;
                            when 335 =>
                                y_angle_cos <= COS_335; y_angle_sin <= SIN_335;
                            when 340 =>
                                y_angle_cos <= COS_340; y_angle_sin <= SIN_340;
                            when 345 =>
                                y_angle_cos <= COS_345; y_angle_sin <= SIN_345;
                            when 350 =>
                                y_angle_cos <= COS_350; y_angle_sin <= SIN_350;
                            when 355 =>
                                y_angle_cos <= COS_355; y_angle_sin <= SIN_355;
                            when 360 =>
                                y_angle_cos <= COS_360; y_angle_sin <= SIN_360;
                            when others =>
                                y_angle_cos <= COS_0;   y_angle_sin <= SIN_0;
                        end case;
                        
                        stage <= 2;
                    
                    when 2 =>
                        -- X axis
                        case x_rotate is
                            when 0   =>
                                x_angle_cos <= COS_0;   x_angle_sin <= SIN_0;
                            when 5   =>
                                x_angle_cos <= COS_5;   x_angle_sin <= SIN_5;
                            when 10  =>
                                x_angle_cos <= COS_10;  x_angle_sin <= SIN_10;
                            when 15  =>
                                x_angle_cos <= COS_15;  x_angle_sin <= SIN_15;
                            when 20  =>
                                x_angle_cos <= COS_20;  x_angle_sin <= SIN_20;
                            when 25  =>
                                x_angle_cos <= COS_25;  x_angle_sin <= SIN_25;
                            when 30  =>
                                x_angle_cos <= COS_30;  x_angle_sin <= SIN_30;
                            when 35  =>
                                x_angle_cos <= COS_35;  x_angle_sin <= SIN_35;
                            when 40  =>
                                x_angle_cos <= COS_40;  x_angle_sin <= SIN_40;
                            when 45  =>
                                x_angle_cos <= COS_45;  x_angle_sin <= SIN_45;
                            when 50  =>
                                x_angle_cos <= COS_50;  x_angle_sin <= SIN_50;
                            when 55  =>
                                x_angle_cos <= COS_55;  x_angle_sin <= SIN_55;
                            when 60  =>
                                x_angle_cos <= COS_60;  x_angle_sin <= SIN_60;
                            when 65  =>
                                x_angle_cos <= COS_65;  x_angle_sin <= SIN_65;
                            when 70  =>
                                x_angle_cos <= COS_70;  x_angle_sin <= SIN_70;
                            when 75  =>
                                x_angle_cos <= COS_75;  x_angle_sin <= SIN_75;
                            when 80  =>
                                x_angle_cos <= COS_80;  x_angle_sin <= SIN_80;
                            when 85  =>
                                x_angle_cos <= COS_85;  x_angle_sin <= SIN_85;
                            when 90  =>
                                x_angle_cos <= COS_90;  x_angle_sin <= SIN_90;
                            when 95  =>
                                x_angle_cos <= COS_95;  x_angle_sin <= SIN_95;
                            when 100 =>
                                x_angle_cos <= COS_100; x_angle_sin <= SIN_100;
                            when 105 =>
                                x_angle_cos <= COS_105; x_angle_sin <= SIN_105;
                            when 110 =>
                                x_angle_cos <= COS_110; x_angle_sin <= SIN_110;
                            when 115 =>
                                x_angle_cos <= COS_115; x_angle_sin <= SIN_115;
                            when 120 =>
                                x_angle_cos <= COS_120; x_angle_sin <= SIN_120;
                            when 125 =>
                                x_angle_cos <= COS_125; x_angle_sin <= SIN_125;
                            when 130 =>
                                x_angle_cos <= COS_130; x_angle_sin <= SIN_130;
                            when 135 =>
                                x_angle_cos <= COS_135; x_angle_sin <= SIN_135;
                            when 140 =>
                                x_angle_cos <= COS_140; x_angle_sin <= SIN_140;
                            when 145 =>
                                x_angle_cos <= COS_145; x_angle_sin <= SIN_145;
                            when 150 =>
                                x_angle_cos <= COS_150; x_angle_sin <= SIN_150;
                            when 155 =>
                                x_angle_cos <= COS_155; x_angle_sin <= SIN_155;
                            when 160 =>
                                x_angle_cos <= COS_160; x_angle_sin <= SIN_160;
                            when 165 =>
                                x_angle_cos <= COS_165; x_angle_sin <= SIN_165;
                            when 170 =>
                                x_angle_cos <= COS_170; x_angle_sin <= SIN_170;
                            when 175 =>
                                x_angle_cos <= COS_175; x_angle_sin <= SIN_175;
                            when 180 =>
                                x_angle_cos <= COS_180; x_angle_sin <= SIN_180;
                            when 185 =>
                                x_angle_cos <= COS_185; x_angle_sin <= SIN_185;
                            when 190 =>
                                x_angle_cos <= COS_190; x_angle_sin <= SIN_190;
                            when 195 =>
                                x_angle_cos <= COS_195; x_angle_sin <= SIN_195;
                            when 200 =>
                                x_angle_cos <= COS_200; x_angle_sin <= SIN_200;
                            when 205 =>
                                x_angle_cos <= COS_205; x_angle_sin <= SIN_205;
                            when 210 =>
                                x_angle_cos <= COS_210; x_angle_sin <= SIN_210;
                            when 215 =>
                                x_angle_cos <= COS_215; x_angle_sin <= SIN_215;
                            when 220 =>
                                x_angle_cos <= COS_220; x_angle_sin <= SIN_220;
                            when 225 =>
                                x_angle_cos <= COS_225; x_angle_sin <= SIN_225;
                            when 230 =>
                                x_angle_cos <= COS_230; x_angle_sin <= SIN_230;
                            when 235 =>
                                x_angle_cos <= COS_235; x_angle_sin <= SIN_235;
                            when 240 =>
                                x_angle_cos <= COS_240; x_angle_sin <= SIN_240;
                            when 245 =>
                                x_angle_cos <= COS_245; x_angle_sin <= SIN_245;
                            when 250 =>
                                x_angle_cos <= COS_250; x_angle_sin <= SIN_250;
                            when 255 =>
                                x_angle_cos <= COS_255; x_angle_sin <= SIN_255;
                            when 260 =>
                                x_angle_cos <= COS_260; x_angle_sin <= SIN_260;
                            when 265 =>
                                x_angle_cos <= COS_265; x_angle_sin <= SIN_265;
                            when 270 =>
                                x_angle_cos <= COS_270; x_angle_sin <= SIN_270;
                            when 275 =>
                                x_angle_cos <= COS_275; x_angle_sin <= SIN_275;
                            when 280 =>
                                x_angle_cos <= COS_280; x_angle_sin <= SIN_280;
                            when 285 =>
                                x_angle_cos <= COS_285; x_angle_sin <= SIN_285;
                            when 290 =>
                                x_angle_cos <= COS_290; x_angle_sin <= SIN_290;
                            when 295 =>
                                x_angle_cos <= COS_295; x_angle_sin <= SIN_295;
                            when 300 =>
                                x_angle_cos <= COS_300; x_angle_sin <= SIN_300;
                            when 305 =>
                                x_angle_cos <= COS_305; x_angle_sin <= SIN_305;
                            when 310 =>
                                x_angle_cos <= COS_310; x_angle_sin <= SIN_310;
                            when 315 =>
                                x_angle_cos <= COS_315; x_angle_sin <= SIN_315;
                            when 320 =>
                                x_angle_cos <= COS_320; x_angle_sin <= SIN_320;
                            when 325 =>
                                x_angle_cos <= COS_325; x_angle_sin <= SIN_325;
                            when 330 =>
                                x_angle_cos <= COS_330; x_angle_sin <= SIN_330;
                            when 335 =>
                                x_angle_cos <= COS_335; x_angle_sin <= SIN_335;
                            when 340 =>
                                x_angle_cos <= COS_340; x_angle_sin <= SIN_340;
                            when 345 =>
                                x_angle_cos <= COS_345; x_angle_sin <= SIN_345;
                            when 350 =>
                                x_angle_cos <= COS_350; x_angle_sin <= SIN_350;
                            when 355 =>
                                x_angle_cos <= COS_355; x_angle_sin <= SIN_355;
                            when 360 =>
                                x_angle_cos <= COS_360; x_angle_sin <= SIN_360;
                            when others =>
                                x_angle_cos <= COS_0;   x_angle_sin <= SIN_0;
                        end case;
                        
                        stage <= 3;
                    
                    when 3 =>
                        reading <= '1';
                        stage   <= 4;
                    
                    when 4 =>
                        -- grab the raw point
                        x <= signed(ram_dout(47 downto 32));
                        y <= signed(ram_dout(31 downto 16));
                        z <= signed(ram_dout(15 downto 0));
                        stage <= 5;
                    
                    ------------------------------------------------------------------------------
                    --  X-axis rotation:  Y' = cos_x * Y  -  sin_x * Z
                    --                     Z' = sin_x * Y  +  cos_x * Z
                    ------------------------------------------------------------------------------
                    when 5 =>
                        -- extend to 32 bits for multiply
                        y_ext <= resize(y,32);
                        z_ext <= resize(z,32);
                        stage <= 6;
                    
                    when 6 =>
                        y_cos <= resize(y_ext * resize(x_angle_cos,32),48);
                        y_sin <= resize(y_ext * resize(x_angle_sin,32),48);
                        z_cos <= resize(z_ext * resize(x_angle_cos,32),48);
                        z_sin <= resize(z_ext * resize(x_angle_sin,32),48);

                        stage  <= 7;
                    
                    when 7 =>
                        y_rotx  <= y_cos - z_sin;
                        z_rotx  <= y_sin + z_cos;
                        ram_we <= '1';
                        writing <= '1';
                        ram_waddr <= std_logic_vector(addr);
                        stage  <= 8;
                        
                   when 8 => 
                        
                        y_finalx <= resize(y_rotx(23 downto 8), 16);
                        z_finalx <= resize(z_rotx(23 downto 8), 16);
                        stage <= 9;
                   
                   when 9 =>
                   
                        rotatedx <= std_logic_vector(x & y_finalx & z_finalx);
                        stage <= 10;
                        
                   when 10 =>
                    -------------------------------------------------------------------------------
                    -- Y-axis rotation:  X' = cos_y * X  +  sin_y * Z'
                    --                     Z' = -sin_y * X +  cos_y * Z'
                    -------------------------------------------------------------------------------
                        x <= signed(rotatedx(47 downto 32));
                        y <= signed(rotatedx(31 downto 16));
                        z <= signed(rotatedx(15 downto 0)); 
                        stage <= 11;
                        
                   when 11 =>
                   
                        x_ext <= resize(x, 32);
                        z_ext <= resize(z, 32);
                        stage <= 12;
                   
                   when 12 => 
                        
                        x_cos <= resize(x_ext * resize(y_angle_cos,32),48);
                        x_sin <= resize(x_ext * resize(y_angle_sin,32),48);
                        z_cos <= resize(z_ext * resize(y_angle_cos,32),48);
                        z_sin <= resize(z_ext * resize(y_angle_sin,32),48);
                        stage <= 13;
                   
                   when 13 =>
                   
                        x_roty <= x_cos - z_sin;
                        z_roty <= z_cos - x_sin;
                        stage <= 14;
                        
                   when 14 =>
                        
                        x_finaly <= resize(x_roty(23 downto 8), 16);
                        z_finaly <= resize(z_roty(23 downto 8), 16);
                        stage <= 15;
                        
                   when 15 =>
                   
                        rotatedy <= std_logic_vector(x_finaly & y & z_finaly);
                        stage <= 16;
                        
                   when 16 =>
                   
                        x <= signed(rotatedy(47 downto 32));
                        y <= signed(rotatedy(31 downto 16));
                        z <= signed(rotatedy(15 downto 0)); 
                        stage <= 17;
                        
                   when 17 =>
                    --------------------------------------------------------------------------------
                    --    Z-axis rotation:  X' = cos_z * X'  -  sin_z * Y'
                    --                     Y' = sin_z * X'  +  cos_z * Y'
                    --------------------------------------------------------------------------------
                        x_ext <= resize(x, 32);
                        y_ext <= resize(y, 32);
                        stage <= 18;
                        
                   when 18 =>
                   
                        x_cos <= resize(x_ext * resize(z_angle_cos,32),48);
                        x_sin <= resize(x_ext * resize(z_angle_sin,32),48);
                        y_cos <= resize(y_ext * resize(z_angle_cos,32),48);
                        y_sin <= resize(y_ext * resize(z_angle_sin,32),48);
                        stage <= 19;
                        
                   when 19 =>
                   
                        x_rotz <= x_cos - y_sin;
                        y_rotz <= x_sin + y_cos;
                        stage <= 20;
                                                
                  when 20 =>
                  
                        x_finalz <= resize(x_rotz(23 downto 8), 16);
                        y_finalz <= resize(y_rotz(23 downto 8), 16);
                        stage <= 21;

                    when 21 =>
                        ram_din   <= std_logic_vector(x_finalz & y_finalz & z);
                        if addr = to_unsigned(DEPTH - 1, addr'length) then
                            ram_we  <= '0';
                            stage <= 23;
                        else
                            addr <= addr + 1;
                            stage <= 22;
                        end if;
                        

                    when 22 =>
                        
                        stage <= 4; 
                        
                    when 23 => 
                    
                        if counter < 10 then
                            counter <= counter +1;
                            stage <= 23;
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
