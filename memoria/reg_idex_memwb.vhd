library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Required for (others => '0') on std_logic_vector in initializations

entity reg_idex_memwb is
    Port (
        clk                 : in  STD_LOGIC;
        reset               : in  STD_LOGIC;
        Flush_i             : in  STD_LOGIC; -- To clear the register contents
        Stall_i             : in  STD_LOGIC; -- To hold the register contents

        -- Inputs from ID-EX Stage
        ALUResult_i         : in  STD_LOGIC_VECTOR(31 downto 0);
        WriteDataMem_i      : in  STD_LOGIC_VECTOR(31 downto 0);
        WriteRegAddr_i      : in  STD_LOGIC_VECTOR(4 downto 0);
        PC_plus_4_pass_i    : in  STD_LOGIC_VECTOR(31 downto 0);
        ALU_Zero_i          : in  STD_LOGIC;

        -- Control Signals from ID-EX Stage
        RegWrite_i          : in  STD_LOGIC;
        MemRead_i           : in  STD_LOGIC;
        MemWrite_i          : in  STD_LOGIC;
        MemToReg_i          : in  STD_LOGIC;

        -- Outputs to MEM-WB Stage
        ALUResult_o         : out STD_LOGIC_VECTOR(31 downto 0);
        WriteDataMem_o      : out STD_LOGIC_VECTOR(31 downto 0);
        WriteRegAddr_o      : out STD_LOGIC_VECTOR(4 downto 0);
        PC_plus_4_pass_o    : out STD_LOGIC_VECTOR(31 downto 0);
        ALU_Zero_o          : out STD_LOGIC;

        -- Control Signals to MEM-WB Stage
        RegWrite_o          : out STD_LOGIC;
        MemRead_o           : out STD_LOGIC;
        MemWrite_o          : out STD_LOGIC;
        MemToReg_o          : out STD_LOGIC
    );
end reg_idex_memwb;

architecture Behavioral of reg_idex_memwb is
    -- Internal signals to hold registered values
    signal s_ALUResult         : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_WriteDataMem      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_WriteRegAddr      : STD_LOGIC_VECTOR(4 downto 0)  := (others => '0');
    signal s_PC_plus_4_pass    : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_ALU_Zero          : STD_LOGIC := '0';

    signal s_RegWrite          : STD_LOGIC := '0';
    signal s_MemRead           : STD_LOGIC := '0';
    signal s_MemWrite          : STD_LOGIC := '0';
    signal s_MemToReg          : STD_LOGIC := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            s_ALUResult         <= (others => '0');
            s_WriteDataMem      <= (others => '0');
            s_WriteRegAddr      <= (others => '0');
            s_PC_plus_4_pass    <= (others => '0');
            s_ALU_Zero          <= '0';
            s_RegWrite          <= '0';
            s_MemRead           <= '0';
            s_MemWrite          <= '0';
            s_MemToReg          <= '0';
        elsif rising_edge(clk) then
            if Flush_i = '1' then
                s_ALUResult         <= (others => '0');
                s_WriteDataMem      <= (others => '0');
                s_WriteRegAddr      <= (others => '0');
                s_PC_plus_4_pass    <= (others => '0');
                s_ALU_Zero          <= '0';
                s_RegWrite          <= '0';
                s_MemRead           <= '0';
                s_MemWrite          <= '0';
                s_MemToReg          <= '0';
            elsif Stall_i = '0' then -- Only load if not stalling
                s_ALUResult         <= ALUResult_i;
                s_WriteDataMem      <= WriteDataMem_i;
                s_WriteRegAddr      <= WriteRegAddr_i;
                s_PC_plus_4_pass    <= PC_plus_4_pass_i;
                s_ALU_Zero          <= ALU_Zero_i;
                s_RegWrite          <= RegWrite_i;
                s_MemRead           <= MemRead_i;
                s_MemWrite          <= MemWrite_i;
                s_MemToReg          <= MemToReg_i;
            end if;
            -- If Stall_i is '1' (and not flush/reset), values remain unchanged due to no assignment
        end if;
    end process;

    -- Assign registered signals to outputs
    ALUResult_o         <= s_ALUResult;
    WriteDataMem_o      <= s_WriteDataMem;
    WriteRegAddr_o      <= s_WriteRegAddr;
    PC_plus_4_pass_o    <= s_PC_plus_4_pass;
    ALU_Zero_o          <= s_ALU_Zero;
    RegWrite_o          <= s_RegWrite;
    MemRead_o           <= s_MemRead;
    MemWrite_o          <= s_MemWrite;
    MemToReg_o          <= s_MemToReg;

end Behavioral;
