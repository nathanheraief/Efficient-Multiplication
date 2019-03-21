

-------------------------------------------------------------------------------
-- Title : Memory Instruction
-- Project : LogicBrain
-------------------------------------------------------------------------------
-- File : loadFirstLayerWeight_tb.vhd
-- Author : non renseigne
-- Created : non renseigne
-- Last update: non renseigne
-------------------------------------------------------------------------------
-- Description:
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
-------------------------------------
ENTITY Montgomery_Multiplication_tb IS
END Montgomery_Multiplication_tb;

ARCHITECTURE arch OF Montgomery_Multiplication_tb IS

	CONSTANT N_WIDTH    : INTEGER   := 4;
	CONSTANT TIME_DELTA : TIME      := 6 ns;

	SIGNAL clk_s        : std_logic := '0';
	SIGNAL reset_s      : std_logic;
	SIGNAL clk_en_s     : std_logic;
	SIGNAL start_s      : std_logic;
	SIGNAL done_s       : std_logic;
	SIGNAL dataa_s      : std_logic_vector(N_WIDTH DOWNTO 0);
	SIGNAL datab_s      : std_logic_vector(N_WIDTH DOWNTO 0);
	SIGNAL result_s     : STD_LOGIC_vector(N_WIDTH DOWNTO 0);

	SIGNAL p_i_s        : STD_LOGIC_Vector(N_WIDTH DOWNTO 0);

	COMPONENT Montgomery_Multiplication
		GENERIC (
			N : INTEGER := 15
		);
		PORT (
			-- Required by CPU
			clk    : IN std_logic;                         -- CPU system clock (always required)
			reset  : IN std_logic;                         -- CPU master asynchronous active high reset (always required)
			clk_en : IN std_logic;                         -- Clock-qualifier (always required)
			start  : IN std_logic;                         -- Active high signal used to specify that inputs are valid (always required)
			done   : OUT std_logic;                        -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
			dataa  : IN std_logic_vector(N DOWNTO 0);      -- Operand A (always required)
			datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (always required)
			result : OUT std_logic_vector(N DOWNTO 0); -- result (always required)

			--Custom I/O
			p_i    : IN std_logic_vector(N DOWNTO 0)
		);
	END COMPONENT;

BEGIN
	DUT : Montgomery_Multiplication
	GENERIC MAP(N => N_WIDTH)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		dataa  => dataa_s,
		datab  => datab_s,
		result => result_s,
		p_i    => p_i_s
	);

	clk_s <= NOT clk_s AFTER TIME_DELTA;

	do_check_out_result : PROCESS
	BEGIN
		reset_s <= '1';

		WAIT FOR 2 * TIME_DELTA;
		reset_s <= '0';

		WAIT FOR TIME_DELTA;
		dataa_s <= (OTHERS => '0');
		datab_s <= (OTHERS => '0');
		p_i_s		<= (OTHERS => '0');

		WAIT FOR TIME_DELTA;
		dataa_s(N_WIDTH DOWNTO 0) 		<= "00111"; --7
		datab_s(N_WIDTH DOWNTO 0) 		<= "11000"; --3 * 8
		p_i_s(N_WIDTH DOWNTO 0)   <= "01011";  --11

		WAIT FOR TIME_DELTA;
		start_s <= '1';

		WAIT FOR 2 * TIME_DELTA;
		start_s <= '0';

		WAIT;
	END PROCESS do_check_out_result;

END ARCHITECTURE;