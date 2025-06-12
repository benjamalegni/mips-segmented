-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work; -- Suponiendo que los componentes se compilan en work

entity MIPS is
    port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC
    );
end MIPS;

architecture Behavioral of MIPS is

    -- Declaraciones de Componentes --

    component if_stage is
        Port (
            clk                     : in  std_logic;
            reset                   : in  std_logic;
            PCSrc_i                 : in  std_logic_vector(1 downto 0);
            Branch_Target_Addr_i    : in  std_logic_vector(31 downto 0);
            Jump_Target_Addr_i      : in  std_logic_vector(31 downto 0);
            Flush_Reg_i             : in  std_logic;
            Stall_Reg_i             : in  std_logic; -- Controlado por la Unidad de Riesgos PC_Stall
            Reg_IF_ID_out           : out std_logic_vector(31 downto 0);
            Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component reg_if_id is -- Actúa como Registro IF/ID-EX
        Port (
            clk            : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            flush          : in  STD_LOGIC;
            stall          : in  STD_LOGIC; -- Controlado por la Unidad de Riesgos PC_Stall
            PC_plus_4_in   : in  STD_LOGIC_VECTOR(31 downto 0);
            Instruction_in : in  STD_LOGIC_VECTOR(31 downto 0);
            PC_plus_4_out  : out STD_LOGIC_VECTOR(31 downto 0);
            Instruction_out: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component id_ex_stage is -- Componente Actualizado
        Port (
            clk                       : in  STD_LOGIC;
            reset                     : in  STD_LOGIC;
            Instruction_i             : in  STD_LOGIC_VECTOR(31 downto 0);
            PC_plus_4_i               : in  STD_LOGIC_VECTOR(31 downto 0);
            RegData1_i                : in  STD_LOGIC_VECTOR(31 downto 0);
            RegData2_i                : in  STD_LOGIC_VECTOR(31 downto 0);
            -- Entradas de Adelantamiento y Burbuja
            ForwardA_sel_i            : in  STD_LOGIC_VECTOR(1 downto 0);
            ForwardB_sel_i            : in  STD_LOGIC_VECTOR(1 downto 0);
            Forward_EXMEM_ALUResult_i : in  STD_LOGIC_VECTOR(31 downto 0);
            Forward_MEMWB_WriteData_i : in  STD_LOGIC_VECTOR(31 downto 0);
            Bubble_IDEX_i             : in  STD_LOGIC;
            -- Salidas
            ALUResult_o               : out STD_LOGIC_VECTOR(31 downto 0);
            WriteDataMem_o            : out STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_o            : out STD_LOGIC_VECTOR(4 downto 0);
            PC_plus_4_pass_o          : out STD_LOGIC_VECTOR(31 downto 0);
            RegWrite_o                : out STD_LOGIC;
            MemRead_o                 : out STD_LOGIC;
            MemWrite_o                : out STD_LOGIC;
            MemToReg_o                : out STD_LOGIC;
            ALU_Zero_o                : out STD_LOGIC;
            PCSrc_o                   : out STD_LOGIC_VECTOR(1 downto 0);
            Branch_Target_Addr_o      : out STD_LOGIC_VECTOR(31 downto 0);
            Jump_Target_Addr_o        : out STD_LOGIC_VECTOR(31 downto 0);
            ReadReg1Addr_o            : out STD_LOGIC_VECTOR(4 downto 0);
            ReadReg2Addr_o            : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;

    component reg_idex_memwb is -- Registro ID-EX/MEM-WB
        Port (
            clk                 : in  STD_LOGIC;
            reset               : in  STD_LOGIC;
            Flush_i             : in  STD_LOGIC;
            Stall_i             : in  STD_LOGIC; -- Stall para este registro (no desde la Unidad de Riesgos por ahora)
            ALUResult_i         : in  STD_LOGIC_VECTOR(31 downto 0);
            WriteDataMem_i      : in  STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_i      : in  STD_LOGIC_VECTOR(4 downto 0);
            PC_plus_4_pass_i    : in  STD_LOGIC_VECTOR(31 downto 0);
            ALU_Zero_i          : in  STD_LOGIC;
            RegWrite_i          : in  STD_LOGIC;
            MemRead_i           : in  STD_LOGIC;
            MemWrite_i          : in  STD_LOGIC;
            MemToReg_i          : in  STD_LOGIC;
            ALUResult_o         : out STD_LOGIC_VECTOR(31 downto 0);
            WriteDataMem_o      : out STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_o      : out STD_LOGIC_VECTOR(4 downto 0);
            PC_plus_4_pass_o    : out STD_LOGIC_VECTOR(31 downto 0);
            ALU_Zero_o          : out STD_LOGIC;
            RegWrite_o          : out STD_LOGIC;
            MemRead_o           : out STD_LOGIC;
            MemWrite_o          : out STD_LOGIC;
            MemToReg_o          : out STD_LOGIC
        );
    end component;

    component mem_wb_stage is
        Port (
            clk_i               : in  STD_LOGIC;
            reset_i             : in  STD_LOGIC;
            ALUResult_i         : in  STD_LOGIC_VECTOR(31 downto 0);
            WriteDataMem_i      : in  STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_i      : in  STD_LOGIC_VECTOR(4 downto 0);
            RegWrite_i          : in  STD_LOGIC;
            MemRead_i           : in  STD_LOGIC;
            MemWrite_i          : in  STD_LOGIC;
            MemToReg_i          : in  STD_LOGIC;
            WriteRegData_o      : out STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_o      : out STD_LOGIC_VECTOR(4 downto 0);
            RegWriteEnable_o    : out STD_LOGIC
        );
    end component;

    component register_file is
        Port (
            clk_i           : in  STD_LOGIC;
            reset_i         : in  STD_LOGIC;
            ReadAddr1_i     : in  STD_LOGIC_VECTOR(4 downto 0);
            ReadAddr2_i     : in  STD_LOGIC_VECTOR(4 downto 0);
            WriteAddr_i     : in  STD_LOGIC_VECTOR(4 downto 0);
            WriteData_i     : in  STD_LOGIC_VECTOR(31 downto 0);
            RegWrite_i      : in  STD_LOGIC;
            ReadData1_o     : out STD_LOGIC_VECTOR(31 downto 0);
            ReadData2_o     : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    -- Nuevo Componente HazardUnit
    component HazardUnit is
        Port (
            IF_ID_Rs_addr_i      : in  STD_LOGIC_VECTOR(4 downto 0);
            IF_ID_Rt_addr_i      : in  STD_LOGIC_VECTOR(4 downto 0);
            -- IF_ID_Inst_is_LW_i   : in  STD_LOGIC; -- Eliminado de HU según su definición
            EXMEM_RegWrite_i     : in  STD_LOGIC;
            EXMEM_WriteRegAddr_i : in  STD_LOGIC_VECTOR(4 downto 0);
            EXMEM_MemToReg_i     : in  STD_LOGIC;
            MEMWB_RegWrite_i     : in  STD_LOGIC;
            MEMWB_WriteRegAddr_i : in  STD_LOGIC_VECTOR(4 downto 0);
            ForwardA_sel_o       : out STD_LOGIC_VECTOR(1 downto 0);
            ForwardB_sel_o       : out STD_LOGIC_VECTOR(1 downto 0);
            PC_Stall_o           : out STD_LOGIC;
            IF_ID_Reg_Stall_o    : out STD_LOGIC; -- Salida de HU
            IDEX_Bubble_o        : out STD_LOGIC
        );
    end component;

    -- Señales para salidas de la Etapa IF / entradas del Registro IF-IDEX
    signal s_if_Instruction_to_reg : std_logic_vector(31 downto 0);
    signal s_if_PC_plus_4_to_reg   : std_logic_vector(31 downto 0);

    -- Señales para salidas del Registro IF-IDEX / entradas de la Etapa ID-EX
    signal s_idex_Instruction_i    : std_logic_vector(31 downto 0);
    signal s_idex_PC_plus_4_i      : std_logic_vector(31 downto 0);

    -- Rs/Rt extraídos de IF/ID para entrada de la Unidad de Riesgos
    signal s_if_id_rs_addr_for_hu : std_logic_vector(4 downto 0);
    signal s_if_id_rt_addr_for_hu : std_logic_vector(4 downto 0);

    -- Señales para conexiones del Archivo de Registros
    signal s_rf_ReadData1          : std_logic_vector(31 downto 0);
    signal s_rf_ReadData2          : std_logic_vector(31 downto 0);
    signal s_idex_ReadReg1Addr     : std_logic_vector(4 downto 0);
    signal s_idex_ReadReg2Addr     : std_logic_vector(4 downto 0);

    -- Señales para la ruta de control del PC (ID-EX a IF)
    signal s_idex_PCSrc_to_if            : std_logic_vector(1 downto 0);
    signal s_idex_Branch_Target_to_if    : std_logic_vector(31 downto 0);
    signal s_idex_Jump_Target_to_if      : std_logic_vector(31 downto 0);

    -- Señales para salidas de la Etapa ID-EX / entradas del Registro IDEX-MEMWB
    signal s_idex_ALUResult_to_reg       : std_logic_vector(31 downto 0);
    signal s_idex_WriteDataMem_to_reg    : std_logic_vector(31 downto 0);
    signal s_idex_WriteRegAddr_to_reg    : std_logic_vector(4 downto 0);
    signal s_idex_PC_plus_4_pass_to_reg  : std_logic_vector(31 downto 0);
    signal s_idex_ALU_Zero_to_reg        : std_logic;
    signal s_idex_RegWrite_to_reg        : std_logic;
    signal s_idex_MemRead_to_reg         : std_logic;
    signal s_idex_MemWrite_to_reg        : std_logic;
    signal s_idex_MemToReg_to_reg        : std_logic;

    -- Señales para salidas del Registro IDEX-MEMWB / entradas de la Etapa MEM-WB
    signal s_memwb_ALUResult_i           : std_logic_vector(31 downto 0);
    signal s_memwb_WriteDataMem_i        : std_logic_vector(31 downto 0);
    signal s_memwb_WriteRegAddr_i        : std_logic_vector(4 downto 0);
    signal s_memwb_RegWrite_i            : std_logic;
    signal s_memwb_MemRead_i             : std_logic;
    signal s_memwb_MemWrite_i            : std_logic;
    signal s_memwb_MemToReg_i            : std_logic;

    -- Señales para salidas de la Etapa MEM-WB / Puerto de Escritura del Archivo de Registros
    signal s_rf_WriteData          : std_logic_vector(31 downto 0);
    signal s_rf_WriteAddr          : std_logic_vector(4 downto 0);
    signal s_rf_RegWriteEnable     : std_logic;

    -- Señales de Control del Pipeline desde la Unidad de Riesgos
    signal s_hu_ForwardA_sel     : std_logic_vector(1 downto 0);
    signal s_hu_ForwardB_sel     : std_logic_vector(1 downto 0);
    signal s_hu_PC_Stall         : std_logic;
    signal s_hu_IDEX_Bubble      : std_logic;
    signal s_hu_IF_ID_Reg_Stall_unused : std_logic; -- Para el puerto de salida de HU

    -- Otras Señales de Control del Pipeline
    signal s_Flush_IFIDEX_Reg      : std_logic;
    signal s_Stall_IDEXMEMWB_Reg   : std_logic := '0';
    signal s_Flush_IDEXMEMWB_Reg   : std_logic := '0';

begin

    -- Determinar si el registro IF/IDEX debe ser vaciado (si se decide salto o bifurcación en IDEX)
    s_Flush_IFIDEX_Reg <= '1' when s_idex_PCSrc_to_if = "01" or s_idex_PCSrc_to_if = "10" else '0';

    -- Extraer Rs/Rt de la instrucción en la etapa ID/EX (salida del registro IF/ID) para la Unidad de Riesgos
    s_if_id_rs_addr_for_hu <= s_idex_Instruction_i(25 downto 21);
    s_if_id_rt_addr_for_hu <= s_idex_Instruction_i(20 downto 16);

    -- Instanciación de la Unidad de Riesgos
    hazard_unit_inst : entity work.HazardUnit
        port map (
            IF_ID_Rs_addr_i      => s_if_id_rs_addr_for_hu,
            IF_ID_Rt_addr_i      => s_if_id_rt_addr_for_hu,
            -- IF_ID_Inst_is_LW_i   => '0', -- Esta entrada fue eliminada de la definición de HU.
            EXMEM_RegWrite_i     => s_memwb_RegWrite_i,     -- RegWrite desde la salida del registro EX/MEM (s_memwb_... son salidas de reg_idex_memwb)
            EXMEM_WriteRegAddr_i => s_memwb_WriteRegAddr_i, -- WriteRegAddr desde la salida del registro EX/MEM
            EXMEM_MemToReg_i     => s_memwb_MemToReg_i,     -- MemToReg desde la salida del registro EX/MEM
            MEMWB_RegWrite_i     => s_rf_RegWriteEnable,    -- RegWrite desde la salida de la etapa MEM/WB (alimenta a RF)
            MEMWB_WriteRegAddr_i => s_rf_WriteAddr,         -- WriteRegAddr desde la salida de la etapa MEM/WB (alimenta a RF)
            ForwardA_sel_o       => s_hu_ForwardA_sel,
            ForwardB_sel_o       => s_hu_ForwardB_sel,
            PC_Stall_o           => s_hu_PC_Stall,
            IF_ID_Reg_Stall_o    => s_hu_IF_ID_Reg_Stall_unused, -- HU proporciona esto, conectar PC_Stall al registro real
            IDEX_Bubble_o        => s_hu_IDEX_Bubble
        );

    -- Etapa 1: Búsqueda de Instrucción (IF)
    if_stage_inst : entity work.if_stage
        port map (
            clk                     => clk,
            reset                   => reset,
            PCSrc_i                 => s_idex_PCSrc_to_if,
            Branch_Target_Addr_i    => s_idex_Branch_Target_to_if,
            Jump_Target_Addr_i      => s_idex_Jump_Target_to_if,
            Flush_Reg_i             => s_Flush_IFIDEX_Reg,
            Stall_Reg_i             => s_hu_PC_Stall, -- Stall desde la Unidad de Riesgos
            Reg_IF_ID_out           => s_if_Instruction_to_reg,
            Reg_IF_ID_PC_plus_4_out => s_if_PC_plus_4_to_reg
        );

    -- Registro de Pipeline: IF/ID-EX
    if_idex_reg_inst : entity work.reg_if_id
        port map (
            clk            => clk,
            reset          => reset,
            flush          => s_Flush_IFIDEX_Reg,
            stall          => s_hu_PC_Stall, -- Stall desde la Unidad de Riesgos
            PC_plus_4_in   => s_if_PC_plus_4_to_reg,
            Instruction_in => s_if_Instruction_to_reg,
            PC_plus_4_out  => s_idex_PC_plus_4_i,
            Instruction_out=> s_idex_Instruction_i
        );

    -- Etapa 2: Decodificación de Instrucción y Ejecución (ID-EX)
    id_ex_stage_inst : entity work.id_ex_stage
        port map (
            clk                       => clk,
            reset                     => reset,
            Instruction_i             => s_idex_Instruction_i,
            PC_plus_4_i               => s_idex_PC_plus_4_i,
            RegData1_i                => s_rf_ReadData1,
            RegData2_i                => s_rf_ReadData2,
            -- Nuevos Puertos de Riesgo/Adelantamiento
            ForwardA_sel_i            => s_hu_ForwardA_sel,
            ForwardB_sel_i            => s_hu_ForwardB_sel,
            Forward_EXMEM_ALUResult_i => s_memwb_ALUResult_i,    -- ALURes desde la salida del registro EXMEM
            Forward_MEMWB_WriteData_i => s_rf_WriteData,         -- Datos WB desde la salida de la etapa MEMWB (datos a RF)
            Bubble_IDEX_i             => s_hu_IDEX_Bubble,
            -- Salidas Originales
            ALUResult_o               => s_idex_ALUResult_to_reg,
            WriteDataMem_o            => s_idex_WriteDataMem_to_reg,
            WriteRegAddr_o            => s_idex_WriteRegAddr_to_reg,
            PC_plus_4_pass_o          => s_idex_PC_plus_4_pass_to_reg,
            RegWrite_o                => s_idex_RegWrite_to_reg,
            MemRead_o                 => s_idex_MemRead_to_reg,
            MemWrite_o                => s_idex_MemWrite_to_reg,
            MemToReg_o                => s_idex_MemToReg_to_reg,
            ALU_Zero_o                => s_idex_ALU_Zero_to_reg,
            PCSrc_o                   => s_idex_PCSrc_to_if,
            Branch_Target_Addr_o      => s_idex_Branch_Target_to_if,
            Jump_Target_Addr_o        => s_idex_Jump_Target_to_if,
            ReadReg1Addr_o            => s_idex_ReadReg1Addr,
            ReadReg2Addr_o            => s_idex_ReadReg2Addr
        );

    -- Registro de Pipeline: ID-EX/MEM-WB
    idex_memwb_reg_inst : entity work.reg_idex_memwb
        port map (
            clk                 => clk,
            reset               => reset,
            Flush_i             => s_Flush_IDEXMEMWB_Reg,
            Stall_i             => s_Stall_IDEXMEMWB_Reg, -- No controlado actualmente por HU para esta etapa de 3 fases
            ALUResult_i         => s_idex_ALUResult_to_reg,
            WriteDataMem_i      => s_idex_WriteDataMem_to_reg,
            WriteRegAddr_i      => s_idex_WriteRegAddr_to_reg,
            PC_plus_4_pass_i    => s_idex_PC_plus_4_pass_to_reg,
            ALU_Zero_i          => s_idex_ALU_Zero_to_reg,
            RegWrite_i          => s_idex_RegWrite_to_reg,
            MemRead_i           => s_idex_MemRead_to_reg,
            MemWrite_i          => s_idex_MemWrite_to_reg,
            MemToReg_i          => s_idex_MemToReg_to_reg,
            ALUResult_o         => s_memwb_ALUResult_i,
            WriteDataMem_o      => s_memwb_WriteDataMem_i,
            WriteRegAddr_o      => s_memwb_WriteRegAddr_i,
            PC_plus_4_pass_o    => open,
            ALU_Zero_o          => open,
            RegWrite_o          => s_memwb_RegWrite_i,
            MemRead_o           => s_memwb_MemRead_i,
            MemWrite_o          => s_memwb_MemWrite_i,
            MemToReg_o          => s_memwb_MemToReg_i
        );

    -- Etapa 3: Acceso a Memoria y Escritura de Retorno (MEM-WB)
    mem_wb_stage_inst : entity work.mem_wb_stage
        port map (
            clk_i               => clk,
            reset_i             => reset,
            ALUResult_i         => s_memwb_ALUResult_i,
            WriteDataMem_i      => s_memwb_WriteDataMem_i,
            WriteRegAddr_i      => s_memwb_WriteRegAddr_i,
            RegWrite_i          => s_memwb_RegWrite_i,
            MemRead_i           => s_memwb_MemRead_i,
            MemWrite_i          => s_memwb_MemWrite_i,
            MemToReg_i          => s_memwb_MemToReg_i,
            WriteRegData_o      => s_rf_WriteData,
            WriteRegAddr_o      => s_rf_WriteAddr,
            RegWriteEnable_o    => s_rf_RegWriteEnable
        );

    -- Instancia del Archivo de Registros
    register_file_inst : entity work.register_file
        port map (
            clk_i           => clk,
            reset_i         => reset,
            ReadAddr1_i     => s_idex_ReadReg1Addr,
            ReadAddr2_i     => s_idex_ReadReg2Addr,
            WriteAddr_i     => s_rf_WriteAddr,
            WriteData_i     => s_rf_WriteData,
            RegWrite_i      => s_rf_RegWriteEnable,
            ReadData1_o     => s_rf_ReadData1,
            ReadData2_o     => s_rf_ReadData2
        );

end Behavioral;
