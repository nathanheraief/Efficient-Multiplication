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

ENTITY Product_Evaluator_tb IS
END Product_Evaluator_tb;


ARCHITECTURE arch OF Product_Evaluator_tb IS

	CONSTANT N_WIDTH    : INTEGER   := 103;
	CONSTANT N_COEFF    : INTEGER   := 8;
	CONSTANT N_ADD      : INTEGER   := 6;
	CONSTANT TIME_DELTA : TIME      := 6 ns;

	SIGNAL clk_s        : std_logic := '0';
	SIGNAL reset_s      : std_logic;
	SIGNAL clk_en_s     : std_logic;
	SIGNAL start_s      : std_logic;
	SIGNAL done_s       : std_logic;
	SIGNAL dataa_s      : std_logic_vector(N_COEFF * N_WIDTH - 1 DOWNTO 0);
	SIGNAL datab_s      : std_logic_vector(N_COEFF * N_WIDTH - 1 DOWNTO 0);
	SIGNAL result_s     : STD_LOGIC_vector(N_COEFF * N_WIDTH - 1 DOWNTO 0);
	SIGNAL p_i_s        : STD_LOGIC_Vector(N_WIDTH - 2 DOWNTO 0);

	-- SIGNAL res0         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res1         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res2         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res3         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res4         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res5         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res6         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	-- SIGNAL res7         : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);

	COMPONENT Product_Evaluator
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
      dataa  : IN std_logic_vector(N * 5 - 1 DOWNTO 0);      -- Operand A (always required)
      datab  : IN std_logic_vector(N * 5 - 1 DOWNTO 0);      -- Operand B(always required)
      result : OUT std_logic_vector(N * N_COEFF - 1 DOWNTO 0); -- result (always required)
      p   : IN std_logic_vector(N - 2 DOWNTO 0)
    );
	END COMPONENT;

BEGIN
	DUT : Product_Evaluator
	GENERIC MAP(
		N      => N_WIDTH,
		N_COEFF => N_COEFF,
    N_ADD   => N_ADD)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		dataa  => dataa_s,
    datab  => datab_s,
		result => result_s,
		p      => p_i_s
	);

	clk_s <= NOT clk_s AFTER TIME_DELTA;

	do_check_out_result : PROCESS
	BEGIN
		reset_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		reset_s <= '0';
		WAIT FOR TIME_DELTA;
		dataa_s <= (OTHERS => '0');
		datab_s <= (OTHERS => '0');
		p_i_s <= (OTHERS => '0');
		WAIT FOR TIME_DELTA;
    -- X4 + X3 + X2 + X1 + 1
		dataa_s(2 DOWNTO 0)   <= "101";
		dataa_s((N_WIDTH*2 + 4) DOWNTO N_WIDTH*2) <= "11111";
		dataa_s(206) <= '1';
		dataa_s(309) <= '1';
		dataa_s(412) <= '1';
    -- X4 + X3 + X2 + X1 + 2
		datab_s(1)   <= '1';
		dataa_s((N_WIDTH*2 + 4) DOWNTO N_WIDTH*2) <= "11111";
		datab_s(206) <= '1';
		datab_s(309) <= '1';
		datab_s(412) <= '1';
		p_i_s(8 DOWNTO 0) <= "100100101";

		WAIT FOR TIME_DELTA;
		start_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		start_s <= '0';
		WAIT FOR 100 * TIME_DELTA;
		-- res7 <= result_s(7 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 7 * (N_WIDTH));
		-- res6 <= result_s(6 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 6 * (N_WIDTH));
		-- res5 <= result_s(5 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 5 * (N_WIDTH));
		-- res4 <= result_s(4 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 4 * (N_WIDTH));
		-- res3 <= result_s(3 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 3 * (N_WIDTH));
		-- res2 <= result_s(2 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 2 * (N_WIDTH));
		-- res1 <= result_s(1 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 1 * (N_WIDTH));
		-- res0 <= result_s(0 * (N_WIDTH) + (N_WIDTH) - 1 DOWNTO 0);

		WAIT;
	END PROCESS do_check_out_result;

END ARCHITECTURE;
