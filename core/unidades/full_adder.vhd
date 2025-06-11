library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NBitAdder is
    generic (
        N : integer := 32  -- Tamaño por defecto de 32 bits
    );
    port (
        A     : in  std_logic_vector(N-1 downto 0);  -- Primer operando
        B     : in  std_logic_vector(N-1 downto 0);  -- Segundo operando
        CIN   : in  std_logic;                       -- Acarreo de entrada
        SUM   : out std_logic_vector(N-1 downto 0);  -- Resultado de la suma
        COUT  : out std_logic                        -- Acarreo de salida
    );
end entity NBitAdder;

architecture Behavioral of NBitAdder is
    signal temp_sum : unsigned(N downto 0);
begin
    -- Suma los dos números y el acarreo de entrada
    temp_sum <= unsigned('0' & A) + unsigned('0' & B) + unsigned'('0' & CIN);
    
    -- Asigna el resultado y el acarreo de salida
    SUM  <= std_logic_vector(temp_sum(N-1 downto 0));
    COUT <= temp_sum(N);
end architecture Behavioral;