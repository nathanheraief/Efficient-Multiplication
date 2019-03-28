-------------------------------------------------------------------------------
-- Title : Product Evaluator
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Product_Evaluator.vhd
-- Author : Aboubakri Mehdi
-- Created : 19 Mars 2019
-- Last update: 19 Mars 2019
-------------------------------------------------------------------------------
-- Description: Product_Evaluator.vhd
--
------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------
ENTITY Product_Evaluator IS
	GENERIC (
		N : INTEGER := 103;
    N_COEFF: INTEGER  := 8;
    N_ADD: INTEGER := 6
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic;                         -- CPU system clock (always required)
		reset  : IN std_logic;                         -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                         -- Clock-qualifier (always required)
		start  : IN std_logic;                         -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                        -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(N * N_COEFF - 1 DOWNTO 0);      -- Operand A (always required)
		datab  : IN std_logic_vector(N * N_COEFF - 1 DOWNTO 0);      -- Operand B(always required)
		result : OUT std_logic_vector(N * N_COEFF - 1 DOWNTO 0); -- result (always required)
    p   : IN std_logic_vector(N - 2 DOWNTO 0)
	);
END Product_Evaluator;

ARCHITECTURE rtl OF Product_Evaluator IS
	TYPE STATE_T IS (INIT, CALCUL, WRITE); --Vous pouvez rajouter des etats ici.

  SIGNAL clk_s          : std_logic;
	SIGNAL reset_s        : std_logic;
	SIGNAL clk_en_s       : std_logic;
	SIGNAL start_s        : std_logic;
	SIGNAL done_s         : std_logic;
	SIGNAL current_s      : STATE_T;
	SIGNAL dataa_s        : STD_LOGIC_VECTOR(N * N_COEFF - 1 DOWNTO 0);
	SIGNAL datab_s        : STD_LOGIC_VECTOR(N * N_COEFF - 1 DOWNTO 0);
	SIGNAL to_be_written  : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
	SIGNAL carry_s        : STD_LOGIC;
  SIGNAL result_s       : STD_LOGIC_VECTOR(N * N_COEFF - 1 DOWNTO 0);
  SIGNAL p_s            : STD_LOGIC_VECTOR(N - 2 DOWNTO 0);
  SIGNAL p_big_s            : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
  SIGNAL done_eva_s     : STD_LOGIC_VECTOR(1 DOWNTO 0);    
  SIGNAL done_prod_s    : STD_LOGIC_VECTOR(N_COEFF DOWNTO 0);    
	

  -- COMPONENT evaluator
	-- 	GENERIC (
	-- 		N      : INTEGER := 103; -- bits by coefficient
	-- 		NB_ADD : INTEGER := 6
	-- 	);
	-- 	PORT (
	-- 		clk    : IN std_logic;                               -- CPU system clock (always required)
	-- 		reset  : IN std_logic;                               -- CPU master asynchronous active high reset (always required)
	-- 		clk_en : IN std_logic;                               -- Clock-qualifier (always required)
	-- 		start  : IN std_logic;                               -- Active high signal used to specify that inputs are valid (always required)
	-- 		done   : OUT std_logic;                              -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
	-- 		dataa  : IN std_logic_vector(5 * (N) - 1 DOWNTO 0);  -- Operand A (always required)
	-- 		result : OUT std_logic_vector((N) * 8 - 1 DOWNTO 0); -- result (always required)
	-- 		p      : IN std_logic_vector(N - 2 DOWNTO 0)

	-- 	);
	-- END COMPONENT;

  COMPONENT Montgomery_Multiplication IS
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
      datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (always required)
      result : OUT std_logic_vector(N DOWNTO 0); -- result (always required)

      --Custom I/O
      p_i    : IN std_logic_vector(N DOWNTO 0)
    );
  END COMPONENT;

BEGIN

  clk_s                <= clk;
	reset_s              <= reset;
	clk_en_s						 <= clk_en_s;

  -- EVA1 : evaluator
	-- GENERIC MAP(
	-- 	N      => N,
	-- 	NB_ADD => N_ADD)
	-- PORT MAP(
	-- 	clk    => clk_s,
	-- 	reset  => reset_s,
	-- 	clk_en => clk_en_s,
	-- 	start  => start_s,
	-- 	done   => done_eva_s(0),
	-- 	dataa  => dataa,
	-- 	result => dataa_s,
	-- 	p      => p_s
	-- );

  -- EVA2 : evaluator
	-- GENERIC MAP(
	-- 	N      => N,
	-- 	NB_ADD => N_ADD)
	-- PORT MAP(
	-- 	clk    => clk_s,
	-- 	reset  => reset_s,
	-- 	clk_en => clk_en_s,
	-- 	start  => start_s,
	-- 	done   => done_eva_s(1),
	-- 	dataa  => datab,
	-- 	result => datab_s,
	-- 	p      => p_s
	-- );

  G1 : FOR i IN ( N_COEFF - 1) DOWNTO 0 GENERATE
		PROD : Montgomery_Multiplication
	  GENERIC MAP(N => N - 1)
	  PORT MAP(
		  clk    => clk_s,
		  reset  => reset_s,
		  clk_en => clk_en_s,
		  start  => start_s,
		  done   => done_prod_s(i),
		  dataa  => dataa_s(i * N + N - 1 DOWNTO N * i),
		  datab  => datab_s(i * N + N - 1 DOWNTO N * i),
		  result => result_s(i * N + N - 1 DOWNTO N * i),
		  p_i    => p_big_s
	  );
	END GENERATE G1;

	PROCESS (clk, reset)
		
  VARIABLE i : INTEGER RANGE 1 TO N := 1; -- set to 0 when process first starts
	
  BEGIN
		IF (reset = '1') THEN
			to_be_written <= (OTHERS => '0');
			result        <= (OTHERS => '0');
			dataa_s				<= (OTHERS => '0');
			datab_s				<= (OTHERS => '0');
      carry_s       <= '0';
			done          <= '0';
			current_s     <= INIT;
			p_s           <= (OTHERS => '0');
			p_big_s       <= (OTHERS => '0');

		ELSIF (rising_edge(clk)) THEN

			CASE current_s IS

				WHEN INIT =>
					IF (start = '1') THEN
						done           <= '0';
						dataa_s 			 <= dataa;
						datab_s 			 <= datab;
            p_s            <= p;
            p_big_s        <= '0' & p;
						current_s <= CALCUL;
            start_s <= '1'; -- !!!
					ELSE
						done      <= '0';
						current_s <= INIT;
					END IF;


				WHEN CALCUL =>
          start_s <= '0';
					IF (done_prod_s = "11111111") THEN 
            current_s <= WRITE;
          END IF;

        -- WHEN PRODUCT =>
        --   IF (done_prod_s(0) = '1') THEN
        --     current_s <= WRITE;
        --   END IF;

				WHEN WRITE =>
					result    <= result_s;
					done      <= '1';
					current_s <= INIT;

			END CASE;
		END IF;
	END PROCESS;

END rtl;