-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;      -- Para operador +
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- Para operador + con std_logic_vector

entity IF_stage is
    Port (
        clk : in std_logic;
        reset : in std_logic;

        -- Entradas para la lógica de selección de PC (típicamente desde la etapa ID-EX)
        PCSrc_i              : in std_logic_vector(1 downto 0);
        Branch_Target_Addr_i : in std_logic_vector(31 downto 0);
        Jump_Target_Addr_i   : in std_logic_vector(31 downto 0);

        -- Señales de control del pipeline
        Flush_Reg_i          : in std_logic;
        Stall_Reg_i          : in std_logic;

        -- Salidas al Registro IF/ID-EX
        Reg_IF_ID_out           : out std_logic_vector(31 downto 0); -- Instrucción
        Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0)  -- PC+4
    );
end IF_stage;

architecture Behavioral of IF_stage is
    signal s_pc_plus_4 : std_logic_vector(31 downto 0);
    signal PC_out      : std_logic_vector(31 downto 0); -- PC actual
    signal PC_in       : std_logic_vector(31 downto 0); -- Próximo PC (entrada al registro de PC)
    signal s_inst_mem_data_out : std_logic_vector(31 downto 0); -- Datos de la memoria de instrucciones

    -- Componente para la Memoria de Instrucciones (suponiendo que está definido en otro lugar o como 'work.Memory')
    component Memory is
        generic(
            C_FUNC_CLK : std_logic := '1';
            C_ELF_FILENAME : string := "program";
            C_MEM_SIZE : integer := 1024
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

    -- Componente para el Registro IF/ID-EX (reg_if_id)
    component reg_if_id is
        Port (
            clk            : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            flush          : in  STD_LOGIC;
            stall          : in  STD_LOGIC;
            PC_plus_4_in   : in  STD_LOGIC_VECTOR(31 downto 0);
            Instruction_in : in  STD_LOGIC_VECTOR(31 downto 0);
            PC_plus_4_out  : out STD_LOGIC_VECTOR(31 downto 0);
            Instruction_out: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin

    -- Registro de PC: Mantiene el contador de programa actual
    process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
        elsif rising_edge(clk) then
            if Stall_Reg_i = '0' then -- Solo actualizar PC si no está bloqueado
                PC_out <= PC_in;
            end if;
        end if;
    end process;

    -- Cálculo de PC+4: Basado en el PC_out actual
    s_pc_plus_4 <= PC_out + 4;

    -- Lógica de Selección del Próximo PC: Determina el valor para PC_in
    with PCSrc_i select
        PC_in <= s_pc_plus_4          when "00",     -- Por defecto a PC+4
                 Branch_Target_Addr_i when "01",     -- Bifurcación
                 Jump_Target_Addr_i   when "10",     -- Salto
                 s_pc_plus_4          when others;   -- Por defecto a PC+4 para "11" o cualquier otro estado indefinido

    -- Instancia de la Memoria de Instrucciones
    inst_memory: Memory
        generic map (
            C_FUNC_CLK     => '1',       -- Suponiendo que clk maneja la memoria directamente si es necesario
            C_ELF_FILENAME => "program", -- Archivo de programa por defecto
            C_MEM_SIZE     => 1024      -- Tamaño de memoria por defecto
        )
        port map (
            Addr    => PC_out, -- Dirección desde el PC actual
            DataIn  => (others => '0'), -- No se escribe en la memoria de instrucciones aquí
            RdStb   => '1',             -- Siempre leyendo
            WrStb   => '0',             -- Nunca escribiendo
            Clk     => clk,             -- Reloj del sistema
            Reset   => reset,           -- Reset del sistema
            DataOut => s_inst_mem_data_out
        );

    -- Instancia del Registro IF/ID-EX
    inst_reg_if_id: reg_if_id
        port map (
            clk             => clk,
            reset           => reset,
            flush           => Flush_Reg_i,
            stall           => Stall_Reg_i,
            PC_plus_4_in    => s_pc_plus_4,
            Instruction_in  => s_inst_mem_data_out,
            PC_plus_4_out   => Reg_IF_ID_PC_plus_4_out,
            Instruction_out => Reg_IF_ID_out
        );

end Behavioral;