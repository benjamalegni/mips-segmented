-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Para extensión de signo, redimensionamiento, sll

library work;
-- Suponiendo que ControlUnit, ALUControl y ALU están compilados en 'work'

entity id_ex_stage is
    Port (
        -- Entradas
        clk                   : in  STD_LOGIC;
        reset                 : in  STD_LOGIC;
        Instruction_i         : in  STD_LOGIC_VECTOR(31 downto 0);
        PC_plus_4_i           : in  STD_LOGIC_VECTOR(31 downto 0);
        RegData1_i            : in  STD_LOGIC_VECTOR(31 downto 0); -- Registro fuente para ALU A
        RegData2_i            : in  STD_LOGIC_VECTOR(31 downto 0); -- Registro fuente para ALU B

        -- Entradas de Control de Adelantamiento y Riesgos
        ForwardA_sel_i          : in  STD_LOGIC_VECTOR(1 downto 0);
        ForwardB_sel_i          : in  STD_LOGIC_VECTOR(1 downto 0);
        Forward_EXMEM_ALUResult_i : in  STD_LOGIC_VECTOR(31 downto 0);
        Forward_MEMWB_WriteData_i : in  STD_LOGIC_VECTOR(31 downto 0);
        Bubble_IDEX_i           : in  STD_LOGIC;

        -- Salidas al Registro ID-EX/MEM-WB
        ALUResult_o           : out STD_LOGIC_VECTOR(31 downto 0);
        WriteDataMem_o        : out STD_LOGIC_VECTOR(31 downto 0);
        WriteRegAddr_o        : out STD_LOGIC_VECTOR(4 downto 0);
        PC_plus_4_pass_o      : out STD_LOGIC_VECTOR(31 downto 0);
        RegWrite_o            : out STD_LOGIC;
        MemRead_o             : out STD_LOGIC;
        MemWrite_o            : out STD_LOGIC;
        MemToReg_o            : out STD_LOGIC;
        ALU_Zero_o            : out STD_LOGIC;

        -- Salidas para control del PC en la etapa IF (enrutadas a través de MIPS.vhd)
        PCSrc_o               : out STD_LOGIC_VECTOR(1 downto 0);
        Branch_Target_Addr_o  : out STD_LOGIC_VECTOR(31 downto 0);
        Jump_Target_Addr_o    : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Salidas para direcciones de lectura del Archivo de Registros (enrutadas a través de MIPS.vhd)
        ReadReg1Addr_o        : out STD_LOGIC_VECTOR(4 downto 0);
        ReadReg2Addr_o        : out STD_LOGIC_VECTOR(4 downto 0)
    );
end id_ex_stage;

architecture Behavioral of id_ex_stage is
    -- Campos de instrucción
    signal s_opcode : std_logic_vector(5 downto 0);
    signal s_rs     : std_logic_vector(4 downto 0);
    signal s_rt     : std_logic_vector(4 downto 0);
    signal s_rd     : std_logic_vector(4 downto 0);
    signal s_funct  : std_logic_vector(5 downto 0);
    signal s_immediate_16 : std_logic_vector(15 downto 0);
    signal s_immediate_extended : std_logic_vector(31 downto 0);

    -- Señales de la Unidad de Control en bruto
    signal s_RegWrite    : std_logic;
    signal s_RegDst      : std_logic;
    signal s_Branch      : std_logic;
    signal s_MemRead     : std_logic;
    signal s_MemtoReg    : std_logic;
    signal s_MemWrite    : std_logic;
    signal s_ALUSrc      : std_logic;
    signal s_Jump        : std_logic;
    signal s_alu_op_from_cu : std_logic_vector(1 downto 0);

    -- Señales de ALUControl
    signal s_final_alu_control : std_logic_vector(3 downto 0);

    -- Señales de entrada de la ALU después del adelantamiento
    signal s_alu_input_a         : std_logic_vector(31 downto 0);
    signal s_alu_input_b_reg_src : std_logic_vector(31 downto 0);
    signal s_alu_operand_b       : std_logic_vector(31 downto 0); -- Operando B final para la ALU (puede ser inmediato)

    -- Señales de salida de la ALU
    signal s_alu_result    : std_logic_vector(31 downto 0);
    signal s_alu_zero      : std_logic;

    -- Señales de control efectivas (pueden ser anuladas por una burbuja)
    signal s_eff_RegWrite        : std_logic;
    signal s_eff_MemRead         : std_logic;
    signal s_eff_MemWrite        : std_logic;
    signal s_eff_MemToReg        : std_logic;
    signal s_eff_Branch          : std_logic;
    signal s_eff_Jump            : std_logic;

    -- Lógica de bifurcación
    signal s_branch_condition_met : std_logic;

    component ControlUnit is
        port (
            OP          : in  std_logic_vector(5 downto 0);
            RegWrite    : out std_logic;
            RegDst      : out std_logic;
            Branch      : out std_logic;
            MemRead     : out std_logic;
            MemtoReg    : out std_logic;
            MemWrite    : out std_logic;
            ALUSrc      : out std_logic;
            Jump        : out std_logic;
            ALUOp_o     : out std_logic_vector(1 downto 0)
        );
    end component;

    component ALUControl is
        port (
            ALUOp      : in  std_logic_vector(1 downto 0);
            Funct      : in  std_logic_vector(5 downto 0);
            ALUControl : out std_logic_vector(3 downto 0)
        );
    end component;

    component ALU is
        port (
            a       : in  std_logic_vector(31 downto 0);
            b       : in  std_logic_vector(31 downto 0);
            control : in  std_logic_vector(3 downto 0);
            zero    : out std_logic;
            result  : out std_logic_vector(31 downto 0)
        );
    end component;

begin
    -- Extracción de Campos de Instrucción
    s_opcode <= Instruction_i(31 downto 26);
    s_rs     <= Instruction_i(25 downto 21);
    s_rt     <= Instruction_i(20 downto 16);
    s_rd     <= Instruction_i(15 downto 11);
    s_funct  <= Instruction_i(5 downto 0);
    s_immediate_16 <= Instruction_i(15 downto 0);

    s_immediate_extended <= std_logic_vector(resize(signed(s_immediate_16), 32));

    control_unit_inst: entity work.ControlUnit
        port map (
            OP         => s_opcode,
            RegWrite   => s_RegWrite,
            RegDst     => s_RegDst,
            Branch     => s_Branch,
            MemRead    => s_MemRead,
            MemtoReg   => s_MemtoReg,
            MemWrite   => s_MemWrite,
            ALUSrc     => s_ALUSrc,
            Jump       => s_Jump,
            ALUOp_o    => s_alu_op_from_cu
        );

    alu_control_inst: entity work.ALUControl
        port map (
            ALUOp      => s_alu_op_from_cu,
            Funct      => s_funct,
            ALUControl => s_final_alu_control
        );

    ReadReg1Addr_o <= s_rs;
    ReadReg2Addr_o <= s_rt;

    -- Mux de Adelantamiento para Entrada A de la ALU
    alu_input_a_mux_proc: process(ForwardA_sel_i, RegData1_i, Forward_EXMEM_ALUResult_i, Forward_MEMWB_WriteData_i)
    begin
        case ForwardA_sel_i is
            when "01" => -- Adelantar desde resultado EX/MEM (operación ALU anterior)
                s_alu_input_a <= Forward_EXMEM_ALUResult_i;
            when "10" => -- Adelantar desde resultado MEM/WB (operación más antigua, podría ser LW o ALU)
                s_alu_input_a <= Forward_MEMWB_WriteData_i;
            when others => -- "00" o por defecto
                s_alu_input_a <= RegData1_i;
        end case;
    end process alu_input_a_mux_proc;

    -- Mux de Adelantamiento para Fuente de Registro de Entrada B de la ALU
    alu_input_b_reg_src_mux_proc: process(ForwardB_sel_i, RegData2_i, Forward_EXMEM_ALUResult_i, Forward_MEMWB_WriteData_i)
    begin
        case ForwardB_sel_i is
            when "01" => -- Adelantar desde resultado EX/MEM
                s_alu_input_b_reg_src <= Forward_EXMEM_ALUResult_i;
            when "10" => -- Adelantar desde resultado MEM/WB
                s_alu_input_b_reg_src <= Forward_MEMWB_WriteData_i;
            when others => -- "00" o por defecto
                s_alu_input_b_reg_src <= RegData2_i;
        end case;
    end process alu_input_b_reg_src_mux_proc;

    s_alu_operand_b <= s_alu_input_b_reg_src when s_ALUSrc = '0' else s_immediate_extended;

    alu_inst: entity work.ALU
        port map (
            a       => s_alu_input_a,
            b       => s_alu_operand_b,
            control => s_final_alu_control,
            zero    => s_alu_zero,
            result  => s_alu_result
        );

    WriteRegAddr_o <= s_rt when s_RegDst = '0' else s_rd;
    WriteDataMem_o <= s_alu_input_b_reg_src; -- Para SW, esto debería ser el dato de Rt (después del adelantamiento)

    -- Lógica de Burbuja para Señales de Control
    s_eff_RegWrite <= s_RegWrite and not Bubble_IDEX_i;
    s_eff_MemRead  <= s_MemRead  and not Bubble_IDEX_i;
    s_eff_MemWrite <= s_MemWrite and not Bubble_IDEX_i;
    s_eff_MemToReg <= s_MemtoReg and not Bubble_IDEX_i;
    s_eff_Branch   <= s_Branch   and not Bubble_IDEX_i;
    s_eff_Jump     <= s_Jump     and not Bubble_IDEX_i;

    -- Lógica de Control del PC
    s_branch_condition_met <= s_eff_Branch and s_alu_zero;

    pc_source_logic: process(s_eff_Jump, s_branch_condition_met)
    begin
        if s_eff_Jump = '1' then
            PCSrc_o <= "10";
        elsif s_branch_condition_met = '1' then
            PCSrc_o <= "01";
        else
            PCSrc_o <= "00";
        end if;
    end process pc_source_logic;

    -- Pasar señales de control efectivas y datos al registro ID-EX/MEM-WB
    ALUResult_o      <= s_alu_result;
    ALU_Zero_o       <= s_alu_zero;
    PC_plus_4_pass_o <= PC_plus_4_i;
    RegWrite_o <= s_eff_RegWrite;
    MemRead_o  <= s_eff_MemRead;
    MemWrite_o <= s_eff_MemWrite;
    MemToReg_o <= s_eff_MemToReg;

end Behavioral;
