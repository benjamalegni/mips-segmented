-- ===========
-- =======    Arquitectura de Computadoras 1 - 2025
-- ==  Registro IF-ID del Pipeline MIPS
-- ==  Este registro almacena la instrucción entre las etapas IF e ID
-- ======================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Importar componentes
use work.mux2_1;
use work.full_adder;

entity reg_if_id is
    Port ( 
        Clk     : in  STD_LOGIC;
        Reset   : in  STD_LOGIC;
        IF_Inst : in  STD_LOGIC_VECTOR(31 downto 0);  -- Instrucción del IF
        ID_Inst : out STD_LOGIC_VECTOR(31 downto 0)   -- Instrucción para el ID
    );
end reg_if_id;

architecture Behavioral of reg_if_id is
    signal reg_inst : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    -- Proceso sincrónico para el registro
    process(Clk, Reset)
    begin
        if Reset = '1' then
            -- Reset asíncrono: limpia el registro
            reg_inst <= (others => '0');
        elsif rising_edge(Clk) then
            -- En el flanco ascendente del reloj, captura la nueva instrucción
            reg_inst <= IF_Inst;
        end if;
    end process;

    -- Asignación combinacional de la salida
    ID_Inst <= reg_inst;

end Behavioral;
