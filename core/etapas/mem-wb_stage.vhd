library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Importar componentes necesarios
library work;
use work.ram.all;

entity mem_wb_stage is
    Port (
        -- Señales básicas
        clk     : in  STD_LOGIC;                    -- Reloj
        reset   : in  STD_LOGIC;                    -- Reset
        
        -- Entradas de la etapa MEM
        direccion_in    : in std_logic_vector(31 downto 0);  -- Dirección de memoria
        mem_wr_data     : in std_logic_vector(31 downto 0);  -- Dato a escribir
        mem_read        : in std_logic;                      -- Lectura memoria
        mem_write       : in std_logic;                      -- Escritura memoria
        mem_to_reg      : in std_logic;                      -- Memoria a registro
        branch          : in std_logic;                      -- Señal branch
        alu_zero        : in std_logic;                      -- Flag cero ALU

        -- Salidas
        read_data_out   : out std_logic_vector(31 downto 0); -- Dato leído
        branch_out      : out std_logic                       -- Señal branch final
    );
end mem_wb_stage;

architecture Behavioral of mem_wb_stage is
    -- Señales internas
    signal read_data : std_logic_vector(31 downto 0);  -- Dato leído de memoria
    signal mux_out   : std_logic_vector(31 downto 0);  -- Salida del multiplexor

    -- Componente memoria de datos
    component DataMemory is
        port (
            CLK         : in  std_logic;                     -- Reloj
            RESET       : in  std_logic;                     -- Reset
            MemRead     : in  std_logic;                     -- Lectura
            MemWrite    : in  std_logic;                     -- Escritura
            Address     : in  std_logic_vector(31 downto 0); -- Dirección
            WriteData   : in  std_logic_vector(31 downto 0); -- Dato escritura
            ReadData    : out std_logic_vector(31 downto 0)  -- Dato lectura
        );
    end component;

begin
    -- Instanciar memoria de datos
    data_mem: DataMemory port map (
        CLK => clk,
        RESET => reset,
        MemRead => mem_read,
        MemWrite => mem_write,
        Address => direccion_in,
        WriteData => mem_wr_data,
        ReadData => read_data
    );

    -- Multiplexor para seleccionar entre memoria y ALU
    mux_out <= read_data when (mem_to_reg = '1') else mem_wr_data;

    -- Lógica de branch (AND entre branch y alu_zero)
    branch_out <= branch and alu_zero;

    -- Conectar salida del multiplexor al puerto de salida
    read_data_out <= mux_out;

end Behavioral;
