-------------------------------------------------------------------------------
-- Title : Omura Addition Unclocked
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
------------------------------------------------------------------------------

ENTITY Omura IS
	PORT (
		-- Required by CPU
		clk    : IN std_logic;                      -- CPU system clock (always required)
		reset  : IN std_logic;                      -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                      -- Clock-qualifier (always required)
		start  : IN std_logic;                      -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                     -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(255 DOWNTO 0); -- Operand A (always required)
		datab  : IN std_logic_vector(255 DOWNTO 0); -- Operand B (optional)
		result : OUT std_logic_vector(255 DOWNTO 0) -- result (always required)

		--Custom I/O
		sub_i  : IN std_logic;
		p_i    : IN std_logic_vector(255 down TO 0);
		m_i    : IN std_logic_vector(255 down TO 0)
	);
END ENTITY Omura;
ARCHITECTURE rtl OF Omura IS
	TYPE STATE_T IS (Init, I0, I0i, I0n, I1, I1i, I1ei, I1eii, I1e, I1n); --Vous pouvez rajouter des etats ici.

	SIGNAL current_state : STATE_T;
	SIGNAL dataa_p       : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL dataa_f       : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL datab_p       : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL datab_f       : STD_LOGIC_VECTOR(255 DOWNTO 0);

	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN

		ELSIF (rising_edge(clk)) THEN

			CASE etat IS

				WHEN Init =>
					IF (start = '1' AND busy = '0') THEN
						done      <= '0';
						-- precalcule de T0
						current_s <= I0;
					ELSE
						done      <= '0';
						current_s <= Init;
					END IF;

				WHEN I0i =>
					IF (val AND (1 << (256 - 1)) ! = '0') THEN
						datab_f <= datab_p - (1 << (256 - 1));
					END IF;
					valid_f   <= '0';
					current_s <= Add;

				WHEN I0n =>
					S <= dataa + datab;
					IF (S[N + 1] = '1' AND S[N] = '1') THEN
						T1 <= '1';
					END IF;
					Sp        <= NOT S;
					current_s <= I1;

				WHEN I1 =>
					IF (T1 = '1') THEN
						current_s <= I1i;
					ELSE
						IF ((S[N] = '1' AND S[N - 1] = '1') THEN
							T2 <= '1';
						END IF;
						current_s <= I1ei;
					END IF;

				WHEN I1i =>
					result    <= Sp;
					current_s <= I1n;
				WHEN I1ei =>
					IF (T2 = '1') THEN
						current_s <= I1eii;
					ELSE
						current_s <= I1e;
					END IF;

				WHEN I1eii =>
					result <= S - 2 * p_i;
					current_s => I1n;

				WHEN I1e  =>
					result    <= S;
					current_s <= I1n;

				WHEN I1n =>
					Done      <= '1';
					current_s <= Init;

			END CASE;

		END IF;

	END PROCESS;
END ARCHITECTURE;
