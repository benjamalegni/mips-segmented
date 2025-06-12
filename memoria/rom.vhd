-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity imem is
    port (
        ADDR_IN  : in  std_logic_vector(31 downto 0);  -- Dirección de 32 bits
        INSTR_OUT: out std_logic_vector(31 downto 0)   -- Instrucción de 32 bits
    );
end entity imem;

architecture Behavioral of imem is
    -- Memoria de instrucciones (ROM)
    type mem_type is array (0 to 255) of std_logic_vector(31 downto 0);
    signal mem : mem_type := (
        -- Aquí se pueden inicializar las instrucciones
        -- Por ejemplo:
        x"00000000",  -- nop
        x"00000000",  -- nop
        x"00000000",  -- nop
        x"00000000",  -- nop
        others => x"00000000"
    );
begin
    -- Lectura de la memoria (combinacional)
    INSTR_OUT <= mem(to_integer(unsigned(ADDR_IN(9 downto 2))));
end architecture Behavioral;
