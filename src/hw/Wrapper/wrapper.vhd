-------------------------------------------------------------------------------
-- Title : wrapper
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : wrapper.vhd
-- Author : Heraief Nathan
-- Created : 20 Mar 2019
-- Last update: 20 Mar 2019
-------------------------------------------------------------------------------
-- Description: wrapper
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
------------------------------------------------------------------------------

ENTITY wrapper IS

	PORT (
		-- Required by CPU
		clk    : IN std_logic;                              -- CPU system clock (always required)
		reset  : IN std_logic;                              -- CPU master asynchronous active high reset (always required)
		clk_en : IN std_logic;                              -- Clock-qualifier (always required)
		start  : IN std_logic;                              -- Active high signal used to specify that inputs are valid (always required)
		done   : OUT std_logic                            -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle
	);
END wrapper;


architecture rtl of wrapper is

  COMPONENT evaluator
  GENERIC (
    N      : INTEGER := 103; -- bits by coefficient
    NB_ADD : INTEGER := 6
  );
  PORT (
    -- Required by CPU
    clk    : IN std_logic;                              -- CPU system clock (always required)
    reset  : IN std_logic;                              -- CPU master asynchronous active high reset (always required)
    clk_en : IN std_logic;                              -- Clock-qualifier (always required)
    start  : IN std_logic;                              -- Active high signal used to specify that inputs are valid (always required)
    done   : OUT std_logic;                             -- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
    dataa  : IN std_logic_vector(5 * (N) - 1 DOWNTO 0); -- Operand A (always required)
    result : OUT std_logic_vector((N) * 7 - 1 DOWNTO 0) -- result (always required)

  );
	END COMPONENT;

  SIGNAL start_s       : std_logic;
  SIGNAL clk_s         : std_logic;
  SIGNAL reset_s       : std_logic;
  SIGNAL clk_en_s      : std_logic;
  SIGNAL done_s        : std_logic;
  SIGNAL dataa_s       : std_logic_vector(514 DOWNTO 0);
  SIGNAL result_s       : std_logic_vector(720 DOWNTO 0);

BEGIN

MODULE : evaluator
PORT MAP(
  clk    => clk_s,
  reset  => reset_s,
  clk_en => clk_en_s,
  start  => start_s,
  done   => done_s,
  dataa  => dataa_s,
  result => result_s
);

clk_s <= clk;
reset_s <= reset;
start_s <= start;

dataa_s <= (others => '0') ;

end architecture;
