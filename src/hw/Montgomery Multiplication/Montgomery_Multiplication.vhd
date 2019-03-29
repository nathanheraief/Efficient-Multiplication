-------------------------------------------------------------------------------
-- Title : Montgomery Multiplication Unclocked 
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Montgomery_Multiplication.vhd
-- Author : Aboubakri Mehdi
-- Created : 08 Mars 2019
-- Last update: 18 Mars 2019
-------------------------------------------------------------------------------
-- Description: Implementation of the Montgomery Method to compute modular Multiplication
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------
ENTITY Montgomery_Multiplication IS
	GENERIC (
		N : INTEGER := 256
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
END Montgomery_Multiplication;

ARCHITECTURE rtl OF Montgomery_Multiplication IS

	COMPONENT Omura_Optimized
		GENERIC (
			N : INTEGER := 4
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
			sub_i  : IN std_logic;
			p_i    : IN std_logic_vector(N DOWNTO 0)
		);

	END COMPONENT;

	TYPE STATE_T IS (INIT, RESCALE1, MULTIPLY, PREPROCESS, CALCUL, LAUNCHADD1, LAUNCHADD2, RESCALE2, MODULO, WRITE); --Vous pouvez rajouter des etats ici.

	SIGNAL clk_s     : STD_LOGIC;
	SIGNAL reset_s   : STD_LOGIC;
	SIGNAL clk_en_s  : STD_LOGIC;
	SIGNAL start_s   : STD_LOGIC;
	SIGNAL done_s    : STD_LOGIC;
	SIGNAL current_s : STATE_T;
	SIGNAL dataa_s   : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL dataa_rescaled   : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL datab_s   : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL sub_i_s   : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL S         : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL modulo_s  : STD_LOGIC_VECTOR(2 * N + 4 DOWNTO 0);
	SIGNAL t         : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL St        : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL Stm       : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL p_i_s_i   : STD_LOGIC_VECTOR(2 * N + 2 DOWNTO 0);     --for first adder
	SIGNAL p_i_s_ii  : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0); --for second adder
	SIGNAL p_i_s_iii  : STD_LOGIC_VECTOR(2 * N DOWNTO 0); --for second adder
	SIGNAL busy      : STD_LOGIC;

	SIGNAL scale		 : STD_LOGIC_VECTOR(N DOWNTO 0);

BEGIN

	clk_s                <= clk;
	reset_s              <= reset;
	clk_en_s						 <= clk_en_s;

	ADD1 : Omura_Optimized
	GENERIC MAP(N => 2*N + 3)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		dataa  => (OTHERS => '0'),
		datab  => S,
		result => modulo_s,
		sub_i  => sub_i_s(0),
		p_i    => p_i_s_i
	);

	PROCESS (clk, reset)

		VARIABLE count : INTEGER RANGE 0 TO 2 * N + 1 := 0; -- set to 0 when process first starts
		VARIABLE addId : INTEGER RANGE 0 TO 1 := 0;

	BEGIN
		IF (reset = '1') THEN
			count := 0;
			addId := 0;
			start_s   <= '0';
			dataa_s   <= (OTHERS => '0');
			dataa_rescaled   <= (OTHERS => '0');
			datab_s   <= (OTHERS => '0');
			sub_i_s   <= (OTHERS => '0'); -- On ne fait que des additions ici
			p_i_s_i   <= (OTHERS => '0');
			p_i_s_ii  <= (OTHERS => '0');
			p_i_s_iii <= (OTHERS => '0');
			t         <= (OTHERS => '0');
			S         <= (OTHERS => '0');
			St        <= (OTHERS => '0');
			Stm       <= (OTHERS => '0');
			busy      <= '0';
			scale			<= (OTHERS => '0');
			result    <= (OTHERS => '0');
			done      <= '0';
			current_s <= INIT;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						scale(7 DOWNTO 0)					<= "00010001";
						done      								<= '0';
						dataa_s(N DOWNTO 0)   		<= dataa;
						datab_s(N DOWNTO 0)   		<= datab;
						p_i_s_i(N DOWNTO 0)  			<= p_i;
						p_i_s_ii(N DOWNTO 0) 			<= p_i;
						Stm												<= (OTHERS => '0');
						current_s <= RESCALE1;
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;

				
				WHEN RESCALE1 =>
					if(scale(count) = '1') THEN
						t <= std_logic_vector(shift_left(unsigned(dataa_s), count));
					ELSE
						t <= (OTHERS => '0');
					END IF;
					current_s <= MULTIPLY;

				WHEN MULTIPLY =>
					if(count < 8) THEN -- count < scale.bitlength
						dataa_rescaled <= dataa_rescaled + t;
						count := count + 1;
						current_s <= RESCALE1;	
					ELSE
						dataa_s <= dataa_rescaled;
						count := 0;
						current_s <= PREPROCESS;
					END IF;

				WHEN PREPROCESS =>
					IF (dataa_s(count) = '1') THEN                                       -- if Xi = 1
						t         <= std_logic_vector(shift_left(unsigned(datab_s), count)); -- t = Y.Xi.(2^i)
					ELSE -- if Xi = 0
						t         <= (OTHERS => '0');
					END IF;
					current_s <= LAUNCHADD1;


				WHEN LAUNCHADD1 =>
					S <= S + t;
					if (count = 2*N) THEN
						count := 0;
						current_s <= LAUNCHADD2;
					ELSE
						current_s <= PREPROCESS;
						count := count + 1;
					END IF;

				WHEN LAUNCHADD2 =>
					Stm <= S + p_i_s_ii;
					current_s <= CALCUL;

				WHEN CALCUL =>
					IF (S(0) = '1') THEN
						S         <= Stm; -- Stm = S + t + modulo
					ELSE
						S         <= S; -- St = S + t
					END IF;
					current_s <= RESCALE2;

				WHEN RESCALE2 =>
					addId := 0;
					S <= std_logic_vector(shift_right(unsigned(S), 1));
					IF (count = (2*N - 1) ) THEN
						count := 0;
						start_s <= '1';
						current_s <= MODULO;
					ELSE
						count := count + 1;
						current_s <= LAUNCHADD2;
					END IF;

				WHEN MODULO =>
					start_s <= '0';
					IF (done_s = '1') THEN
						current_s <= WRITE;
					END IF;
					
				WHEN WRITE =>
					result    <= modulo_s(N DOWNTO 0);
					done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END rtl;

