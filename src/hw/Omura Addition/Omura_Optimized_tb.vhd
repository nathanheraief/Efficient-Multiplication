
-------------------------------------------------------------------------------
-- Title : Omura_Optimized_tb
-- Project : Efficient multiplication
-------------------------------------------------------------------------------
-- File : Omura_Optimized_tb.vhd
-- Author : Heraief Nathan
-- Created : 18 Feb 2019
-- Last update: 12 Mar 2019
-------------------------------------------------------------------------------
-- Description: Testbench for Omura_Optimized_tb
--
------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
-------------------------------------
ENTITY Omura_Optimized_tb IS
END Omura_Optimized_tb;

ARCHITECTURE arch OF Omura_Optimized_tb IS

	CONSTANT N_WIDTH    : INTEGER := 577;
	CONSTANT TIME_DELTA : TIME    := 6 ns;

	SIGNAL clk_s    : std_logic := '0';
	SIGNAL reset_s  : std_logic;
	SIGNAL clk_en_s : std_logic;
	SIGNAL start_s  : std_logic;
	SIGNAL done_s   : std_logic;
	SIGNAL dataa_s  : std_logic_vector(N_WIDTH DOWNTO 0);
	SIGNAL datab_s  : std_logic_vector(N_WIDTH DOWNTO 0);
	SIGNAL result_s : STD_LOGIC_vector(N_WIDTH + 1 DOWNTO 0);
	SIGNAL sub_i_s  : STD_LOGIC;
	SIGNAL p_i_s    : STD_LOGIC_Vector(N_WIDTH - 1 DOWNTO 0);
	SIGNAL m_i_s    : STD_LOGIC_Vector(N_WIDTH + 1 DOWNTO 0);

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
	DUT : Omura_Optimized
	GENERIC MAP(N => N_WIDTH)
	PORT MAP(
		clk    => clk_s,
		reset  => reset_s,
		clk_en => clk_en_s,
		start  => start_s,
		done   => done_s,
		dataa  => dataa_s,
		datab  => datab_s,
		result => result_s,
		sub_i  => sub_i_s,
		p_i    => p_i_s,
		m_i    => m_i_s
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
		WAIT FOR TIME_DELTA;
		dataa_s(N_WIDTH - 1) <= '1';
		--datab_s(N_WIDTH) <= '1';

		p_i_s   <= "0010111011010111110101010011100010101101010011010110101100000011010110011100101001111010000001001010000011100010000011111111100010011001011010010100110111001001000110010100011000011100110100000110100011100111101110011110100001110001111001011001011110110111011010010011000010000010001001101010100000110001010000010011010001110110110110011011111100001100110110111010110100101001111111100000010100111101111101011000010110011001001001101011110001110110001001101011000000010001000100111101000110110100001100100110101110101010101001011001010011100110110000111000010010000001100000001";
		m_i_s   <= "001010001001010000010101011000111010100101011001010010100111111001010011000110101100001011111101101011111000111011111000000000111011001101001011010110010001101101110011010111001111000110010111110010111000110000100011000010111100011100001101001101000010010001001011011001111011111011101100101010111110011101011111011001011100010010010011001000000111100110010010001010010110101100000000111111010110000100000101001111010011001101101100101000011100010011101100101001111111011101110110000101110010010111100110110010100010101010101101001101011000110010011110001111011011111100111111110";
		sub_i_s <= '0';
		WAIT FOR TIME_DELTA;
		start_s <= '1';
		WAIT FOR 2 * TIME_DELTA;
		start_s <= '0';
		WAIT;
	END PROCESS do_check_out_result;

END ARCHITECTURE;
