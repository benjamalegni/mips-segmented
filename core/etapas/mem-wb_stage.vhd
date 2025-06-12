library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Not strictly needed here but good practice

-- Assuming DataMemory component is available, possibly from 'work.ram' or similar
library work;
-- use work.ram.all; -- If DataMemory is defined in a package 'ram' in 'work'

entity mem_wb_stage is
    Port (
        -- Inputs from ID-EX/MEM-WB Register
        clk_i               : in  STD_LOGIC; -- Clock for Data Memory
        reset_i             : in  STD_LOGIC; -- Reset for Data Memory
        
        ALUResult_i         : in  STD_LOGIC_VECTOR(31 downto 0); -- Result from ALU
        WriteDataMem_i      : in  STD_LOGIC_VECTOR(31 downto 0); -- Data to write to memory (for SW)
        WriteRegAddr_i      : in  STD_LOGIC_VECTOR(4 downto 0);  -- Address of destination register

        -- Control signals from ID-EX/MEM-WB Register
        RegWrite_i          : in  STD_LOGIC; -- Enables register write
        MemRead_i           : in  STD_LOGIC; -- Enables memory read
        MemWrite_i          : in  STD_LOGIC; -- Enables memory write
        MemToReg_i          : in  STD_LOGIC; -- Selects write-back data source (Mem vs ALU)

        -- Outputs to Register File
        WriteRegData_o      : out STD_LOGIC_VECTOR(31 downto 0); -- Data to write to register file
        WriteRegAddr_o      : out STD_LOGIC_VECTOR(4 downto 0);  -- Destination register address
        RegWriteEnable_o    : out STD_LOGIC                      -- To enable writing in Register File
    );
end mem_wb_stage;

architecture Behavioral of mem_wb_stage is
    -- Signal for data read from Data Memory
    signal s_mem_read_data : std_logic_vector(31 downto 0);

    -- Component for Data Memory (ensure this matches your actual DataMemory component)
    component DataMemory is
        port (
            CLK         : in  std_logic;
            RESET       : in  std_logic;
            MemRead     : in  std_logic;
            MemWrite    : in  std_logic;
            Address     : in  std_logic_vector(31 downto 0);
            WriteData   : in  std_logic_vector(31 downto 0);
            ReadData    : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    -- Instantiate Data Memory
    -- The address for memory operations comes from the ALU result.
    -- Data to be written to memory (for SW) comes from WriteDataMem_i.
    data_memory_inst: entity work.DataMemory -- Or specific library.entity if not in 'work' directly
        port map (
            CLK       => clk_i,
            RESET     => reset_i,
            MemRead   => MemRead_i,
            MemWrite  => MemWrite_i,
            Address   => ALUResult_i,
            WriteData => WriteDataMem_i,
            ReadData  => s_mem_read_data
        );

    -- Write-Back Mux: Selects data to be written to the register file.
    -- If MemToReg_i is '1', data comes from memory (LW).
    -- Otherwise, data comes from ALU result (R-type, I-type ALU).
    WriteRegData_o <= s_mem_read_data when MemToReg_i = '1' else
                      ALUResult_i;

    -- Pass through the destination register address and RegWrite enable signal
    WriteRegAddr_o   <= WriteRegAddr_i;
    RegWriteEnable_o <= RegWrite_i;

end Behavioral;
