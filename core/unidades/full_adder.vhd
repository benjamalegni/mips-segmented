-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NBitAdder is
    generic (
        N : integer := 32  -- Default size of 32 bits
    );
    port (
        A     : in  std_logic_vector(N-1 downto 0);  -- First operand
        B     : in  std_logic_vector(N-1 downto 0);  -- Second operand
        CIN   : in  std_logic;                       -- Input carry
        SUM   : out std_logic_vector(N-1 downto 0);  -- Sum result
        COUT  : out std_logic                        -- Output carry
    );
end entity NBitAdder;

architecture Behavioral of NBitAdder is
    signal temp_sum : unsigned(N downto 0);
begin
    -- Add the two numbers and the input carry
    temp_sum <= unsigned('0' & A) + unsigned('0' & B) + unsigned'('0' & CIN);
    
    -- Assign the result and the output carry
    SUM  <= std_logic_vector(temp_sum(N-1 downto 0));
    COUT <= temp_sum(N);
end architecture Behavioral;
