library ieee;
use ieee.std_logic_1164.all;

entity key_ctrl is 
port (
	reset 		: in std_logic;
	clk 			:in std_logic;
	key_n 		: in std_logic_vector(3 downto 0);
	key_off 		: out std_logic;
	key_on  		: out std_logic;
	key_up 		: out std_logic;
	key_down  	: out std_logic	
);
end entity key_ctrl;

architecture key_ctrl_rtl of key_ctrl is

constant c_cnt_max : integer := 500000-1;--500000


signal key_off_r : std_logic;
signal key_on_r  : std_logic;
signal key_up_r : std_logic;
signal key_down_r  : std_logic;
signal key_off_2r : std_logic;
signal key_on_2r  : std_logic;
signal key_up_2r : std_logic;
signal key_down_2r  : std_logic;
signal counter : integer range 0 to c_cnt_max;
signal prev : integer range 0 to 4;

begin

--Double Sync

p_double_sync_key : process(clk, reset)
begin	
	if rising_edge(clk) then
		key_off_r <= key_n(0);
		key_off_2r<= key_off_r;
		
		key_on_r <= key_n(1);
		key_on_2r<= key_on_r;
		
		key_down_r <= key_n(2);
		key_down_2r<= key_down_r;

		key_up_r <= key_n(3);
		key_up_2r<= key_up_r;
	end if;
end process p_double_sync_key;

p_key_ctrl : process(clk, reset)
	begin
		if reset = '1' then
			prev <= 4;
		elsif rising_edge(clk) then
			key_off <= '0';
			key_on <= '0';
			key_down <='0';
			key_up <= '0';
			if (key_off_2r = '0') then
				if (prev = 0) then
					if (counter = c_cnt_max) then
						key_off <= '1';    --output
						counter <=0;
					else 
						counter <= counter+1;
					end if;
				else 
					key_off<='1';
					prev<=0;
					counter <=0;
				end if;
			elsif (key_on_2r ='0') then
				if (prev = 1) then
					if (counter =c_cnt_max) then
						key_on <= '1';
						counter <=0;
					else 
						counter <= counter+1;
					end if;
				else 
					key_on<='1';
					prev<=1;
					counter <=0;
				end if;
			elsif (key_down_2r = '0') then 
				if (key_up_2r ='0') then
					--Do Nothing
				else
					if (prev = 2) then
						if (counter =c_cnt_max) then
							key_down <= '1';
							counter<=0;
						else
							counter <= counter+1;
						end if;
					else 
						key_down<='1';
						prev <= 2 ;
						counter <=0;
					end if;
				end if;
			elsif (key_up_2r = '0') then
				if (key_down_2r ='0') then
					--Do Nothing
				else
					if (prev = 3) then
						if (counter = c_cnt_max) then
							key_up <= '1';
							counter <=0;
						else 
							counter <= counter+1;
						end if;
					else 
						key_up<='1';
						prev<=3;
						counter <=0;
					end if;
				end if;
			end if;
		end if;
end process p_key_ctrl;
	
end architecture key_ctrl_rtl;