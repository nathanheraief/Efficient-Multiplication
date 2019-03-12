-------------------------------------------------------------------------------
-- Title : Evaluator
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : evaluator.vhd
-- Author : Heraief Nathan
-- Created : 18 Feb 2019
-- Last update: 18 Feb 2019
-------------------------------------------------------------------------------
-- Description: Evaluation of A(X) and B(X) on Alpha
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_11NB_ADD4.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------
ENTITY evaluator IS
	GENERIC (
		N      : INTEGER := 515,
		NB_ADD : INTEGER := 6
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic; -- CPU system clock (always required)
		reset  : IN std_logic; -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic; -- Clock-qualifier (always required)
		start  : IN std_logic; -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic; -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(N DOWNTO 0); -- Operand A (always required)
		datab  : IN std_logic_vector(N DOWNTO 0); -- Operand B (optional)
		result : OUT std_logic_vector(N DOWNTO 0) -- result (always required)

	);
END evaluator;

ARCHITECTURE rtl OF evaluator IS
	TYPE STATE_T IS (INIT, PRECALCUL, WAIT, CALCUL); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s : STATE_T;

	SIGNAL COUNTER   : INTEGER := 0;
	SIGNAL SP1       : std_logic_vector(N/5 DOWNTO 0);--103 bits
	SIGNAL SI1       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SP2       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SI2       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SP4       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SI4       : std_logic_vector(N/5 DOWNTO 0);

	SIGNAL start_s   : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL clk_s     : std_logic;
	SIGNAL done_s    : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL sub_i_s   : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL dataa_s   : std_logic_vector(NB_ADD * (N/5) DOWNTO 0);
	SIGNAL datab_s   : std_logic_vector(NB_ADD * (N/5) DOWNTO 0);

	COMPONENT Omura_Optimized
		GENERIC (
			N : INTEGER := 103
		);
		PORT (
			-- Required by CPU
			clk    : IN std_logic; -- CPU system clock (always required)
			reset  : IN std_logic; -- CPU master asynchronous active high reset (always required)
			clk_en : IN std_logic; -- Clock-qualifier (always required)
			start  : IN std_logic; -- Active high signal used to specify that inputs are valid (always required)
			done   : OUT std_logic; -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
			dataa  : IN std_logic_vector(N DOWNTO 0); -- Operand A (always required)
			datab  : IN std_logic_vector(N DOWNTO 0); -- Operand B (optional)
			result : OUT std_logic_vector(N + 1 DOWNTO 0) -- result (always required)
		);
	END COMPONENT;

BEGIN
	clk_s   <= clk;
	reset_s <= reset;

	G1  : FOR i IN (NB_ADD - 1) DOWNTO 0 GENERATE
		ADD : Omura_Optimized
			GENERIC MAP(N => N/5)
		PORT MAP(
			clk    => clk_s,
			reset  => reset_s,
			clk_en => clk_en_s,
			start  => start_s(i),
			done   => done_s(i),
			dataa  => dataa_s(i * (N/5) + (N/5) - 1 DOWNTO i * (N/5)),
			datab  => datab_s(i * (N/5) + (N/5) - 1 DOWNTO i * (N/5)),
			result => result_s(i * (N/5) + (N/5) - 1 DOWNTO i * (N/5)),
			sub_i  => sub_i_s(i),
			p_i    => p_i_s,
			m_i    => m_i_s
		);
END GENERATE G1;
PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			SP1       <= (OTHERS => '0');
			SI1       <= (OTHERS => '0');
			SP2       <= (OTHERS => '0');
			SP4       <= (OTHERS => '0');
			SI4       <= (OTHERS => '0');
			sub_i_s   <= (OTHERS => '0');
			busy      <= '0';
			result    <= (OTHERS => '0');
			done      <= '0';
			current_s <= Init;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						done      <= '0';
						current_s <= PREPROCESS;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				WHEN WAIT =>
					start_s = 0;
					IF (done_s = (OTHERS <= '1')) THEN
						IF (counter = 2) THEN
							current_s <= CALCUL;
							counter = 0;
						ELSE
							counter = counter + 1;
							current_s <= PRECALCUL;
						END IF;
					ELSE
						current_s <= WAIT;
					END IF;


				WHEN PRECALCUL =>
					start_s <= 0;
					IF (counter = 0) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= dataa(102 DOWNTO 0); --a0
						datab_s(102 DOWNTO 0) <= datab(308 DOWNTO 206); --a2
						-- Adder 1
						dataa_s(205 DOWNTO 103) <= dataa(205 DOWNTO 103); --a1
						datab_s(205 DOWNTO 103) <= datab(205 DOWNTO 103); --a3
						--Adder 2
						dataa_s(308 DOWNTO 206) <= dataa(102 DOWNTO 0); --a0
						datab_s(308 DOWNTO 206) <= datab(308 - 2 DOWNTO 206) & (OTHERS => '0'); --a2*2^2
						--Adder 3
						dataa_s(411 DOWNTO 309) <= dataa(205 - 1 DOWNTO 103) & (OTHERS => '0'); -- 2a1
						datab_s(411 DOWNTO 309) <= datab(411 - 3 DOWNTO 309) & (OTHERS => '0'); --2^3 * a3
						--Adder 4
						dataa_s(514 DOWNTO 412) <= dataa(102 DOWNTO 0); --a0
						datab_s(514 DOWNTO 412) <= datab(308 - 4 DOWNTO 206) & (OTHERS => '0'); -- 2^4 * a2
						-- Adder 5
						dataa_s(618 DOWNTO 515) <= dataa(205 - 2 DOWNTO 103) & (OTHERS => '0'); --2^2 * a1
						datab_s(618 DOWNTO 515) <= datab(411 - 6 DOWNTO 309) & (OTHERS => '0'); -- 2^6 * a3

						start_s <= 1;
						current_s <= WAIT;
					END IF;

					IF (counter = 1) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= result_s(102 DOWNTO 0); -- c
						datab_s(102 DOWNTO 0) <= datab(514 DOWNTO 412); --a4
						-- Adder 1
						dataa_s(205 DOWNTO 103) <= dataa(205 DOWNTO 103); --a1
						datab_s(205 DOWNTO 103) <= datab(205 DOWNTO 103); --a3
						--Adder 2
						dataa_s(308 DOWNTO 206) <= result_s(308 DOWNTO 206); --c
						datab_s(308 DOWNTO 206) <= datab(514 - 4 DOWNTO 412) & (OTHERS => '0'); --a4*2^4
						--Adder 3
						dataa_s(411 DOWNTO 309) <= dataa(205 - 1 DOWNTO 103) & (OTHERS => '0'); -- 2a1
						datab_s(411 DOWNTO 309) <= datab(411 - 3 DOWNTO 309) & (OTHERS => '0'); --2^3 * a3
						--Adder 4
						dataa_s(514 DOWNTO 412) <= result_s(102 DOWNTO 0); --c
						datab_s(514 DOWNTO 412) <= datab(514 - 8 DOWNTO 412 & (OTHERS => '0'); -- 2^8 * a4
						-- Adder 5
						dataa_s(618 DOWNTO 515) <= dataa(205 - 4 DOWNTO 103) & (OTHERS => '0'); --2^2 * a1
						datab_s(618 DOWNTO 515) <= datab(411 - 64 DOWNTO 309) & (OTHERS => '0'); -- 2^6 * a3

						start_s <= 1;
						current_s <= WAIT;

					END IF;

					IF (counter = 2) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= result_s(102 DOWNTO 0); -- sp1
						datab_s(102 DOWNTO 0) <= result_s(205 DOWNTO 103); -- si1
						-- Adder 1
						dataa_s(205 DOWNTO 103) <= result_s(102 DOWNTO 0); -- sp1
						datab_s(205 DOWNTO 103) <= result_s(205 DOWNTO 103); -- -si1
						sub_i_s(1) <= '1';
						--Adder 2
						dataa_s(308 DOWNTO 206) <= result_s(308 DOWNTO 206); -- sp2
						datab_s(308 DOWNTO 206) <= result_s(411 DOWNTO 309); -- si2
						--Adder 3
						dataa_s(411 DOWNTO 309) <= result_s(308 DOWNTO 206); -- sp2
						datab_s(411 DOWNTO 309) <= result_s(411 DOWNTO 309); -- -si2
						sub_i_s(3) <= '1';
						--Adder 4
						dataa_s(514 DOWNTO 412) <= result_s(514 DOWNTO 412); --sp4
						datab_s(514 DOWNTO 412) <= result_s(618 DOWNTO 515); -- si4
						-- Adder 5
						dataa_s(618 DOWNTO 515) <= result_s(514 DOWNTO 412); -- sp4
						datab_s(618 DOWNTO 515) <= result_s(618 DOWNTO 515); -- -si4
						sub_i_s(5) <= '1';

						start_s <= 1;
						current_s <= WAIT;

					END IF;

				WHEN CALCUL =>
					result <= result_s;


			END CASE;
		END IF;
	END PROCESS;

END rtl;
