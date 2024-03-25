library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;


entity dc_disp_ctrl is
port (
	clk					: in std_logic;
	reset					: in std_logic;
	current_dc			: in std_logic_vector(7 downto 0);
	current_dc_update	: in std_logic;
	transmit_ready		: in std_logic;
	transmit_valid		: out std_logic;
	transmit_data		: out std_logic_vector(7 downto 0);
	hex0					: out std_logic_vector(6 downto 0);
	hex1              : out std_logic_vector(6 downto 0);
	hex2					: out std_logic_vector(6 downto 0);
	hex3					: out std_logic_vector(6 downto 0) );
end entity dc_disp_ctrl;
	
architecture rtl of dc_disp_ctrl is

	
component bcd_decode is
	port(
	
	   clk                     : in  std_logic;
      reset                   : in  std_logic;   -- active high reset
      
      -- input data interface
      input_vector            : in  std_logic_vector(7 downto 0);
      valid_in                : in  std_logic;
      ready                   : out std_logic;  -- ready for data when high

      -- output result
      bcd_0                   : out std_logic_vector(3 downto 0); -- ones
      bcd_1                   : out std_logic_vector(3 downto 0); -- tens
      bcd_2                   : out std_logic_vector(3 downto 0); -- hundreds
      valid_out               : out std_logic); -- Set high one clock cycle when bcd* is valid
		
end component bcd_decode;


	-- bcd lab6 singals
	signal bcd_0         :  std_logic_vector(3 downto 0); -- ones
   signal bcd_1         :  std_logic_vector(3 downto 0); -- tens
   signal bcd_2         :  std_logic_vector(3 downto 0); -- hundreds
	
	signal input_vector  : std_logic_vector(7 downto 0);
   signal valid_in      : std_logic;
   signal ready         : std_logic;
	signal valid_out	   : std_logic;

	type t_percent_bcd is array (0 to 100) of std_logic_vector(11 downto 0);
	constant c_percent_bcd : t_percent_bcd 	:= (	"000000000000", "000000000001", "000000000010", "000000000011", "000000000100",
																	"000000000101", "000000000110", "000000000111", "000000001000", "000000001001",
																	
																	"000000010000", "000000010001", "000000010010", "000000010011", "000000010100",
																	"000000010101", "000000010110", "000000010111", "000000011000", "000000011001",
																	
																	"000000100000", "000000100001", "000000100010", "000000100011", "000000100100",
																	"000000100101", "000000100110", "000000100111", "000000101000", "000000101001",
																	
																	"000000110000", "000000110001", "000000110010", "000000110011", "000000110100",
																	"000000110101", "000000110110", "000000110111", "000000111000", "000000111001",
																	
																	"000001000000", "000001000001", "000001000010", "000001000011", "000001000100",
																	"000001000101", "000001000110", "000001000111", "000001001000", "000001001001",
																	
																	"000001010000", "000001010001", "000001010010", "000001010011", "000001010100",
																	"000001010101", "000001010110", "000001010111", "000001011000", "000001011001",
																	
																	"000001100000", "000001100001", "000001100010", "000001100011", "000001100100",
																	"000001100101", "000001100110", "000001100111", "000001101000", "000001101001",
																	
																	"000001110000", "000001110001", "000001110010", "000001110011", "000001110100",
																	"000001110101", "000001110110", "000001110111", "000001111000", "000001111001",
																	
																	"000010000000", "000010000001", "000010000010", "000010000011", "000010000100",
																	"000010000101", "000010000110", "000010000111", "000010001000", "000010001001",
																	
																	"000010010000", "000010010001", "000010010010", "000010010011", "000010010100",
																	"000010010101", "000010010110", "000010010111", "000010011000", "000010011001",
																	
																	"000100000000" );
	
	type t_slv_8bit_arr is array (integer range <>) of std_logic_vector(7 downto 0);

	type t_7seg_numbers is array (9 downto 0) of std_logic_vector(6 downto 0);
	constant c_7seg_numbers : t_7seg_numbers := (	not "1101111",		--pos 9  ”9”
																	not "1111111",		--pos 8  ”8”
																	not "0000111",		--pos 7  ”7”
																	not "1111101",		--pos 6  ”6”
																	not "1101101",		--pos 5  ”5”
																	not "1100110",		--pos 4  ”4”
																	not "1001111",		--pos 3  ”3”
																	not "1011011",		--pos 2  ”2”
																	not "0000110",		--pos 1  ”1”
																	not "0111111" );	--pos 0  ”0”
																	
	constant c_numbers_ascii : t_slv_8bit_arr(0 to 9) := (	"00110000",		-- "0"
																				"00110001",		-- "1"
																				"00110010",		-- "2"
																				"00110011",		-- "3"
																				"00110100",		-- "4"
																				"00110101",		-- "5"
																				"00110110",		-- "6"
																				"00110111",		-- "7"
																				"00111000",		-- "8"
																				"00111001" );	-- "9"
	
	type t_seven_seg_state is (	s_idle,
											s_update );
	
									
	type t_serial_uart_state is (	s_idle,
											s_percent_to_ascii,
											s_send_data,
											s_send_wait );
	
	signal seven_seg_state		: t_seven_seg_state;
	signal serial_uart_state	: t_serial_uart_state;
	
	constant data_width			: natural := 8;
	
	signal ascii_arr				: t_slv_8bit_arr(0 to 4);
	signal ascii_idx				: natural := 0;
	
	signal reset_serial			: std_logic;
	signal send_wait_counter	: natural;
	
	signal current_dc_saved		: std_logic_vector(7 downto 0);
	signal new_dc_available		: std_logic;
	
begin

bcd : bcd_decode
port map(
	
		clk                     => clk,
      reset                   => reset,  -- active high reset
      
      -- input data interface
      input_vector            => input_vector,
      valid_in                => valid_in,
      ready                   => ready,  -- ready for data when high

      -- output result
      bcd_0                   => bcd_0, -- ones
      bcd_1                   => bcd_1, -- tens
      bcd_2                   => bcd_2, -- hundreds
      valid_out               => valid_out); -- Set high one clock cycle when bcd* is valid

		
	p_handle_seven_seg : process(clk, reset)
	begin
	
		if reset = '1' then
		
			seven_seg_state <= s_idle;
			hex0 <= c_7seg_numbers(0);
			hex1 <= c_7seg_numbers(0);
			hex2 <= c_7seg_numbers(0);
			hex3 <= c_7seg_numbers(0);
		
		elsif rising_edge(clk) then
		
			case seven_seg_state is
			
				when s_idle =>
					if current_dc_update = '1' then
						seven_seg_state <= s_update;
					end if;
				
				when s_update =>
				
					hex0 <= c_7seg_numbers(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc))))(3 downto 0))));
					hex1 <= c_7seg_numbers(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc))))(7 downto 4))));
					hex2 <= c_7seg_numbers(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc))))(11 downto 8))));
					seven_seg_state <= s_idle;
					
			end case;
			
		end if;
	
	end process p_handle_seven_seg;

	
	p_serial_uart_transmit : process(clk, reset)
	begin
		
		reset_serial		<= '0';
	
		if reset = '1' then
		
			transmit_valid		<= '0';
			new_dc_available	<= '0';
			
			ascii_idx <= 0;
			send_wait_counter <= 0;
			
			reset_serial <= '1';
		
		elsif rising_edge(clk) then
		
			if current_dc_update = '1' then
				new_dc_available <= '1';
			end if;
		
			case serial_uart_state is
			
				when s_idle =>
					if	transmit_ready = '1' then
						if reset_serial = '1' then
							ascii_arr(0)		<= "00100000";																-- "<space>";
							ascii_arr(1)		<= "00100000";																-- "<space>";
							ascii_arr(2)		<= c_numbers_ascii(to_integer(unsigned(c_percent_bcd(0))));	-- "0"
							ascii_arr(3)		<= "00100101";																-- "%"
							ascii_arr(4)		<= "00001101";																-- "<carriage return>"
							reset_serial		<= '0';
							serial_uart_state <= s_send_data;
							
						elsif new_dc_available = '1' then
							new_dc_available <= '0';
							current_dc_saved <= current_dc;
							serial_uart_state <= s_percent_to_ascii;
							
						end if;
					end if;
				
				when s_percent_to_ascii =>
					if to_integer(unsigned(c_percent_bcd(to_integer(unsigned(current_dc_saved)))(11 downto 8))) = 0 then
						if to_integer(unsigned(c_percent_bcd(to_integer(unsigned(current_dc_saved)))(7 downto 4))) = 0 then
							ascii_arr(0) <= "00100000";	-- "<space>"
							ascii_arr(1) <= "00100000";	-- "<space>"
							ascii_arr(2) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(3 downto 0))));
						else
							ascii_arr(0) <= "00100000";	-- "<space>"
							ascii_arr(1) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(7 downto 4))));
							ascii_arr(2) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(3 downto 0))));
						end if;
					
					else
						ascii_arr(0) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(11 downto 8))));
						ascii_arr(1) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(7 downto 4))));
						ascii_arr(2) <= c_numbers_ascii(to_integer(unsigned(c_percent_bcd((to_integer(unsigned(current_dc_saved))))(3 downto 0))));
					end if;
					ascii_arr(3) <= "00100101";	-- "%"
					ascii_arr(4) <= "00001101";	-- "<carriage return>"
					
					serial_uart_state <= s_send_data;
					
				when s_send_data =>
					transmit_valid <= '1';
					
					if ascii_idx = 5 then
						ascii_idx <= 0;
						transmit_valid <= '0';
						serial_uart_state <= s_idle;
					else
						transmit_data <= ascii_arr(ascii_idx);
						ascii_idx <= ascii_idx + 1;
						serial_uart_state <= s_send_wait;
					end if;
					
				when s_send_wait =>
					transmit_valid <= '0';
					if send_wait_counter = 2 then
						if transmit_ready = '1' then
							send_wait_counter <= 0;
							serial_uart_state <= s_send_data;
						end if;
					else
						send_wait_counter <= send_wait_counter + 1;
					end if;
				
			end case;
			
		end if;
	
	end process p_serial_uart_transmit;

end architecture;