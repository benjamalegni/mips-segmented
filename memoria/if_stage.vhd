-- ===========
-- =======    Arquitectura de Computadoras 1 - 2025
-- ==  Etapa IF del Pipeline MIPS
-- ==  Conecta la memoria de instrucciones con el registro IF/ID
-- ======================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity if_stage is
    Port ( 
        Clk         : in  STD_LOGIC;
        Reset       : in  STD_LOGIC;
        PC          : in  STD_LOGIC_VECTOR(31 downto 0);  -- Program Counter
        ID_Inst     : out STD_LOGIC_VECTOR(31 downto 0)   -- Instrucción para la etapa ID
    );
end if_stage;

architecture Behavioral of if_stage is
    -- Señales internas
    signal IF_Inst : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Componente Memory (Instruction Memory)
    component Memory is
        generic(
            C_FUNC_CLK    : std_logic := '1';
            C_ELF_FILENAME    : string := "program";
            C_MEM_SIZE        : integer := 1024
        );
        Port ( 
            Addr    : in  std_logic_vector(31 downto 0);
            DataIn  : in  std_logic_vector(31 downto 0);
            RdStb   : in  std_logic;
            WrStb   : in  std_logic;
            Clk     : in  std_logic;
            Reset   : in  std_logic;
            DataOut : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Componente reg_if_id
    component reg_if_id is
        Port ( 
            Clk     : in  STD_LOGIC;
            Reset   : in  STD_LOGIC;
            IF_Inst : in  STD_LOGIC_VECTOR(31 downto 0);
            ID_Inst : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin
    -- Instancia de la memoria de instrucciones
    inst_memory: Memory
        generic map (
            C_FUNC_CLK => '1',
            C_ELF_FILENAME => "program",
            C_MEM_SIZE => 1024
        )
        port map (
            Addr    => PC,
            DataIn  => (others => '0'),  -- No se escribe en la memoria de instrucciones
            RdStb   => '1',              -- Siempre leemos instrucciones
            WrStb   => '0',              -- No escribimos en la memoria de instrucciones
            Clk     => Clk,
            Reset   => Reset,
            DataOut => IF_Inst
        );

    -- Instancia del registro IF/ID
    inst_reg_if_id: reg_if_id
        port map (
            Clk     => Clk,
            Reset   => Reset,
            IF_Inst => IF_Inst,
            ID_Inst => ID_Inst
        );

end Behavioral; 