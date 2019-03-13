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
		N      : INTEGER := 515;
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
		result : OUT std_logic_vector((N/5)*7-1 DOWNTO 0) -- result (always required)

	);
END evaluator;

ARCHITECTURE rtl OF evaluator IS
	TYPE STATE_T IS (INIT, PRECALCUL, TEMP, CALCUL); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s : STATE_T;
	SIGNAL busy      : std_logic := '0';

	SIGNAL COUNTER   : INTEGER := 0;
	SIGNAL SP1       : std_logic_vector(N/5 DOWNTO 0);--103 bits
	SIGNAL SI1       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SP2       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SI2       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SP4       : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL SI4       : std_logic_vector(N/5 DOWNTO 0);

	SIGNAL start_s   : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL clk_s     : std_logic;
	SIGNAL reset_s   : std_logic;
	SIGNAL clk_en_s  : std_logic;
	SIGNAL done_s    : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL sub_i_s   : std_logic_vector(NB_ADD - 1 DOWNTO 0);
	SIGNAL dataa_s   : std_logic_vector(NB_ADD * (N/5) DOWNTO 0);
	SIGNAL datab_s   : std_logic_vector(NB_ADD * (N/5) DOWNTO 0);
	SIGNAL result_s  : std_logic_vector(NB_ADD * (N/5 + 1) DOWNTO 0);

	SIGNAL m_i_s     : std_logic_vector(N/5 DOWNTO 0);
	SIGNAL p_i_s     : std_logic_vector(N/5 - 2 DOWNTO 0);

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
			result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

		  --Custom I/O
		  sub_i : IN std_logic;
		  p_i   : IN std_logic_vector(N - 1 DOWNTO 0)
		);
	END COMPONENT;

BEGIN
	clk_s   <= clk;
	reset_s <= reset;

	G1  : FOR i IN (NB_ADD - 1) DOWNTO 0 GENERATE
		ADD : Omura_Optimized
			GENERIC MAP(N => N/5 - 1)
		PORT MAP(
			clk    => clk_s,
			reset  => reset_s,
			clk_en => clk_en_s,
			start  => start_s(i),
			done   => done_s(i),
			dataa  => dataa_s(i * (N/5) + (N/5) - 1 DOWNTO i * (N/5)),
			datab  => datab_s(i * (N/5) + (N/5) - 1 DOWNTO i * (N/5)),
			result => result_s(i * (N/5 +1) + (N/5+1) - 1 DOWNTO i * (N/5+1)),
			sub_i  => sub_i_s(i),
			p_i    => p_i_s
		);
END GENERATE G1;
PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
		  
	        start_s       <= (OTHERS => '0');
	        dataa_s       <= (OTHERS => '0');
	        datab_s       <= (OTHERS => '0');
	       result_s       <= (OTHERS => '0');
		    m_i_s       <= (OTHERS => '0');
		    p_i_s       <= "100111101000110110100001100100110101110101010101001011001010011100110110000111000010010000001100000001";
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
						current_s <= PRECALCUL;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				WHEN TEMP =>
					start_s <= (OTHERS => '0');
					IF (done_s = "111111" OR done_s = "010101" ) THEN
						IF (counter = 2) THEN
							current_s <= CALCUL;
							counter <= 0;
						ELSE
							counter <= counter + 1;
							current_s <= PRECALCUL;
						END IF;
					ELSE
						current_s <= TEMP;
					END IF;


				WHEN PRECALCUL =>
					IF (counter = 0) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= dataa(102 DOWNTO 0); --a0
						datab_s(102 DOWNTO 0) <= datab(308 DOWNTO 206); --a2
						-- Adder 1
						dataa_s(205 DOWNTO 103) <= dataa(205 DOWNTO 103); --a1
						datab_s(205 DOWNTO 103) <= datab(205 DOWNTO 103); --a3
						--Adder 2
						dataa_s(308 DOWNTO 206) <= dataa(102 DOWNTO 0); --a0
						datab_s(308 DOWNTO 206+2) <= datab(308 - 2 DOWNTO 206); --a2*2^2
						--Adder 3
						dataa_s(411 DOWNTO 309+1) <= dataa(205 - 1 DOWNTO 103); -- 2a1
						datab_s(411 DOWNTO 309+3) <= datab(411 - 3 DOWNTO 309); --2^3 * a3
						--Adder 4
						dataa_s(514 DOWNTO 412) <= dataa(102 DOWNTO 0); --a0
						datab_s(514 DOWNTO 412+4) <= datab(308 - 4 DOWNTO 206) ; -- 2^4 * a2
						-- Adder 5
						dataa_s(617 DOWNTO 515+2) <= dataa(205 - 2 DOWNTO 103); --2^2 * a1
						datab_s(617 DOWNTO 515+6) <= datab(411 - 6 DOWNTO 309) ; -- 2^6 * a3

						start_s <= (OTHERS => '1');
						current_s <= TEMP;
					END IF;

					IF (counter = 1) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= result_s(102 DOWNTO 0); -- c
						datab_s(102 DOWNTO 0) <= datab(514 DOWNTO 412); --a4
						-- Adder 1
						--dataa_s(205 DOWNTO 103) <= dataa(205 DOWNTO 103); --a1
						--datab_s(205 DOWNTO 103) <= datab(205 DOWNTO 103); --a3
						--Adder 2
						dataa_s(308 DOWNTO 206) <= result_s(310 DOWNTO 208); --c
						datab_s(308 DOWNTO 206+4) <= datab(514 - 4 DOWNTO 412); --a4*2^4
						--Adder 3
						--dataa_s(411 DOWNTO 309+1) <= dataa(205 - 1 DOWNTO 103); -- 2a1
						--datab_s(411 DOWNTO 309+3) <= datab(411 - 3 DOWNTO 309); --2^3 * a3
						--Adder 4
						dataa_s(514 DOWNTO 412)   <= result_s(102 DOWNTO 0); --c
						datab_s(514 DOWNTO 412+8) <= datab(514 - 8 DOWNTO 412) ; -- 2^8 * a4
						-- Adder 5
						--dataa_s(618 DOWNTO 515+4) <= dataa(205 - 4 DOWNTO 103); --2^2 * a1
						--datab_s(618 DOWNTO 515+6) <= datab(411 - 6 DOWNTO 309); -- 2^6 * a3

						start_s(0) <= '1';
						start_s(2) <= '1';
						start_s(4) <= '1';

						current_s <= TEMP;

					END IF;

					IF (counter = 2) THEN
						-- Adder 0
						dataa_s(102 DOWNTO 0) <= result_s(103-1 DOWNTO 0); -- sp1
						datab_s(102 DOWNTO 0) <= result_s(207-1 DOWNTO 104); -- si1
						-- Adder 1
						dataa_s(205 DOWNTO 103) <= result_s(103-1 DOWNTO 0); -- sp1
						datab_s(205 DOWNTO 103) <= result_s(207-1 DOWNTO 104); -- -si1
						sub_i_s(1) <= '1';
						--Adder 2
						dataa_s(308 DOWNTO 206) <= result_s(311-1 DOWNTO 208); -- sp2
						datab_s(308 DOWNTO 206) <= result_s(415-1 DOWNTO 312); -- si2
						--Adder 3
						dataa_s(411 DOWNTO 309) <= result_s(311-1 DOWNTO 208); -- sp2
						datab_s(411 DOWNTO 309) <= result_s(415-1 DOWNTO 312); -- -si2
						sub_i_s(3) <= '1';
						--Adder 4
						dataa_s(514 DOWNTO 412) <= result_s(519-1 DOWNTO 416); --sp4
						datab_s(514 DOWNTO 412) <= result_s(623-1 DOWNTO 520); -- si4
						-- Adder 5
						dataa_s(617 DOWNTO 515) <= result_s(519-1 DOWNTO 416); -- sp4
						datab_s(617 DOWNTO 515) <= result_s(623-1 DOWNTO 520); -- -si4
						sub_i_s(5) <= '1';

						start_s <= (OTHERS => '1');
						current_s <= TEMP;

					END IF;

				WHEN CALCUL =>
					result(617 DOWNTO 0) <= result_s(622 DOWNTO 520) &
					                          result_s(518 DOWNTO 416) &
					                          result_s(414 DOWNTO 312) &
					                          result_s(310 DOWNTO 208) &
					                          result_s(206 DOWNTO 104) &
					                          result_s(102 DOWNTO 0);


			END CASE;
		END IF;
	END PROCESS;

END rtl;
