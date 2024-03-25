library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
entity serial_ctrl is
	port(
			received_data   : in std_logic_vector(7 downto 0);
			received_valid  : in std_logic;
			clk 	: in std_logic;
			reset : in std_logic;
			serial_on 	: out std_logic;
			serial_off 	: out std_logic;
			serial_up 	: out std_logic;
			serial_down : out std_logic
			);
end entity serial_ctrl;


architecture rtl of serial_ctrl is

	type t_main_state is ( s_idle, s_pulse );
	signal main_state : t_main_state;

begin

	p_data : process(clk, reset) 
	begin
	
		if reset = '1' then
		
			serial_on	<= '0';
			serial_off	<= '0';
			serial_up	<= '0';
			serial_down	<= '0';
			
			main_state	<= s_idle;
		
		elsif rising_edge(clk) then
		
			case main_state is
			
				when s_idle =>
					serial_on 	<= '0';
					serial_off 	<= '0';
					serial_up 	<= '0';
					serial_down <= '0';
					if received_valid = '1' then
						main_state <= s_pulse;
					end if;
					
				when s_pulse =>
					if received_data = "00110000" then	-- "0"
						serial_off <= '1';
						
					elsif received_data = "01010101" or received_data = "01110101" then	-- "U" or "u"
						serial_up <= '1';
					
					elsif received_data = "01000100" or received_data = "01100100" then	-- "D" or "d"
						serial_down <= '1';
					
					elsif received_data = "00110001" then	-- "1"
						serial_on <= '1';
						
					end if;
					main_state <= s_idle;
					
			end case;
			
		end if;
		
	end process;
	
end architecture;