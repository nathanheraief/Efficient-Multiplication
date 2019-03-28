-------------------------------------------------------------------------------
-- Title : Wrapper
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Wrapper.vhd
-- Author : Heraief Nathan
-- Created : 28 Mars 2019
-- Last update: 28 Mars 2019
-------------------------------------------------------------------------------
-- Description: Wrapping all COMPONENTs
--
------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------

ENTITY Wrapper IS
	GENERIC (
		N       : INTEGER := 256;
		N_COEFF : INTEGER := 5
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic; -- CPU system clock (always required)
		reset  : IN std_logic; -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic; -- Clock-qualifier (always required)
		start  : IN std_logic; -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
	);
END Wrapper;

ARCHITECTURE rtl OF Wrapper IS

	TYPE STATE_T IS (INIT, RUN);

	SIGNAL current_s : STATE_T;
	SIGNAL busy      : std_logic := '0';
	SIGNAL COUNTER   : INTEGER   := 0;

	SIGNAL clk_s     : std_logic;
	SIGNAL reset_s   : std_logic;
	SIGNAL clk_en_s  : std_logic;

	SIGNAL dataa     : std_logic_vector(N * N_COEFF - 1 DOWNTO 0); -- Operand A (always required)
	SIGNAL datab     : std_logic_vector(N * N_COEFF - 1 DOWNTO 0); -- Operand B(always required)
	SIGNAL result    : std_logic_vector(N * 8 - 1 DOWNTO 0); -- result (always required)
	SIGNAL p         : std_logic_vector(N - 2 DOWNTO 0);

	COMPONENT Evaluator
		GENERIC (
			N      : INTEGER := 103; -- bits by coefficient
			NB_ADD : INTEGER := 6
		);
		PORT (
			-- Required by CPU
			clk    : IN std_logic;                               -- CPU system clock (always required)
			reset  : IN std_logic;                               -- CPU master asynchronous active high reset (always required)
			clk_en : IN std_logic;                               -- Clock-qualifier (always required)
			start  : IN std_logic;                               -- Active high signal used to specify that inputs are valid (always required)
			done   : OUT std_logic;                              -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
			dataa  : IN std_logic_vector(5 * (N) - 1 DOWNTO 0);  -- Operand A (always required)
			result : OUT std_logic_vector((N) * 8 - 1 DOWNTO 0); -- result (always required)
			p      : IN std_logic_vector(N - 2 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL start_eval_1  : std_logic;
	SIGNAL done_eval_1   : std_logic;
	SIGNAL result_eval_1 : std_logic_vector((N) * 8 - 1 DOWNTO 0);

	SIGNAL start_eval_2  : std_logic;
	SIGNAL done_eval_2   : std_logic;
	SIGNAL result_eval_2 : std_logic_vector((N) * 8 - 1 DOWNTO 0);

	COMPONENT Product_Evaluator
		GENERIC (
			N       : INTEGER := 103;
			N_COEFF : INTEGER := 8;
			N_ADD   : INTEGER := 6
		);
		PORT (
			-- Required by CPU
			clk    : IN std_logic;                                   -- CPU system clock (always required)
			reset  : IN std_logic;                                   -- CPU master asynchronous active high reset (always required)
			clk_en : IN std_logic;                                   -- Clock-qualifier (always required)
			start  : IN std_logic;                                   -- Active high signal used to specify that inputs are valid (always required)
			done   : OUT std_logic;                                  -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
			dataa  : IN std_logic_vector(N * N_COEFF - 1 DOWNTO 0);  -- Operand A (always required)
			datab  : IN std_logic_vector(N * N_COEFF - 1 DOWNTO 0);  -- Operand B(always required)
			result : OUT std_logic_vector(N * N_COEFF - 1 DOWNTO 0); -- result (always required)
			p      : IN std_logic_vector(N - 2 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL start_product : std_logic;
	SIGNAL done_product  : std_logic;

BEGIN

	clk_s         <= clk;
	reset_s       <= reset;
	start_eval_1  <= start;
	start_eval_2  <= start;
	start_product <= done_eval_1 AND done_eval_2;

	evaluator_1 : evaluator
	GENERIC MAP(
		N      => N,
		NB_ADD => 6
	)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_eval_1,
		done   => done_eval_1,
		dataa  => dataa,
		result => result_eval_1,
		p      => p
	);

	evaluator_2 : evaluator
	GENERIC MAP(
		N      => N,
		NB_ADD => 6
	)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_eval_2,
		done   => done_eval_2,
		dataa  => datab,
		result => result_eval_2,
		p      => p
	);

	Product_Evaluator_1 : Product_Evaluator
	GENERIC MAP(
		N       => N ,
		N_COEFF => 8
	)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_product,
		done   => done_product,
		dataa  => result_eval_1,
		datab  => result_eval_2,
		result => result,
		p      => p
	);
	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN

			dataa     <= (OTHERS => '0');
			datab     <= (OTHERS => '0');
			result    <= (OTHERS => '0');
			done      <= '0';
			p         <= (OTHERS => '0');
			current_s <= Init;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						dataa(10) <= '1';
						datab(10) <= '1';
						p(N - 2)  <= '1';
						done      <= '0';
						current_s <= RUN;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				WHEN RUN =>
					IF (done_product = '1') THEN
						done      <= '1';
						current_s <= INIT;
					ELSE
						current_s <= RUN;
					END IF;
			END CASE;
		END IF;
	END PROCESS;

END ARCHITECTURE;