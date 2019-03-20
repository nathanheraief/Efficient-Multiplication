-------------------------------------------------------------------------------
-- Title : Exact Divider by 5 
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Divider_Five.vhd
-- Author : Aboubakri Mehdi
-- Created : 19 Mars 2019
-- Last update: 19 Mars 2019
-------------------------------------------------------------------------------
-- Description: Implementation of the exact division by 5
--
------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------
ENTITY Divider_Five IS
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
END Divider_Five;

ARCHITECTURE rtl OF Divider_Five IS
	TYPE STATE_T IS (INIT, CALCUL, WRITE); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s     : STATE_T;
	SIGNAL data_s        : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
	SIGNAL to_be_written : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
	SIGNAL carry_s       : STD_LOGIC;
  SIGNAL result_s      : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
	

BEGIN

	PROCESS (clk, reset)
		
  VARIABLE i : INTEGER RANGE 2 TO N := 2; -- set to 0 when process first starts
	
  BEGIN
		IF (reset = '1') THEN
			data_s        <= (OTHERS => '0');
			to_be_written <= (OTHERS => '0');
			result        <= (OTHERS => '0');
			result_s      <= (OTHERS => '0');
      carry_s       <= '0';
			done          <= '0';
			current_s     <= INIT;
			

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1') THEN
						done           <= '0';
            carry_s        <= '0';
						data_s         <= data;
						result_s(1 DOWNTO 0)    <= data(1 DOWNTO 0);
						current_s <= CALCUL;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;


				WHEN CALCUL =>
					IF (i = N) THEN
            i := 2;
            current_s <= WRITE;
          ELSE
            IF (carry_s = '1') THEN
              IF (result_s(i-2) = '1') THEN
                IF (data_s(i) = '1') THEN
                  result_s(i) <= '1';
                END IF;
                carry_s <= '1';
              ELSE
                IF (data_s(i) = '1') THEN
                  carry_s <= '0';
                ELSE
                  result_s(i) <= '1';
                  carry_s <= '1';
                END IF;
              END IF;
            ELSE
              IF (result_s(i-2) = '1') THEN
                IF (data_s(i) = '1') THEN
                  carry_s <= '0';
                ELSE
                  result_s(i) <= '1';
                  carry_s <= '1';
                END IF;
              ELSE
                result_s(i) <= data_s(i);
                carry_s <= '0';
              END IF;
            END IF;
            i := i + 1;
          END IF;

				WHEN WRITE =>
					result    <= result_s;
					done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END rtl;