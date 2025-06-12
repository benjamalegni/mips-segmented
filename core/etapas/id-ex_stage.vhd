library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- For sign extension, resize, sll

library work;
-- Assuming ControlUnit, ALUControl, and ALU are compiled into 'work'

entity id_ex_stage is
    Port (
        -- Inputs
        clk                   : in  STD_LOGIC;
        reset                 : in  STD_LOGIC;
        Instruction_i         : in  STD_LOGIC_VECTOR(31 downto 0);
        PC_plus_4_i           : in  STD_LOGIC_VECTOR(31 downto 0);
        RegData1_i            : in  STD_LOGIC_VECTOR(31 downto 0);
        RegData2_i            : in  STD_LOGIC_VECTOR(31 downto 0);

        -- Outputs to ID-EX/MEM-WB Register
        ALUResult_o           : out STD_LOGIC_VECTOR(31 downto 0);
        WriteDataMem_o        : out STD_LOGIC_VECTOR(31 downto 0);
        WriteRegAddr_o        : out STD_LOGIC_VECTOR(4 downto 0);
        PC_plus_4_pass_o      : out STD_LOGIC_VECTOR(31 downto 0);
        RegWrite_o            : out STD_LOGIC;
        MemRead_o             : out STD_LOGIC;
        MemWrite_o            : out STD_LOGIC;
        MemToReg_o            : out STD_LOGIC;
        ALU_Zero_o            : out STD_LOGIC;

        -- Outputs for PC control in IF stage (routed via MIPS.vhd)
        PCSrc_o               : out STD_LOGIC_VECTOR(1 downto 0);
        Branch_Target_Addr_o  : out STD_LOGIC_VECTOR(31 downto 0);
        Jump_Target_Addr_o    : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Outputs for Register File read addresses (routed via MIPS.vhd)
        ReadReg1Addr_o        : out STD_LOGIC_VECTOR(4 downto 0);
        ReadReg2Addr_o        : out STD_LOGIC_VECTOR(4 downto 0)
    );
end id_ex_stage;

architecture Behavioral of id_ex_stage is
    -- Instruction fields
    signal s_opcode : std_logic_vector(5 downto 0);
    signal s_rs     : std_logic_vector(4 downto 0);
    signal s_rt     : std_logic_vector(4 downto 0);
    signal s_rd     : std_logic_vector(4 downto 0);
    signal s_funct  : std_logic_vector(5 downto 0);
    signal s_immediate_16 : std_logic_vector(15 downto 0);
    signal s_immediate_extended : std_logic_vector(31 downto 0);

    -- Control Unit signals
    signal s_RegWrite    : std_logic;
    signal s_RegDst      : std_logic;
    signal s_Branch      : std_logic;
    signal s_MemRead     : std_logic;
    signal s_MemtoReg    : std_logic;
    signal s_MemWrite    : std_logic;
    signal s_ALUSrc      : std_logic;
    signal s_Jump        : std_logic;
    signal s_alu_op_from_cu : std_logic_vector(1 downto 0); -- Changed from 4-bit to 2-bit

    -- ALUControl signals
    signal s_final_alu_control : std_logic_vector(3 downto 0); -- Output from new ALUControl module

    -- ALU signals
    signal s_alu_operand_b : std_logic_vector(31 downto 0);
    signal s_alu_result    : std_logic_vector(31 downto 0);
    signal s_alu_zero      : std_logic;

    -- Branch logic
    signal s_branch_condition_met : std_logic;

    -- Updated ControlUnit component
    component ControlUnit is
        port (
            OP          : in  std_logic_vector(5 downto 0);
            -- Funct input removed
            RegWrite    : out std_logic;
            RegDst      : out std_logic;
            Branch      : out std_logic;
            MemRead     : out std_logic;
            MemtoReg    : out std_logic;
            MemWrite    : out std_logic;
            ALUSrc      : out std_logic;
            Jump        : out std_logic;
            ALUOp_o     : out std_logic_vector(1 downto 0) -- Changed from ALUControl
        );
    end component;

    -- New ALUControl component
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
    -- Instruction Field Extraction
    s_opcode <= Instruction_i(31 downto 26);
    s_rs     <= Instruction_i(25 downto 21);
    s_rt     <= Instruction_i(20 downto 16);
    s_rd     <= Instruction_i(15 downto 11);
    s_funct  <= Instruction_i(5 downto 0);
    s_immediate_16 <= Instruction_i(15 downto 0);

    -- Sign Extension for Immediate
    s_immediate_extended <= std_logic_vector(resize(signed(s_immediate_16), 32));

    -- Control Unit Instantiation (Updated)
    control_unit_inst: entity work.ControlUnit
        port map (
            OP         => s_opcode,
            -- Funct mapping removed
            RegWrite   => s_RegWrite,
            RegDst     => s_RegDst,
            Branch     => s_Branch,
            MemRead    => s_MemRead,
            MemtoReg   => s_MemtoReg,
            MemWrite   => s_MemWrite,
            ALUSrc     => s_ALUSrc,
            Jump       => s_Jump,
            ALUOp_o    => s_alu_op_from_cu -- Changed port name and signal
        );

    -- New ALUControl Instantiation
    alu_control_inst: entity work.ALUControl
        port map (
            ALUOp      => s_alu_op_from_cu,
            Funct      => s_funct,
            ALUControl => s_final_alu_control
        );

    -- Register File Read Addresses
    ReadReg1Addr_o <= s_rs;
    ReadReg2Addr_o <= s_rt;

    -- ALU Operand B Mux
    s_alu_operand_b <= RegData2_i when s_ALUSrc = '0' else s_immediate_extended;

    -- ALU Instantiation (Updated control signal)
    alu_inst: entity work.ALU
        port map (
            a       => RegData1_i,
            b       => s_alu_operand_b,
            control => s_final_alu_control, -- Changed to output of new ALUControl module
            zero    => s_alu_zero,
            result  => s_alu_result
        );

    -- Write Register Address Mux
    WriteRegAddr_o <= s_rt when s_RegDst = '0' else s_rd;

    -- Data to Memory (for SW)
    WriteDataMem_o <= RegData2_i;

    -- PC Control Logic
    s_branch_condition_met <= s_Branch and s_alu_zero;
    Jump_Target_Addr_o   <= (PC_plus_4_i(31 downto 28) & Instruction_i(25 downto 0) & "00");
    Branch_Target_Addr_o <= PC_plus_4_i + (s_immediate_extended sll 2);

    pc_source_logic: process(s_Jump, s_branch_condition_met)
    begin
        if s_Jump = '1' then
            PCSrc_o <= "10";
        elsif s_branch_condition_met = '1' then
            PCSrc_o <= "01";
        else
            PCSrc_o <= "00";
        end if;
    end process;

    -- Pass-through outputs for ID-EX/MEM-WB register
    ALUResult_o      <= s_alu_result;
    ALU_Zero_o       <= s_alu_zero;
    PC_plus_4_pass_o <= PC_plus_4_i;
    RegWrite_o <= s_RegWrite;
    MemRead_o  <= s_MemRead;
    MemWrite_o <= s_MemWrite;
    MemToReg_o <= s_MemtoReg;

end Behavioral;
