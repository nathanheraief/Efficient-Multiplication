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
		N : INTEGER := 577,
    NB_ADD : INTEGER := NB_ADD
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
		result : OUT std_logic_vector(N + 1 DOWNTO 0) -- result (always required)

	);
END evaluator;

ARCHITECTURE rtl OF evaluator IS
	TYPE STATE_T IS (INIT, PRECALCUL, CALCUL); --Vous pouvez rajouter des etats ici.

	SIGNAL current_s     : STATE_T;

  SIGNAL COUNTER : INTEGER := 0;
  SIGNAL SP1 : std_logic_vector(N DOWNTO 0);
  SIGNAL SI1 : std_logic_vector(N DOWNTO 0);
  SIGNAL SP2 : std_logic_vector(N DOWNTO 0);
  SIGNAL SI2 : std_logic_vector(N DOWNTO 0);
  SIGNAL SP4 : std_logic_vector(N DOWNTO 0);
  SIGNAL SI4 : std_logic_vector(N DOWNTO 0);

  SIGNAL start_s : std_logic_vector(NB_ADD-1 DOWNTO 0);
  SIGNAL clk_s   : std_logic;
  SIGNAL done_s : std_logic_vector(NB_ADD-1 DOWNTO 0);
  SIGNAL sub_i_s : std_logic_vector(NB_ADD-1 DOWNTO 0);
  SIGNAL dataa_s : std_logic_vector(NB_ADD*(N+1) DOWNTO 0);
  SIGNAL datab_s : std_logic_vector(NB_ADD*(N+1) DOWNTO 0);


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
  			datab  : IN std_logic_vector(N DOWNTO 0);      -- Operand B (optional)
  			result : OUT std_logic_vector(N + 1 DOWNTO 0); -- result (always required)

  			--Custom I/O
  			sub_i : IN std_logic;
  			p_i   : IN std_logic_vector(N - 1 DOWNTO 0);
  			m_i   : IN std_logic_vector(N + 1 DOWNTO 0)
  		);
  	END COMPONENT;

BEGIN

clk_s     <= clk;
reset_s   <= reset;

G1 : FOR i IN (NB_ADD-1) DOWNTO 0 GENERATE
  ADD:Omura_Optimized
  GENERIC MAP(N => N_WIDTH)
  PORT MAP(
    clk    => clk_s,
    reset  => reset_s,
    clk_en => clk_en_s,
    start  => start_s(i),
    done   => done_s(i),
    dataa  => dataa_s(i(N+1) DOWNTO N+(N+1)*i),
    datab  => datab_s(i(N+1) DOWNTO N+(N+1)*i),
    result => result_s(i(N+1) DOWNTO N+(N+1)*i),
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
			busy          <= '0';
			result        <= (OTHERS => '0');
			done          <= '0';
			current_s     <= Init;

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

				WHEN PRECALCUL =>
          IF(counter = 0) THEN
            dataa_s(102 DOWNTO 0)   <=
            dataa_s(205 DOWNTO 103) <=
            dataa_s(308 DOWNTO 206) <=
            dataa_s(411 DOWNTO 309) <=
            dataa_s(515 DOWNTO 412) <=
          END IF;
          IF(counter = 1) THEN
          END IF;
          IF(counter = 3) THEN
          END IF;
				WHEN CALCUL =>


			END CASE;
		END IF;
	END PROCESS;

END rtl;
