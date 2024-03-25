library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;


entity pwm_ctrl is
port (
	clk					: in std_logic;
	reset					: in std_logic; 
	key_on				: in std_logic;
	key_off				: in std_logic;
	key_up				: in std_logic;
	key_down				: in std_logic;
	serial_on			: in std_logic;
	serial_off			: in std_logic;
	serial_up			: in std_logic;
	serial_down			: in std_logic;
	pwm_output			: out std_logic;
	current_dc			: out std_logic_vector(7 downto 0);
	current_dc_update	: out std_logic );
	
end entity pwm_ctrl;

architecture rtl of pwm_ctrl is
	type t_main_state is (	s_key_on,
									s_key_off,
									s_key_up,
									s_key_down,
									s_serial_on,
									s_serial_off,
									s_serial_up,
									s_serial_down,
									s_waiting );
									
	signal main_state			: t_main_state;
	
	-- Signals for p_main_state
	signal current_dc_int			: natural := 0;
	signal saved_dc					: natural := 100;
	
	-- Signals for p_pwm_control
	constant cnt_max					: natural := 50000-1;
	constant dc_to_compare_scaler	: natural := 500;			-- Calculated by ((cnt_max + 1) / 100)
	signal cnt_compare				: natural := 0;
	signal counter						: natural := 0;
	signal last_compare				: natural := 0;
begin

	current_dc <= std_logic_vector(to_unsigned(current_dc_int, current_dc'length));

	p_main_state : process(clk, reset)
	begin
		
		if reset = '1' then
		
			main_state		<= s_waiting;
			current_dc_int	<= 0;
			saved_dc			<= 100;
		
		elsif rising_edge(clk) then
			
			case main_state is
			
				when s_key_on =>
					main_state <= s_waiting;
					current_dc_int <= saved_dc;
				
				when s_key_off =>
					main_state <= s_waiting;
					current_dc_int <= 0;
					if current_dc_int > 0 then
						saved_dc <= current_dc_int; -- Save only when PWM is on
					end if;
				
				when s_key_up =>
					main_state <= s_waiting;
					if current_dc_int < 100 then
						if current_dc_int < 10 then
							current_dc_int <= 10; -- Set to 10 if off
						else
							current_dc_int <= current_dc_int+1; -- Increment if in range
						end if;
					end if;
				
				when s_key_down =>
					main_state <= s_waiting;
					if current_dc_int > 10 then
						current_dc_int <= current_dc_int - 1; -- Decrement if in range
					end if;
				
				when s_serial_on =>
					main_state <= s_waiting;
					current_dc_int <= saved_dc;
				
				when s_serial_off =>
					main_state <= s_waiting;
					current_dc_int <= 0;
					if current_dc_int > 0 then
						saved_dc <= current_dc_int; -- Save only when PWM is 
					end if;
				
				when s_serial_up =>
					main_state <= s_waiting;
					if current_dc_int < 100 then
						if current_dc_int < 10 then
							current_dc_int <= 10; -- Set to 10 if off
						else
							current_dc_int <= current_dc_int+1; -- Increment if in range
						end if;

					end if;
				
				when s_serial_down =>
					main_state <= s_waiting;
					if current_dc_int > 10 then
						current_dc_int <= current_dc_int-1; -- Decrement if in range
					end if;
				
				when s_waiting =>
					if 	key_off		= '1'	then main_state <= s_key_off;
					elsif key_on		= '1'	then main_state <= s_key_on;
					elsif key_down		= '1'	then main_state <= s_key_down;
					elsif key_up		= '1'	then main_state <= s_key_up;
					elsif serial_off	= '1'	then main_state <= s_serial_off;
					elsif serial_on	= '1'	then main_state <= s_serial_on;
					elsif serial_down	= '1'	then main_state <= s_serial_down;
					elsif serial_up	= '1'	then main_state <= s_serial_up;
					end if;
			end case;
		end if;
	
	end process p_main_state;
	
	p_pwm_control : process(clk, reset)
	begin
		
		if reset = '1' then
		
			counter 				<= 0;
			current_dc_update	<= '0';
			pwm_output			<= '0';
		
		elsif rising_edge(clk) then
			
			if counter < cnt_compare then pwm_output <= '1';
			else									pwm_output <= '0';
			end if;
			current_dc_update	<= '0';
			
			if counter = cnt_max then
			
				counter		<= 0;
				cnt_compare	<= current_dc_int * dc_to_compare_scaler;
				
			else
				counter <= counter + 1;
						end if;
			
			if last_compare /= cnt_compare then
				current_dc_update	<= '1';
				last_compare		<= cnt_compare;
			end if;
		
		end if;
	
	end process p_pwm_control;

end architecture;


