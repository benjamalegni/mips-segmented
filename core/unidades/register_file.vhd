-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    Port (
        clk_i           : in  STD_LOGIC;
        reset_i         : in  STD_LOGIC; -- Opcional: para reiniciar los valores de los registros

        ReadAddr1_i     : in  STD_LOGIC_VECTOR(4 downto 0);
        ReadAddr2_i     : in  STD_LOGIC_VECTOR(4 downto 0);

        WriteAddr_i     : in  STD_LOGIC_VECTOR(4 downto 0);
        WriteData_i     : in  STD_LOGIC_VECTOR(31 downto 0);
        RegWrite_i      : in  STD_LOGIC; -- Habilitación de escritura

        ReadData1_o     : out STD_LOGIC_VECTOR(31 downto 0);
        ReadData2_o     : out STD_LOGIC_VECTOR(31 downto 0)
    );
end register_file;

architecture Behavioral of register_file is
    -- Declarar el tipo para el array de registros (32 registros, 32 bits cada uno)
    type reg_array_t is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);

    -- Declarar la señal del archivo de registros, inicializada a ceros
    -- Usar 'signal' lo convierte en un elemento registrado, sensible al reloj para las escrituras.
    -- Para simulación, los valores iniciales se pueden establecer aquí. Para síntesis, se prefiere el reset.
    signal regs : reg_array_t := (others => (others => '0'));

    -- Constante para la dirección del registro cero
    constant ZERO_REG_ADDR : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

begin

    -- Puerto de Lectura 1 (lectura combinacional)
    -- El registro $0 siempre lee como 0
    ReadData1_o <= (others => '0') when ReadAddr1_i = ZERO_REG_ADDR else
                   regs(to_integer(unsigned(ReadAddr1_i)));

    -- Puerto de Lectura 2 (lectura combinacional)
    -- El registro $0 siempre lee como 0
    ReadData2_o <= (others => '0') when ReadAddr2_i = ZERO_REG_ADDR else
                   regs(to_integer(unsigned(ReadAddr2_i)));

    -- Puerto de Escritura (escritura síncrona)
    write_process: process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            -- Opcional: Reiniciar todos los registros a cero.
            -- Esto podría consumir muchos recursos en FPGAs si no se optimiza.
            -- A menudo, se realiza la inicialización individual de registros o se confía en el arranque del sistema.
            -- Para este ejemplo, incluyamos un reset completo.
            regs <= (others => (others => '0'));
        elsif rising_edge(clk_i) then
            if RegWrite_i = '1' and WriteAddr_i /= ZERO_REG_ADDR then
                -- Solo escribir si RegWrite está activo y no se está escribiendo en el registro $0
                regs(to_integer(unsigned(WriteAddr_i))) <= WriteData_i;
            end if;
        end if;
    end process write_process;

end Behavioral;
