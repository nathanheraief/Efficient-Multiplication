-------------------------------------------------------------------------------
-- Title : Omura Addition
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
------------------------------------------------------------------------------

ENTITY Omura IS
	PORT (
  -- Required by CPU
  clk: in std_logic;				-- CPU system clock (always required)
	reset: in std_logic;				-- CPU master asynchronous active high reset (always required)
	clk_en: in std_logic;				-- Clock-qualifier (always required)
	start: in std_logic;				-- Active high signal used to specify that inputs are valid (always required)
	done: out std_logic;				-- Active high signal used to notify the CPU that result is valid (required for variable multi-cycle)
	dataa: in std_logic_vector(255 downto 0);		-- Operand A (always required)
	datab: in std_logic_vector(255 downto 0);		-- Operand B (optional)
	result: out std_logic_vector(255 downto 0)	-- result (always required)

  --Custom I/O
    sub_i     : IN std_logic;
    p_i       : IN std_logic_vector(255 down to 0);
    m_i       : IN std_logic_vector(255 down to 0)
	);
END ENTITY Omura;


architecture rtl of Omura is
    -- State signals
    type state_T is (Idle, Shift, Valid, WaitState);
    signal current_s, next_s: state_T;

    -- Other signals
    signal dataa_p: STD_LOGIC_VECTOR(255 downto 0);
    signal dataa_f: STD_LOGIC_VECTOR(255 downto 0);
    signal datab_p: STD_LOGIC_VECTOR(255 downto 0);
    signal datab_f: STD_LOGIC_VECTOR(255 downto 0);
    signal valid_p: STD_LOGIC;
    signal valid_f: STD_LOGIC;


    synchrone_ASM: process(clk, reset)
    begin
        if(reset = '1') then
            current_s <= Idle;
            dataa_p <= (others => '0');
            datab_p <= (others => '0');
            valid_p <= '0';
        elsif(clk'event and clk = '1') then
            current_s <= next_s;
            dataa_p <= dataa_f;
            datab_p <= datab_f;
            valid_p <= valid_f;
        end if;
    end process;

    asynchrone_ASM: process(sub_i, valueIn, current_s, dataa_p, datab_p)
    begin
        case current_s is
            when Idle => if(sub_i = '1') then
                            next_s <= Comp;
                         else
                            next_s <= Idle;
                         end if;
                         valid_f <= '0';
                         dataa_f <= dataa
                         datab_f <= datab

            when Comp => if(val AND (1<< (256-1))  != '0') then
                            datab_f <= datab_p - (1<< (256-1));
                          end if;
                          valid_f <= '0';
                          next_s <= Add;

            when Add => if(doneIn = '1') then
                            next_s <= Shift;
                            --bufferValues_f <= valueIn & bufferValues_p(9 downto 1);
                            bufferValues_f <= bufferValues_p(8 downto 0) & valueIn ;
                          else
                            next_s <= WaitState;
                            bufferValues_f <= bufferValues_p;
                          end if;
                          valid_f <= '0';

            when others => if(doneIn = '0') then
                              next_s <= Valid;
                              bufferValues_f <= bufferValues_p;
                           else
                              next_s <= Shift;
                              --bufferValues_f <= valueIn & bufferValues_p(9 downto 1);
                              bufferValues_f <= bufferValues_p(8 downto 0) & valueIn ;
                           end if;
                           valid_f <= '0';
        end case;
    end process;
