-------------------------------------------------------------------------------
-- Title : Evaluator
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : evaluator_tb.vhd
-- Author : Heraief Nathan
-- Created : 11 Mar 2019
-- Last update: 12 Mar 2019
-------------------------------------------------------------------------------
-- Description: Testbench for evaluator

------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
-------------------------------------
ENTITY evaluator_tb IS
END evaluator_tb;

ARCHITECTURE arch OF evaluator_tb IS

	CONSTANT N_WIDTH    : INTEGER := 103;
	CONSTANT ADD				: INTEGER := 6;
	CONSTANT TIME_DELTA : TIME    := 6 ns;

	SIGNAL clk_s    : std_logic := '0';
	SIGNAL reset_s  : std_logic;
	SIGNAL clk_en_s : std_logic;
	SIGNAL start_s  : std_logic;
	SIGNAL done_s   : std_logic;
	SIGNAL dataa_s  : std_logic_vector(5*N_WIDTH - 1 DOWNTO 0);
	SIGNAL result_s : STD_LOGIC_vector((N_WIDTH)*7-1 DOWNTO 0);
	SIGNAL sub_i_s  : STD_LOGIC;
	SIGNAL p_i_s    : STD_LOGIC_Vector(5*N_WIDTH - 1 DOWNTO 0);
	SIGNAL m_i_s    : STD_LOGIC_Vector(5*N_WIDTH + 1 DOWNTO 0);
	
	SIGNAL res1     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	SIGNAL res2     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	SIGNAL res3     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	SIGNAL res4     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	SIGNAL res5     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
	SIGNAL res6     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);
    SIGNAL res7     : STD_LOGIC_VECTOR(N_WIDTH - 1 DOWNTO 0);

	COMPONENT evaluator
	GENERIC (
		N      : INTEGER :=103; -- bits by coefficient
		NB_ADD : INTEGER := 6
	);
	PORT (
		-- Required by CPU
		clk    : IN std_logic;                              -- CPU system clock (always required)
		reset  : IN std_logic;                              -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                              -- Clock-qualifier (always required)
		start  : IN std_logic;                              -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic;                             -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
		dataa  : IN std_logic_vector(5 * N - 1 DOWNTO 0);       -- Operand A (always required)
		result : OUT std_logic_vector((N) * 7 - 1 DOWNTO 0) -- result (always required)

	);
	END COMPONENT;

BEGIN
	DUT : evaluator
	GENERIC MAP(
	N      => N_WIDTH,
	NB_ADD => ADD)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		dataa  => dataa_s,
		result => result_s
	);

	clk_s <= NOT clk_s AFTER TIME_DELTA;
	


	do_check_out_result : PROCESS
	BEGIN
		reset_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		reset_s <= '0';
		WAIT FOR TIME_DELTA;
		dataa_s <= (OTHERS => '0');
		WAIT FOR TIME_DELTA;
		dataa_s(0) <= '1';
		dataa_s(103) <= '1';
		dataa_s(206) <= '1';
		dataa_s(309) <= '1';
		dataa_s(412) <= '1';

		WAIT FOR TIME_DELTA;
		start_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		start_s <= '0';
		WAIT FOR 100 * TIME_DELTA;
		res7         <=                                         result_s(6 * (N_WIDTH)  + (N_WIDTH) - 1 DOWNTO 6 * (N_WIDTH)) ;
		res6         <=                                         result_s(5 * (N_WIDTH)  + (N_WIDTH) - 1 DOWNTO 5 * (N_WIDTH)) ;
	    res5		 <=		                                    result_s(4 * (N_WIDTH)  + (N_WIDTH) - 1  DOWNTO 4 * (N_WIDTH)) ;
	    res4		 <=		                                    result_s(3 *(N_WIDTH)  + (N_WIDTH) - 1  DOWNTO 3 * (N_WIDTH)) ;
	    res3		 <=		                                    result_s(2 * (N_WIDTH)  + (N_WIDTH) - 1  DOWNTO 2 * (N_WIDTH)) ;
	    res2		 <=		                                    result_s(1 * (N_WIDTH)  + (N_WIDTH) - 1   DOWNTO 1 * (N_WIDTH)) ;
	    res1		 <=		                                    result_s(0 * (N_WIDTH)  + (N_WIDTH) - 1    DOWNTO 0) ;

		WAIT;
	END PROCESS do_check_out_result;

END ARCHITECTURE;
