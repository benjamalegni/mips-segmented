-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mux2_1 is
    generic (
        N : integer := 32  -- Tamaño del bus de direcciones
    );
    port (
        mux_ctl  : in  std_logic;                     -- Señal de control
        mux_in0  : in  std_logic_vector(N-1 downto 0); -- Entrada de dirección 0
        mux_in1  : in  std_logic_vector(N-1 downto 0); -- Entrada de dirección 1
        mux_out  : out std_logic_vector(N-1 downto 0)  -- Salida seleccionada
    );
end entity mux2_1;

architecture Behavioral of mux2_1 is
begin
    mux_out <= mux_in0 when mux_ctl = '0' else mux_in1;
end architecture Behavioral;
