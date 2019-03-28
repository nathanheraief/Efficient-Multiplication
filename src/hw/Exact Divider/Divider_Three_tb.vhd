-------------------------------------------------------------------------------
-- Title : Divider Three test bench
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Divider_Three_tb.vhd
-- Author : Aboubakri Mehdi
-- Created : 19 Mars 2019
-- Last update: 19 Mars 2019
-------------------------------------------------------------------------------
-- Description: Testbench for Divider_Three
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
-------------------------------------
ENTITY Divider_Three_tb IS
END Divider_Three_tb;

ARCHITECTURE arch OF Divider_Three_tb IS

	CONSTANT N_WIDTH    : INTEGER := 4;
	CONSTANT TIME_DELTA : TIME    := 6 ns;

	SIGNAL clk_s    : std_logic := '0';
	SIGNAL reset_s  : std_logic;  
	SIGNAL clk_en_s : std_logic;
	SIGNAL start_s  : std_logic;
	SIGNAL done_s   : std_logic;
	SIGNAL data_s  : std_logic_vector(N_WIDTH - 1 DOWNTO 0);
	SIGNAL result_s : STD_LOGIC_vector(N_WIDTH - 1 DOWNTO 0);

	COMPONENT Divider_Three
		GENERIC (
			N : INTEGER := 577
		);
		PORT (
		-- Required by CPU
		clk    : IN std_logic;                         -- CPU system clock (always required)
		reset  : IN std_logic;                         -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                         -- Clock-qualifier (always required)
		start  : IN std_logic;                         -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                        -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		data  : IN std_logic_vector(N - 1 DOWNTO 0);      -- Operand A (always required)
		result : OUT std_logic_vector(N - 1 DOWNTO 0) -- result (always required)
	);
	END COMPONENT;

BEGIN
	DUT : Divider_Three
	GENERIC MAP(N => N_WIDTH)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		data  => data_s,
		result => result_s
	);

	clk_s <= NOT clk_s AFTER TIME_DELTA;

	do_check_out_result : PROCESS
	BEGIN
		reset_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		reset_s <= '0';
		WAIT FOR TIME_DELTA;
		data_s <= (OTHERS => '0');
		WAIT FOR TIME_DELTA;
		data_s <= "0110";

		WAIT FOR TIME_DELTA;
		start_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		start_s <= '0';
		WAIT;
	END PROCESS do_check_out_result;

END ARCHITECTURE;