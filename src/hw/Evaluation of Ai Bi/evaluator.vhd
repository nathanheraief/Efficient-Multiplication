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
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------

ENTITY evaluator IS
	GENERIC (
		N      : INTEGER := 103; -- bits by coefficient
		NB_ADD : INTEGER := 6
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic;                              -- CPU system clock (always required)
		reset  : IN std_logic;                              -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                              -- Clock-qualifier (always required)
		start  : IN std_logic;                              -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                             -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(5 * (N) - 1 DOWNTO 0); -- Operand A (always required)
		result : OUT std_logic_vector((N) * 7 - 1 DOWNTO 0); -- result (always required)
		p    : IN std_logic_vector(N - 2 DOWNTO 0)
	);
END evaluator;
ARCHITECTURE rtl OF evaluator IS

	TYPE STATE_T IS (INIT, PRECALCUL, TEMP, TEMP2, CALCUL, STORAGE, FINISH);

	SIGNAL current_s     : STATE_T;
	SIGNAL busy          : std_logic := '0';
	SIGNAL COUNTER       : INTEGER   := 0;

	SIGNAL start_s       : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL clk_s         : std_logic;
	SIGNAL reset_s       : std_logic;
	SIGNAL clk_en_s      : std_logic;
	SIGNAL done_s        : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL sub_i_s       : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL dataa_s       : std_logic_vector(NB_ADD * (N) - 1 DOWNTO 0);
	SIGNAL datab_s       : std_logic_vector(NB_ADD * (N) - 1DOWNTO 0);
	SIGNAL result_s      : std_logic_vector(NB_ADD * (N + 1) - 1 DOWNTO 0);
	SIGNAL store         : std_logic_vector((N) - 1 DOWNTO 0);
	SIGNAL bigstore      : std_logic_vector(5 * (N) + (N) - 1 DOWNTO 0);

	COMPONENT Omura_Optimized
		GENERIC (
			N : INTEGER := 103
		);
		PORT (
			-- Required by CPU
			clk    : IN std_logic;                         -- CPU system clock (always required)
			reset  : IN std_logic;                         -- CPU master asynchronous active high reset (always required)
			clk_en : IN std_logic;                         -- Clock-qualifier (always required)
			start  : IN std_logic;                         -- Active high signal used to specify that inputs are valid (always required)
			done   : OUT std_logic;                        -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
			dataa  : IN std_logic_vector(N DOWNTO 0);      -- Operand A (always required)
			datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (optional)
			result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

			--Custom I/O
			sub_i  : IN std_logic;
			p_i    : IN std_logic_vector(N - 1 DOWNTO 0)
		);
	END COMPONENT;
BEGIN

	clk_s   <= clk;
	reset_s <= reset;

	G1 : FOR i IN (NB_ADD - 1) DOWNTO 0 GENERATE
		ADD : Omura_Optimized
		GENERIC MAP(N => N - 1) --103
		PORT MAP(
			clk    => clk_s,
			reset  => reset_s,
			clk_en => clk_en_s,
			start  => start_s(i),
			done   => done_s(i),
			dataa  => dataa_s(i * (N) + (N) - 1 DOWNTO i * (N)),
			datab  => datab_s(i * (N) + (N) - 1 DOWNTO i * (N)),
			result => result_s(i * (N + 1) + (N + 1) - 1 DOWNTO i * (N + 1)),
			sub_i  => sub_i_s(i),
			p_i    => p
		);
	END GENERATE G1;

	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN

			start_s       <= (OTHERS => '0');
			dataa_s       <= (OTHERS => '0');
			datab_s       <= (OTHERS => '0');
			p_i_s         <= (OTHERS => '0');
			sub_i_s       <= (OTHERS => '0');
			busy          <= '0';
			result        <= (OTHERS => '0');
			store         <= (OTHERS => '0'); 
			bigstore      <= (OTHERS => '0'); 
			done          <= '0';
			current_s     <= Init;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						done      <= '0';
						current_s <= PRECALCUL;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				WHEN TEMP          =>
					start_s <= (OTHERS => '0');
					IF (done_s = "111111" OR done_s = "010101") THEN
						IF (counter = 2) THEN
							current_s <= STORAGE;
							counter   <= 0;
						ELSE
							sub_i_s   <= (OTHERS => '0');
							dataa_s   <= (OTHERS => '0');
							datab_s   <= (OTHERS => '0');
							counter   <= counter + 1;
							current_s <= PRECALCUL;
						END IF;
					ELSE
						current_s <= TEMP;
					END IF;

				WHEN TEMP2         =>
					start_s <= (OTHERS => '0');
					IF (done_s = "000111" OR done_s = "000001") THEN
						IF (counter = 2) THEN
							current_s <= FINISH;
							counter   <= 0;
						ELSE
							sub_i_s   <= (OTHERS => '0');
							dataa_s   <= (OTHERS => '0');
							datab_s   <= (OTHERS => '0');
							counter   <= counter + 1;
							current_s <= CALCUL;
						END IF;
					ELSE
						current_s <= TEMP2;
					END IF;
				WHEN PRECALCUL =>
					IF (counter = 0) THEN
						-- Adder 0
						dataa_s(0 * (N) + N - 1 DOWNTO 0)           <= dataa(0 * (N) + N - 1 DOWNTO 0);           --a0
						datab_s(0 * (N) + N - 1 DOWNTO 0)           <= dataa(2 * (N) + N - 1 DOWNTO 2 * (N));     --a2
						-- Adder 1
						dataa_s(1 * (N) + N - 1 DOWNTO 1 * (N))     <= dataa(1 * (N) + N - 1 DOWNTO 1 * (N));     --a1
						datab_s(1 * (N) + N - 1 DOWNTO 1 * (N))     <= dataa(3 * (N) + N - 1 DOWNTO 3 * (N));     --a3
						--Adder 2
						dataa_s(2 * (N) + N - 1 DOWNTO 2 * (N))     <= dataa(0 * (N) + N - 1 DOWNTO 0);           --a0
						datab_s(2 * (N) + N - 1 DOWNTO 2 * (N) + 2) <= dataa(2 * (N) + N - 1 - 2 DOWNTO 2 * (N)); --a2*2^2
						--Adder 3
						dataa_s(3 * (N) + N - 1 DOWNTO 3 * (N) + 1) <= dataa(1 * (N) + N - 1 - 1 DOWNTO 1 * (N)); -- 2a1
						datab_s(3 * (N) + N - 1 DOWNTO 3 * (N) + 3) <= dataa(3 * (N) + N - 1 - 3 DOWNTO 3 * (N)); --2^3 * a3
						--Adder 4
						dataa_s(4 * (N) + N - 1 DOWNTO 4 * (N))     <= dataa(0 * (N) + N - 1 DOWNTO 0);           --a0
						datab_s(4 * (N) + N - 1 DOWNTO 4 * (N) + 4) <= dataa(2 * (N) + N - 1 - 4 DOWNTO 2 * (N)); -- 2^4 * a2
						-- Adder 5
						dataa_s(5 * (N) + N - 1 DOWNTO 5 * (N) + 2) <= dataa(1 * (N) + N - 1 - 2 DOWNTO 1 * (N)); --2^2 * a1
						datab_s(5 * (N) + N - 1 DOWNTO 5 * (N) + 6) <= dataa(3 * (N) + N - 1 - 6 DOWNTO 3 * (N)); -- 2^6 * a3

						start_s                                     <= (OTHERS => '1');
						current_s                                   <= TEMP;
					END IF;

					IF (counter = 1) THEN
						-- Adder 0
						dataa_s(0 * (N) + N - 1 DOWNTO 0)           <= result_s(0 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 0);           -- c
						datab_s(0 * (N) + N - 1 DOWNTO 0)           <= dataa(4 * (N) + N - 1 DOWNTO 4 * (N));                      --a4
						-- Adder 1
						--dataa_s(i*(N) + N - 1 DOWNTO i*(N)) <= dataa(i*(N) + N - 1 DOWNTO i*(N)); --a1
						--datab_s(i*(N) + N - 1 DOWNTO i*(N)) <= datab(i*(N) + N - 1 DOWNTO i*(N)); --a3
						--Adder 2
						dataa_s(2 * (N) + N - 1 DOWNTO 2 * (N))     <= result_s(2 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 2 * (N + 1)); --c
						datab_s(2 * (N) + N - 1 DOWNTO 2 * (N) + 4) <= dataa(4 * (N) + N - 1 - 4 DOWNTO 4 * (N));                  --a4*2^4
						--Adder 3
						--dataa_s(4*(N) + N - 1 DOWNTO 3*(N)+1) <= dataa(i*(N) + N - 1 - 1 DOWNTO i*(N)); -- 2a1
						--datab_s(4*(N) + N - 1 DOWNTO 3*(N)+3) <= datab(4*(N) + N - 1 - 3 DOWNTO 3*(N)); --2^3 * a3
						--Adder 4
						dataa_s(4 * (N) + N - 1 DOWNTO 4 * (N))     <= result_s(4 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 4 * (N + 1)); --c
						datab_s(4 * (N) + N - 1 DOWNTO 4 * (N) + 8) <= dataa(4 * (N) + N - 1 - 8 DOWNTO 4 * (N));                  -- 2^8 * a4
						-- Adder 5
						--dataa_s(618 DOWNTO 5*(N)+4) <= dataa(i*(N) + N - 1 - 4 DOWNTO i*(N)); --2^2 * a1
						--datab_s(618 DOWNTO 5*(N)+6) <= datab(4*(N) + N - 1 - 6 DOWNTO 3*(N)); -- 2^6 * a3

						start_s(0)                                  <= '1';
						start_s(2)                                  <= '1';
						start_s(4)                                  <= '1';

						current_s                                   <= TEMP;

					END IF;

					IF (counter = 2) THEN
						-- Adder 0
						dataa_s(0 * (N) + N - 1 DOWNTO 0)       <= result_s(1 * (N) - 1 DOWNTO 0);                             -- sp1
						datab_s(0 * (N) + N - 1 DOWNTO 0)       <= result_s(1 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 1 * (N + 1)); -- si1
						-- Adder 1
						dataa_s(1 * (N) + N - 1 DOWNTO 1 * (N)) <= result_s(1 * (N) - 1 DOWNTO 0);                             -- sp1
						datab_s(1 * (N) + N - 1 DOWNTO 1 * (N)) <= result_s(1 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 1 * (N + 1)); -- -si1
						sub_i_s(1)                              <= '1';
						--Adder 2
						dataa_s(2 * (N) + N - 1 DOWNTO 2 * (N)) <= result_s(2 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 2 * (N + 1)); -- sp2
						datab_s(2 * (N) + N - 1 DOWNTO 2 * (N)) <= result_s(3 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 3 * (N + 1)); -- si2
						--Adder 3
						dataa_s(3 * (N) + N - 1 DOWNTO 3 * (N)) <= result_s(2 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 2 * (N + 1)); -- sp2
						datab_s(3 * (N) + N - 1 DOWNTO 3 * (N)) <= result_s(3 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 3 * (N + 1)); -- -si2
						sub_i_s(3)                              <= '1';
						--Adder 4
						dataa_s(4 * (N) + N - 1 DOWNTO 4 * (N)) <= result_s(4 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 4 * (N + 1)); --sp4
						datab_s(4 * (N) + N - 1 DOWNTO 4 * (N)) <= result_s(5 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 5 * (N + 1)); -- si4
						-- Adder 5
						dataa_s(5 * (N) + N - 1 DOWNTO 5 * (N)) <= result_s(4 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 4 * (N + 1)); -- sp4
						datab_s(5 * (N) + N - 1 DOWNTO 5 * (N)) <= result_s(5 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 5 * (N + 1)); -- -si4
						store                                   <= result_s(5 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 5 * (N + 1));
						sub_i_s(5)                              <= '1';

						start_s                                 <= (OTHERS => '1');
						current_s                               <= TEMP;

					END IF;

				WHEN STORAGE =>
					bigstore <= result_s(5 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 5 * (N + 1)) &
						        result_s(4 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 4 * (N + 1)) &
						        result_s(3 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 3 * (N + 1)) &
						        result_s(2 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 2 * (N + 1)) &
						        result_s(1 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 1 * (N + 1)) &
						        result_s(0 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 0);
						        
						     sub_i_s   <= (OTHERS => '0');
							dataa_s   <= (OTHERS => '0');
							datab_s   <= (OTHERS => '0');
					current_s <= CALCUL;
				WHEN CALCUL =>

					IF (counter = 0) THEN
						-- Adder 0                                
						dataa_s(0 * (N) + N - 1 DOWNTO 0)           <= result_s(0 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 0); --A(1)
						datab_s(0 * (N) + N - 1 DOWNTO 0)           <= '0'& store((N) - 1 DOWNTO 1);                                            --2^-1 Si4
						-- Adder 1
						dataa_s(1 * (N) + N - 1 DOWNTO 1 * (N) + 3) <= dataa(2 * (N) + N - 1 - 3 DOWNTO 2 * (N));        --2^3 a2
						datab_s(1 * (N) + N - 1 DOWNTO 1 * (N) + 2) <= dataa(3 * (N) + N - 1 - 2 DOWNTO 3 * (N));        -- - 2^2 a3
						--Adder 2
						dataa_s(2 * (N) + N - 1 DOWNTO 2 * (N) + 6) <= dataa(4 * (N) + N - 1 - 6 DOWNTO 4*(N));              --2^6 a4
						datab_s(2 * (N) + N - 1 DOWNTO 2 * (N) + 4) <= dataa(4 * (N) + N - 1 - 4 DOWNTO 4 * (N));        --a4*2^4
						sub_i_s(1)                                  <= '1';
						start_s(0)                                  <= '1';
						start_s(1)                                  <= '1';
						start_s(2)                                  <= '1';
						current_s                                   <= TEMP2;

					END IF;

					IF (counter = 1) THEN

						-- Adder 0                                
						dataa_s(0 * (N) + N - 1 DOWNTO 0) <= result_s(1 * (N) - 1 DOWNTO 0);                             -- r1  
						datab_s(0 * (N) + N - 1 DOWNTO 0) <= result_s(1 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 1 * (N + 1)); -- r2

						start_s(0)                        <= '1';
						current_s                         <= TEMP2;
					END IF;

					IF (counter = 2) THEN
						-- Adder 0                                
						dataa_s(0 * (N) + N - 1 DOWNTO 0) <= result_s(1 * (N) - 1 DOWNTO 0);                             -- r1
						datab_s(0 * (N) + N - 1 DOWNTO 0) <= result_s(2 * (N + 1) + (N + 1) - 1 - 1 DOWNTO 2 * (N + 1)); -- r3

						start_s(0)                        <= '1';
						current_s                         <= TEMP2;
					END IF;

				WHEN FINISH =>
					result    <= result_s(1 * (N) - 1 DOWNTO 0) & bigstore;
					done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END ARCHITECTURE;
