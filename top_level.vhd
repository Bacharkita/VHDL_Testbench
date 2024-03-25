library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;




entity pwm_module is

generic (
	g_simulation	: boolean := false );
port (
	key_n				: in std_logic_vector(3 downto 0);
	clock_50			: in std_logic;
	fpga_in_rx		: in std_logic;
	fpga_out_tx		: out std_logic;
	ledg				: out std_logic_vector(7 downto 0);
	ledr				: out std_logic_vector(9 downto 0);
	hex0				: out std_logic_vector(6 downto 0);
	hex1				: out std_logic_vector(6 downto 0);
	hex2           : out std_logic_vector(6 downto 0);
	hex3				: out std_logic_vector(6 downto 0));
	
end entity pwm_module;



architecture str of pwm_module is

	-- Signals from pll/reset
	signal reset 					: std_logic;
	signal clk_50					: std_logic;
	signal pll_locked				: std_logic;
	
	-- Signals from key_ctrl
	signal key_on					: std_logic;
	signal key_off					: std_logic;
	signal key_up					: std_logic;
	signal key_down				: std_logic;
	
	-- Signals from serial_uart
	signal received_data			: std_logic_vector(7 downto 0);
	signal received_valid		: std_logic;
	signal transmit_ready		: std_logic;
	signal transmit_valid		: std_logic;
	signal transmit_data			: std_logic_vector(7 downto 0);
	
	-- Signals from serial_ctrl
	signal serial_on				: std_logic;
	signal serial_off				: std_logic;
	signal serial_up				: std_logic;
	signal serial_down			: std_logic;
	
	-- Signals from pwm_ctrl
	signal current_dc				: std_logic_vector(7 downto 0);
	signal current_dc_update	: std_logic;

begin
	
	ledg(7 downto 1) <= "0000000";
	ledr(9 downto 1) <= "000000000";
	
	-- Handle creation of PLL
	b_gen_pll : if (not g_simulation) generate
   -- Instance of PLL
      i_altera_pll : entity work.altera_pll
      port map(
         areset		=> '0',        -- Reset towards PLL is inactive
         inclk0		=> clock_50,   -- 50 MHz input clock
         c0		      => open,       -- 25 MHz output clock unused
         c1		      => clk_50,     -- 50 MHz output clock
         c2		      => open,       -- 100 MHz output clock unused
         locked		=> pll_locked);-- PLL Locked output signal

      i_reset_ctrl : entity work.reset_ctrl
      generic map(
         g_reset_hold_clk  => 127)
      port map(
         clk         => clk_50,
         reset_in    => '0',
         reset_in_n  => pll_locked, -- reset active if PLL is not locked

         reset_out   => reset,
         reset_out_n => open);
   end generate;
	
	b_sim_clock_gen : if g_simulation generate
      clk_50   <= clock_50;
      p_internal_reset : process
      begin
         reset    <= '1';
         wait until clock_50 = '1';
         wait for 1 us;
         wait until clock_50 = '1';
         reset    <= '0';
         wait;
      end process p_internal_reset;
   end generate;
	
	
	key_ctrl_0 : entity work.key_ctrl
	port map (
		clk		=> clk_50,
		reset		=> reset,
		key_n		=> key_n,
		key_on	=> key_on,
		key_off	=> key_off,
		key_up	=> key_up,
		key_down	=> key_down );
		
	pwm_ctrl_0 : entity work.pwm_ctrl
	port map (
		clk					=> clk_50,
		reset					=> reset,
		key_on				=> key_on,
		key_off				=> key_off,
		key_up				=> key_up,
		key_down				=> key_down,
		serial_on			=> serial_on,
		serial_off			=> serial_off,
		serial_up			=> serial_up,
		serial_down			=> serial_down,
		pwm_output			=> ledg(0),
		current_dc			=> current_dc,
		current_dc_update	=> current_dc_update );
		
	serial_uart_0 : entity work.serial_uart
	port map (
      clk                     => clk_50,
      reset                   => reset,
      rx                      => fpga_in_rx,
      tx                      => fpga_out_tx,
      received_data           => received_data,
      received_valid          => received_valid,
      received_error          => ledr(0),
      received_parity_error   => open,					-- Not used
      transmit_ready          => transmit_ready,
      transmit_valid          => transmit_valid,
      transmit_data           => transmit_data );
		
	serial_ctrl_0 : entity work.serial_ctrl
	port map (
		clk				=> clk_50,
		reset				=> reset, 
		received_data	=> received_data,
		received_valid	=> received_valid,
		serial_on		=> serial_on,
		serial_off		=> serial_off,
		serial_up		=> serial_up,
		serial_down		=> serial_down );
	
	dc_disp_ctrl_0 : entity work.dc_disp_ctrl
	port map (
		clk					=> clk_50,
		reset					=> reset,
		current_dc			=> current_dc,
		current_dc_update	=> current_dc_update,
		transmit_ready		=> transmit_ready,
		transmit_valid		=> transmit_valid,
		transmit_data		=> transmit_data,
		hex0					=> hex0,
		hex1					=> hex1,
		hex2					=> hex2,
		hex3					=> hex3 );
	
end architecture;

