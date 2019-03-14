-------------------------------------------------------------------------------
-- Title : Montgomery Multiplication Unclocked 
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Montgomery_Multiplication.vhd
-- Author : Aboubakri Mehdi
-- Created : 08 Mars 2019
-- Last update: 08 Mars 2019
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
		datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (always required)
		result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

		--Custom I/O
		p_i    : IN std_logic_vector(N - 1 DOWNTO 0);
		m_i    : IN std_logic_vector(N + 1 DOWNTO 0)
	);
END Montgomery_Multiplication;

ARCHITECTURE rtl OF Montgomery_Multiplication IS

	COMPONENT Omura_Optimized
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
			datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (always required)
			result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

			--Custom I/O
			sub_i  : IN std_logic;
			p_i    : IN std_logic_vector(N - 1 DOWNTO 0);
			m_i    : IN std_logic_vector(N + 1 DOWNTO 0)
		);

	END COMPONENT;

	TYPE STATE_T IS (INIT, PREPROCESS, CALCUL, LAUNCHADD, RESCALE, WRITE); --Vous pouvez rajouter des etats ici.

	SIGNAL clk_s     : STD_LOGIC;
	SIGNAL reset_s   : STD_LOGIC;
	SIGNAL clk_en_s  : STD_LOGIC;
	SIGNAL start_s   : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL done_s    : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL current_s : STATE_T;
	SIGNAL dataa_s   : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL datab_s   : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL sub_i_s   : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL S         : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL t         : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL St        : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL St_f        : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	-- SIGNAL St_f					 : STD_LOGIC_VECTOR(2*N + 2 DOWNTO 0);
	SIGNAL Stm       : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0);
	SIGNAL p_i_s_i   : STD_LOGIC_VECTOR(2 * N DOWNTO 0);     --for first adder
	SIGNAL p_i_s_ii  : STD_LOGIC_VECTOR(2 * N + 3 DOWNTO 0); --for second adder
	-- SIGNAL p_i_s_f       : STD_LOGIC_VECTOR(2*N + 2 DOWNTO 0);
	SIGNAL m_i_s     : STD_LOGIC_VECTOR(2 * N + 2 DOWNTO 0);
	SIGNAL busy      : STD_LOGIC;
	SIGNAL addition_s: STD_LOGIC;
BEGIN

	clk_s                <= clk;
	reset_s              <= reset;

	ADD1 : Omura_Optimized
	GENERIC MAP(N => 2 * N + 1)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s(0),
		done   => done_s(0),
		dataa  => S(2 * N + 1 DOWNTO 0),
		datab  => t(2 * N + 1 DOWNTO 0),
		result => St(2 * N + 2 DOWNTO 0),
		sub_i  => sub_i_s(0),
		p_i    => p_i_s_i,
		m_i    => m_i_s
	);

	ADD2 : Omura_Optimized
	GENERIC MAP(N => 2 * N + 1)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s(1),
		done   => done_s(1),
		dataa  => St_f(2 * N + 1 DOWNTO 0),
		datab  => p_i_s_ii(2 * N + 1 DOWNTO 0),
		result => Stm(2 * N + 2 DOWNTO 0),
		sub_i  => sub_i_s(1),
		p_i    => p_i_s_i,
		m_i    => m_i_s
	);

	PROCESS (clk, reset)

		VARIABLE count : INTEGER RANGE 0 TO N := 0; -- set to 0 when process first starts
		VARIABLE addId : INTEGER RANGE 0 TO 1 := 0;

	BEGIN
		IF (reset = '1') THEN
			count := 0;
			addId := 0;
			start_s   <= (OTHERS => '0');
			dataa_s   <= (OTHERS => '0');
			datab_s   <= (OTHERS => '0');
			done_s		<= (OTHERS => '0');
			p_i_s_i   <= (OTHERS => '0');
			p_i_s_ii  <= (OTHERS => '0');
			t         <= (OTHERS => '0');
			St        <= (OTHERS => '0');
			St_f      <= (OTHERS => '0');
			Stm       <= (OTHERS => '0');
			S         <= (OTHERS => '0');
			busy      <= '0';
			result    <= (OTHERS => '0');
			done      <= '0';
			current_s <= INIT;

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1' AND busy = '0') THEN
						done      								<= '0';
						start_s										<= "00";
						dataa_s(N DOWNTO 0)   		<= dataa;
						datab_s(N DOWNTO 0)   		<= datab;
						p_i_s_i(N - 1 DOWNTO 0)  	<= p_i;
						p_i_s_ii(N - 1 DOWNTO 0) 	<= p_i;
						current_s <= PREPROCESS;
					ELSE
						done      <= '0';
						start_s   <= "00";
						current_s <= INIT;
					END IF;

				WHEN PREPROCESS =>
					IF (dataa_s(count) = '1') THEN                                       -- if Xi = 1
						t         <= std_logic_vector(shift_left(unsigned(datab_s), count)); -- t = Y.Xi.(2^i)
						current_s <= CALCUL;
					ELSE -- if Xi = 0
						t         <= (OTHERS => '0');
						current_s <= CALCUL;
					END IF;

				WHEN CALCUL =>

					IF (addId = 1) THEN
						start_s(0) <= '0';
					ELSE
						start_s(0) <= '1';
						addId := 1;
					END IF;

					IF (done_s(0) = '1' AND start_s(1) = '0') THEN
						current_s <= LAUNCHADD;
					END IF;

					IF (done_s = "11") THEN
						start_s <= "00";
						IF (t(0) = '1') THEN
							-- S         <= Stm; -- Stm = S + t + modulo
							current_s <= RESCALE;
						ELSE
							-- S         <= St; -- St = S + t
							current_s <= RESCALE;
						END IF;
					END IF;

				WHEN LAUNCHADD =>
					start_s(1) <= '1';
					St_f <= St;
					current_s <= CALCUL;

				WHEN RESCALE =>
					-- start_s <= "00";
					addId := 0;
					S <= std_logic_vector(shift_right(unsigned(S), 1));
					IF (count = N) THEN
						count := 0;
						current_s <= WRITE;
					ELSE
						count := count + 1;
						current_s <= PREPROCESS;
					END IF;	
				WHEN WRITE =>
					result    <= S(N + 1 DOWNTO 0);
					done_s		<= "00";
					done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END rtl;