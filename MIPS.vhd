library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work; -- Assuming components are compiled into work

entity MIPS is
    port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC
    );
end MIPS;

architecture Behavioral of MIPS is

    -- Component Declarations --

    component if_stage is
        Port (
            clk                     : in  std_logic;
            reset                   : in  std_logic;
            PCSrc_i                 : in  std_logic_vector(1 downto 0);
            Branch_Target_Addr_i    : in  std_logic_vector(31 downto 0);
            Jump_Target_Addr_i      : in  std_logic_vector(31 downto 0);
            Flush_Reg_i             : in  std_logic;
            Stall_Reg_i             : in  std_logic;
            Reg_IF_ID_out           : out std_logic_vector(31 downto 0);
            Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component reg_if_id is -- Acts as IF/ID-EX Register
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

    component id_ex_stage is
        Port (
            clk                   : in  STD_LOGIC;
            reset                 : in  STD_LOGIC;
            Instruction_i         : in  STD_LOGIC_VECTOR(31 downto 0);
            PC_plus_4_i           : in  STD_LOGIC_VECTOR(31 downto 0);
            RegData1_i            : in  STD_LOGIC_VECTOR(31 downto 0);
            RegData2_i            : in  STD_LOGIC_VECTOR(31 downto 0);
            ALUResult_o           : out STD_LOGIC_VECTOR(31 downto 0);
            WriteDataMem_o        : out STD_LOGIC_VECTOR(31 downto 0);
            WriteRegAddr_o        : out STD_LOGIC_VECTOR(4 downto 0);
            PC_plus_4_pass_o      : out STD_LOGIC_VECTOR(31 downto 0);
            RegWrite_o            : out STD_LOGIC;
            MemRead_o             : out STD_LOGIC;
            MemWrite_o            : out STD_LOGIC;
            MemToReg_o            : out STD_LOGIC;
            ALU_Zero_o            : out STD_LOGIC;
            PCSrc_o               : out STD_LOGIC_VECTOR(1 downto 0);
            Branch_Target_Addr_o  : out STD_LOGIC_VECTOR(31 downto 0);
            Jump_Target_Addr_o    : out STD_LOGIC_VECTOR(31 downto 0);
            ReadReg1Addr_o        : out STD_LOGIC_VECTOR(4 downto 0);
            ReadReg2Addr_o        : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;

    component reg_idex_memwb is -- ID-EX/MEM-WB Register
        Port (
            clk                 : in  STD_LOGIC;
            reset               : in  STD_LOGIC;
            Flush_i             : in  STD_LOGIC;
            Stall_i             : in  STD_LOGIC;
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

    -- Signals for IF Stage outputs / IF-IDEX Register inputs
    signal s_if_Instruction_to_reg : std_logic_vector(31 downto 0);
    signal s_if_PC_plus_4_to_reg   : std_logic_vector(31 downto 0);

    -- Signals for IF-IDEX Register outputs / ID-EX Stage inputs
    signal s_idex_Instruction_i    : std_logic_vector(31 downto 0);
    signal s_idex_PC_plus_4_i      : std_logic_vector(31 downto 0);

    -- Signals for Register File connections
    signal s_rf_ReadData1          : std_logic_vector(31 downto 0);
    signal s_rf_ReadData2          : std_logic_vector(31 downto 0);
    signal s_idex_ReadReg1Addr     : std_logic_vector(4 downto 0); -- from IDEX to RF
    signal s_idex_ReadReg2Addr     : std_logic_vector(4 downto 0); -- from IDEX to RF

    -- Signals for PC control path (ID-EX to IF)
    signal s_idex_PCSrc_to_if            : std_logic_vector(1 downto 0);
    signal s_idex_Branch_Target_to_if    : std_logic_vector(31 downto 0);
    signal s_idex_Jump_Target_to_if      : std_logic_vector(31 downto 0);

    -- Signals for ID-EX Stage outputs / IDEX-MEMWB Register inputs
    signal s_idex_ALUResult_to_reg       : std_logic_vector(31 downto 0);
    signal s_idex_WriteDataMem_to_reg    : std_logic_vector(31 downto 0);
    signal s_idex_WriteRegAddr_to_reg    : std_logic_vector(4 downto 0);
    signal s_idex_PC_plus_4_pass_to_reg  : std_logic_vector(31 downto 0);
    signal s_idex_ALU_Zero_to_reg        : std_logic;
    signal s_idex_RegWrite_to_reg        : std_logic;
    signal s_idex_MemRead_to_reg         : std_logic;
    signal s_idex_MemWrite_to_reg        : std_logic;
    signal s_idex_MemToReg_to_reg        : std_logic;

    -- Signals for IDEX-MEMWB Register outputs / MEM-WB Stage inputs
    signal s_memwb_ALUResult_i           : std_logic_vector(31 downto 0);
    signal s_memwb_WriteDataMem_i        : std_logic_vector(31 downto 0);
    signal s_memwb_WriteRegAddr_i        : std_logic_vector(4 downto 0);
    -- signal s_memwb_PC_plus_4_pass_i   : std_logic_vector(31 downto 0); -- Not used by mem_wb
    -- signal s_memwb_ALU_Zero_i         : std_logic; -- Not used by mem_wb
    signal s_memwb_RegWrite_i            : std_logic;
    signal s_memwb_MemRead_i             : std_logic;
    signal s_memwb_MemWrite_i            : std_logic;
    signal s_memwb_MemToReg_i            : std_logic;

    -- Signals for MEM-WB Stage outputs / Register File Write Port
    signal s_rf_WriteData          : std_logic_vector(31 downto 0);
    signal s_rf_WriteAddr          : std_logic_vector(4 downto 0);
    signal s_rf_RegWriteEnable     : std_logic;

    -- Pipeline Control Signals
    signal s_Stall_IFIDEX_Reg      : std_logic := '0'; -- Default: no stall
    signal s_Flush_IFIDEX_Reg      : std_logic;      -- Controlled by branch/jump
    signal s_Stall_IDEXMEMWB_Reg   : std_logic := '0'; -- Default: no stall
    signal s_Flush_IDEXMEMWB_Reg   : std_logic := '0'; -- Default: no flush (usually not flushed)

begin

    -- Determine if IF/IDEX register should be flushed (if branch or jump is decided in IDEX)
    s_Flush_IFIDEX_Reg <= '1' when s_idex_PCSrc_to_if = "01" or s_idex_PCSrc_to_if = "10" else '0';

    -- Stage 1: Instruction Fetch (IF)
    if_stage_inst : entity work.if_stage
        port map (
            clk                     => clk,
            reset                   => reset,
            PCSrc_i                 => s_idex_PCSrc_to_if,          -- From ID-EX stage
            Branch_Target_Addr_i    => s_idex_Branch_Target_to_if,  -- From ID-EX stage
            Jump_Target_Addr_i      => s_idex_Jump_Target_to_if,    -- From ID-EX stage
            Flush_Reg_i             => s_Flush_IFIDEX_Reg,          -- Control for IF/IDEX reg
            Stall_Reg_i             => s_Stall_IFIDEX_Reg,          -- Control for IF/IDEX reg
            Reg_IF_ID_out           => s_if_Instruction_to_reg,     -- To IF/IDEX reg
            Reg_IF_ID_PC_plus_4_out => s_if_PC_plus_4_to_reg        -- To IF/IDEX reg
        );

    -- Pipeline Register: IF/ID-EX
    if_idex_reg_inst : entity work.reg_if_id
        port map (
            clk            => clk,
            reset          => reset,
            flush          => s_Flush_IFIDEX_Reg,
            stall          => s_Stall_IFIDEX_Reg,
            PC_plus_4_in   => s_if_PC_plus_4_to_reg,
            Instruction_in => s_if_Instruction_to_reg,
            PC_plus_4_out  => s_idex_PC_plus_4_i,      -- To ID-EX stage
            Instruction_out=> s_idex_Instruction_i     -- To ID-EX stage
        );

    -- Stage 2: Instruction Decode & Execute (ID-EX)
    id_ex_stage_inst : entity work.id_ex_stage
        port map (
            clk                   => clk, -- For potential internal clocked components if any
            reset                 => reset,
            Instruction_i         => s_idex_Instruction_i,
            PC_plus_4_i           => s_idex_PC_plus_4_i,
            RegData1_i            => s_rf_ReadData1,         -- From Register File
            RegData2_i            => s_rf_ReadData2,         -- From Register File
            ALUResult_o           => s_idex_ALUResult_to_reg,
            WriteDataMem_o        => s_idex_WriteDataMem_to_reg,
            WriteRegAddr_o        => s_idex_WriteRegAddr_to_reg,
            PC_plus_4_pass_o      => s_idex_PC_plus_4_pass_to_reg,
            RegWrite_o            => s_idex_RegWrite_to_reg,
            MemRead_o             => s_idex_MemRead_to_reg,
            MemWrite_o            => s_idex_MemWrite_to_reg,
            MemToReg_o            => s_idex_MemToReg_to_reg,
            ALU_Zero_o            => s_idex_ALU_Zero_to_reg,
            PCSrc_o               => s_idex_PCSrc_to_if,          -- To IF stage PC logic
            Branch_Target_Addr_o  => s_idex_Branch_Target_to_if,  -- To IF stage PC logic
            Jump_Target_Addr_o    => s_idex_Jump_Target_to_if,    -- To IF stage PC logic
            ReadReg1Addr_o        => s_idex_ReadReg1Addr,         -- To Register File
            ReadReg2Addr_o        => s_idex_ReadReg2Addr          -- To Register File
        );

    -- Pipeline Register: ID-EX/MEM-WB
    idex_memwb_reg_inst : entity work.reg_idex_memwb
        port map (
            clk                 => clk,
            reset               => reset,
            Flush_i             => s_Flush_IDEXMEMWB_Reg,
            Stall_i             => s_Stall_IDEXMEMWB_Reg,
            ALUResult_i         => s_idex_ALUResult_to_reg,
            WriteDataMem_i      => s_idex_WriteDataMem_to_reg,
            WriteRegAddr_i      => s_idex_WriteRegAddr_to_reg,
            PC_plus_4_pass_i    => s_idex_PC_plus_4_pass_to_reg,
            ALU_Zero_i          => s_idex_ALU_Zero_to_reg,
            RegWrite_i          => s_idex_RegWrite_to_reg,
            MemRead_i           => s_idex_MemRead_to_reg,
            MemWrite_i          => s_idex_MemWrite_to_reg,
            MemToReg_i          => s_idex_MemToReg_to_reg,
            ALUResult_o         => s_memwb_ALUResult_i,       -- To MEM-WB stage
            WriteDataMem_o      => s_memwb_WriteDataMem_i,    -- To MEM-WB stage
            WriteRegAddr_o      => s_memwb_WriteRegAddr_i,    -- To MEM-WB stage
            PC_plus_4_pass_o    => open, -- s_memwb_PC_plus_4_pass_i, -- Not directly used by mem_wb
            ALU_Zero_o          => open, -- s_memwb_ALU_Zero_i,         -- Not directly used by mem_wb
            RegWrite_o          => s_memwb_RegWrite_i,        -- To MEM-WB stage
            MemRead_o           => s_memwb_MemRead_i,         -- To MEM-WB stage
            MemWrite_o          => s_memwb_MemWrite_i,        -- To MEM-WB stage
            MemToReg_o          => s_memwb_MemToReg_i         -- To MEM-WB stage
        );

    -- Stage 3: Memory Access & Write-Back (MEM-WB)
    mem_wb_stage_inst : entity work.mem_wb_stage
        port map (
            clk_i               => clk,   -- Clock for Data Memory if synchronous
            reset_i             => reset, -- Reset for Data Memory if synchronous
            ALUResult_i         => s_memwb_ALUResult_i,
            WriteDataMem_i      => s_memwb_WriteDataMem_i,
            WriteRegAddr_i      => s_memwb_WriteRegAddr_i,
            RegWrite_i          => s_memwb_RegWrite_i,
            MemRead_i           => s_memwb_MemRead_i,
            MemWrite_i          => s_memwb_MemWrite_i,
            MemToReg_i          => s_memwb_MemToReg_i,
            WriteRegData_o      => s_rf_WriteData,        -- To Register File
            WriteRegAddr_o      => s_rf_WriteAddr,        -- To Register File
            RegWriteEnable_o    => s_rf_RegWriteEnable    -- To Register File
        );

    -- Register File Instance
    register_file_inst : entity work.register_file
        port map (
            clk_i           => clk,
            reset_i         => reset,
            ReadAddr1_i     => s_idex_ReadReg1Addr,    -- From ID-EX stage
            ReadAddr2_i     => s_idex_ReadReg2Addr,    -- From ID-EX stage
            WriteAddr_i     => s_rf_WriteAddr,         -- From MEM-WB stage
            WriteData_i     => s_rf_WriteData,         -- From MEM-WB stage
            RegWrite_i      => s_rf_RegWriteEnable,    -- From MEM-WB stage
            ReadData1_o     => s_rf_ReadData1,         -- To ID-EX stage
            ReadData2_o     => s_rf_ReadData2          -- To ID-EX stage
        );

end Behavioral;
