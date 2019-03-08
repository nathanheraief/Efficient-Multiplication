-------------------------------------------------------------------------------
-- Title : Omura Addition Unclocked Optimized
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Omura.vhd
-- Author : Heraief Nathan
-- Created : 18 Feb 2019
-- Last update: 18 Feb 2019
-------------------------------------------------------------------------------
-- Description: Implementatio of the Omura Methode to compute modular Addition
--
------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------
ENTITY Omura_Optimized IS
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
		dataa  : IN std_logic_vector(N DOWNTO 0);      -- Operand A (always required)
		datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (optional)
		result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

		--Custom I/O
		sub_i : IN std_logic;
		p_i   : IN std_logic_vector(N - 1 DOWNTO 0);
		m_i   : IN std_logic_vector(N + 1 DOWNTO 0)
	);
END Omura_Optimized;

ARCHITECTURE rtl OF Omura_Optimized IS
	TYPE STATE_T IS (INIT, PREPROCESS, CALCUL, RESCALE, WRITE); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s     : STATE_T;
	SIGNAL dataa_p       : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL dataa_f       : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL datab_p       : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL datab_f       : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL to_be_written : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL S             : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL Sp            : STD_LOGIC_VECTOR(N + 1 DOWNTO 0);
	SIGNAL pp            : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
	SIGNAL busy          : STD_LOGIC;
	SIGNAL T1            : STD_LOGIC;
	SIGNAL T2            : STD_LOGIC;

BEGIN

	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			dataa_p       <= (OTHERS => '0');
			dataa_f       <= (OTHERS => '0');
			datab_p       <= (OTHERS => '0');
			datab_f       <= (OTHERS => '0');
			to_be_written <= (OTHERS => '0');
			S             <= (OTHERS => '0');
			Sp            <= (OTHERS => '0');
			pp            <= (OTHERS => '0');
			busy          <= '0';
			result        <= (OTHERS => '0');
			done          <= '0';
			T1            <= '0';
			T2            <= '0';
			current_s     <= Init;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						done      <= '0';
						dataa_p   <= (N + 1 DOWNTO dataa'length => '0') & dataa;
						datab_p   <= (N + 1 DOWNTO datab'length => '0') & datab;
						current_s <= PREPROCESS;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				WHEN PREPROCESS =>
					IF (sub_i = '1') THEN
						datab_f   <= NOT datab_p + 1;
						dataa_f   <= dataa_p;
						current_s <= CALCUL;
					ELSE
						datab_f   <= datab_p;
						dataa_f   <= dataa_p;
						current_s <= CALCUL;
					END IF;

				WHEN CALCUL =>
					S                  <= dataa_f + datab_f;
					pp(N - 1 DOWNTO 1) <= p_i(N - 2 DOWNTO 0);
					current_s          <= RESCALE;

				WHEN RESCALE =>
					IF (S(N + 1) = '1') THEN
						to_be_written <= NOT S;
						current_s     <= WRITE;
					ELSE
						IF (S(N) = '1') THEN
							to_be_written <= S + (NOT pp + 1);
							current_s     <= WRITE;
						ELSE
							to_be_written <= S;
							current_s     <= WRITE;
						END IF;
					END IF;
				WHEN WRITE =>
					result    <= to_be_written;
					Done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END rtl;