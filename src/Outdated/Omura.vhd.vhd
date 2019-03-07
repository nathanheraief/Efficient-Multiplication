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
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------

ENTITY Omura IS
	GENERIC (
		N : INTEGER := 577
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic;                     -- CPU system clock (always required)
		reset  : IN std_logic;                     -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                     -- Clock-qualifier (always required)
		start  : IN std_logic;                     -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                    -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(N DOWNTO 0);  -- Operand A (always required)
		datab  : IN std_logic_vector(N DOWNTO 0);  -- Operand B (optional)
		result : OUT std_logic_vector(N DOWNTO 0); -- result (always required)

		--Custom I/O
		sub_i  : IN std_logic;
		p_i    : IN std_logic_vector(N DOWNTO 0);
		m_i    : IN std_logic_vector(N DOWNTO 0)
	);
END ENTITY Omura;
ARCHITECTURE rtl OF Omura IS
	TYPE STATE_T IS (Init, I0, I0i, I0n, I1, I1i, I1ei, I1eii, I1e, I1n); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s : STATE_T;
	SIGNAL dataa_p   : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL dataa_f   : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL datab_p   : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL datab_f   : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL S         : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL Sp        : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL pp        : STD_LOGIC_VECTOR(N DOWNTO 0);
	SIGNAL busy      : STD_LOGIC;
	SIGNAL T1        : STD_LOGIC;
	SIGNAL T2        : STD_LOGIC;

BEGIN

	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			dataa_p   <= (OTHERS => '0');
			dataa_f   <= (OTHERS => '0');
			datab_p   <= (OTHERS => '0');
			datab_f   <= (OTHERS => '0');
			S         <= (OTHERS => '0');
			Sp        <= (OTHERS => '0');
			busy      <= '0';
			result    <= (OTHERS => '0');
			done      <= '0';
			T1        <= '0';
			T2        <= '0';
			current_s <= Init;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN Init =>
					IF (start = '1' AND busy = '0') THEN
						done      <= '0';
						dataa_p   <= (N DOWNTO dataa'length => '0') & dataa;
						datab_p   <= (N DOWNTO dataa'length => '0') & dataa;
						current_s <= I0;
					ELSE
						done      <= '0';
						current_s <= Init;
					END IF;

				WHEN I0 =>
					IF (sub_i = '1') THEN
						current_s <= I0i;
					ELSE
						current_s <= I0n;
					END IF;

				WHEN I0i =>
					datab_f   <= NOT datab_p + 1;
					current_s <= I0n;

				WHEN I0n =>
					S <= dataa_p + datab_f;
					IF (S(N) = '1') THEN
						T1 <= '1';
					END IF;
					Sp        <= NOT S;
					current_s <= I1;

				WHEN I1 =>
					IF (T1 = '1') THEN
						current_s <= I1i;
					ELSE
						IF (S(N) = '1' AND S(N - 1) = '1') THEN
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
					pp(N - 1 DOWNTO 1) <= p_i(N - 2 DOWNTO 0);

				WHEN I1eii =>
					result    <= S + ((NOT pp) + 1);
					current_s <= I1n;

				WHEN I1e =>
					result    <= S;
					current_s <= I1n;

				WHEN I1n =>
					Done      <= '1';
					current_s <= Init;

			END CASE;
		END IF;
	END PROCESS;

END ARCHITECTURE;