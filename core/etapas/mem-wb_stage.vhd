-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- No es estrictamente necesario aquí pero es buena práctica

-- Suponiendo que el componente DataMemory está disponible, posiblemente desde 'work.ram' o similar
library work;
-- use work.ram.all; -- Si DataMemory está definido en un paquete 'ram' en 'work'

entity mem_wb_stage is
    Port (
        -- Entradas desde el Registro ID-EX/MEM-WB
        clk_i               : in  STD_LOGIC; -- Reloj para la Memoria de Datos
        reset_i             : in  STD_LOGIC; -- Reset para la Memoria de Datos
        
        ALUResult_i         : in  STD_LOGIC_VECTOR(31 downto 0); -- Resultado de la ALU
        WriteDataMem_i      : in  STD_LOGIC_VECTOR(31 downto 0); -- Dato a escribir en memoria (para SW)
        WriteRegAddr_i      : in  STD_LOGIC_VECTOR(4 downto 0);  -- Dirección del registro destino

        -- Señales de control desde el Registro ID-EX/MEM-WB
        RegWrite_i          : in  STD_LOGIC; -- Habilita la escritura en registro
        MemRead_i           : in  STD_LOGIC; -- Habilita la lectura de memoria
        MemWrite_i          : in  STD_LOGIC; -- Habilita la escritura en memoria
        MemToReg_i          : in  STD_LOGIC; -- Selecciona la fuente de datos para write-back (Mem vs ALU)

        -- Salidas al Archivo de Registros
        WriteRegData_o      : out STD_LOGIC_VECTOR(31 downto 0); -- Dato a escribir en el archivo de registros
        WriteRegAddr_o      : out STD_LOGIC_VECTOR(4 downto 0);  -- Dirección del registro destino
        RegWriteEnable_o    : out STD_LOGIC                      -- Para habilitar la escritura en el Archivo de Registros
    );
end mem_wb_stage;

architecture Behavioral of mem_wb_stage is
    -- Señal para el dato leído desde la Memoria de Datos
    signal s_mem_read_data : std_logic_vector(31 downto 0);

    -- Componente para la Memoria de Datos (asegúrese de que coincida con su componente Memory real)
    component Memory is
        port (
            Clk         : in  std_logic;
            Reset       : in  std_logic;
            RdStb       : in  std_logic;
            WrStb       : in  std_logic;
            Addr        : in  std_logic_vector(31 downto 0);
            DataIn      : in  std_logic_vector(31 downto 0);
            DataOut     : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    -- Instanciar Memoria de Datos
    -- La dirección para las operaciones de memoria proviene del resultado de la ALU.
    -- El dato a escribir en memoria (para SW) proviene de WriteDataMem_i.
    data_memory_inst: entity work.Memory -- O la entidad específica de la librería si no está directamente en 'work'
        port map (
            Clk       => clk_i,
            Reset     => reset_i,
            RdStb     => MemRead_i,
            WrStb     => MemWrite_i,
            Addr      => ALUResult_i,
            DataIn    => WriteDataMem_i,
            DataOut   => s_mem_read_data
        );

    -- Mux de Write-Back: Selecciona el dato a escribir en el archivo de registros.
    -- Si MemToReg_i es '1', el dato proviene de la memoria (LW).
    -- De lo contrario, el dato proviene del resultado de la ALU (tipo R, ALU tipo I).
    WriteRegData_o <= s_mem_read_data when MemToReg_i = '1' else
                      ALUResult_i;

    -- Pasar la dirección del registro destino y la señal de habilitación RegWrite
    WriteRegAddr_o   <= WriteRegAddr_i;
    RegWriteEnable_o <= RegWrite_i;

end Behavioral;
