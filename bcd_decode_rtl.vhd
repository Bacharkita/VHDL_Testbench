library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

--=================================================================
--
-- BCD Decode
--
-- Transforms a 7 bit input vector to 3 BCD values.
-- Valid in shall be set high when input_vector is valid.
-- Valid_out shall be set high when transformed data is ready on
-- the bcd_* outputs
--
--=================================================================
entity bcd_decode is
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
end entity bcd_decode;

architecture rtl of bcd_decode is

   -- Types and constants
	
   -- Signals

begin

	BCD_decode : process(clk)
		variable v_input : std_logic_vector(7 downto 0);
		variable v_bcd   : std_logic_vector(11 downto 0);
	begin

		if rising_edge(clk) then
			
			v_input  	:= input_vector ;
			v_bcd    	:= (others => '0');
			
			ready 		<= '1';
			valid_out 	<= valid_in;
			
			for i in 0 to 7 loop
				
				if v_bcd(3 downto 0) > "0100" then
					v_bcd(3 downto 0) := std_logic_vector(unsigned(v_bcd(3 downto 0)) + "0011"); 
				end if;
				
				if v_bcd(7 downto 4) > "0100" then
					v_bcd(7 downto 4) := std_logic_vector(unsigned(v_bcd(7 downto 4)) + "0011");
				end if;
				
				if v_bcd(11 downto 8) > "0100" then
					v_bcd(11 downto 8) := std_logic_vector(unsigned(v_bcd(11 downto 8)) + "0011");
				end if;
				
				v_bcd   := v_bcd(10 downto 0) & v_input(7); 	-- shift bcd + 1 new entry
				v_input := v_input(6 downto 0) & '0';        -- shift input + 0 padding
				
			end loop;
			 
			bcd_0 	<= v_bcd(3 downto 0);
			bcd_1 	<= v_bcd(7  downto 4);
			bcd_2 	<= v_bcd(11  downto 8);
			  
		end if;
	end process;

end architecture rtl;


