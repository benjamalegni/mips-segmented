-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sign_extend is
    Port (
        -- Entrada: Campo inmediato de 16 bits (instrucciones tipo I)
        imm_16 : in  STD_LOGIC_VECTOR(15 downto 0);
        -- Salida: Valor extendido a 32 bits (preservando el signo)
        imm_32 : out STD_LOGIC_VECTOR(31 downto 0)
    );
end sign_extend;

architecture Behavioral of sign_extend is
begin
    -- Lógica de extensión de signo
    imm_32 <= x"FFFF" & imm_16 when imm_16(15) = '1' else  -- Negativo
              x"0000" & imm_16;                            -- Positivo
end Behavioral;
