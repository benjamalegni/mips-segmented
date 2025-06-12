library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;      -- For + operator
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- For + operator with std_logic_vector

entity IF_stage is
    Port (
        clk : in std_logic;
        reset : in std_logic;

        -- Inputs for PC selection logic (from ID-EX stage typically)
        PCSrc_i              : in std_logic_vector(1 downto 0);
        Branch_Target_Addr_i : in std_logic_vector(31 downto 0);
        Jump_Target_Addr_i   : in std_logic_vector(31 downto 0);

        -- Pipeline control signals
        Flush_Reg_i          : in std_logic;
        Stall_Reg_i          : in std_logic;

        -- Outputs to IF/ID-EX Register
        Reg_IF_ID_out           : out std_logic_vector(31 downto 0); -- Instruction
        Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0)  -- PC+4
    );
end IF_stage;

architecture Behavioral of IF_stage is
    signal s_pc_plus_4 : std_logic_vector(31 downto 0);
    signal PC_out      : std_logic_vector(31 downto 0); -- Current PC
    signal PC_in       : std_logic_vector(31 downto 0); -- Next PC (input to PC register)
    signal s_inst_mem_data_out : std_logic_vector(31 downto 0); -- Data from instruction memory

    -- Component for Instruction Memory (assuming it's defined elsewhere or as 'work.Memory')
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

    -- Component for IF/ID-EX Register (reg_if_id)
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

    -- PC Register: Holds the current program counter
    process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
        elsif rising_edge(clk) then
            if Stall_Reg_i = '0' then -- Only update PC if not stalled
                PC_out <= PC_in;
            end if;
        end if;
    end process;

    -- PC+4 Calculation: Based on the current PC_out
    s_pc_plus_4 <= PC_out + 4;

    -- Next PC Selection Logic: Determines the value for PC_in
    with PCSrc_i select
        PC_in <= s_pc_plus_4          when "00",     -- Default to PC+4
                 Branch_Target_Addr_i when "01",     -- Branch
                 Jump_Target_Addr_i   when "10",     -- Jump
                 s_pc_plus_4          when others;   -- Default to PC+4 for "11" or any other undefined state

    -- Instruction Memory instance
    inst_memory: Memory
        generic map (
            C_FUNC_CLK     => '1',       -- Assuming clk drives memory directly if needed
            C_ELF_FILENAME => "program", -- Default program file
            C_MEM_SIZE     => 1024      -- Default memory size
        )
        port map (
            Addr    => PC_out, -- Address from current PC
            DataIn  => (others => '0'), -- Not writing to instruction memory here
            RdStb   => '1',             -- Always reading
            WrStb   => '0',             -- Never writing
            Clk     => clk,             -- System clock
            Reset   => reset,           -- System reset
            DataOut => s_inst_mem_data_out
        );

    -- IF/ID-EX Register instance
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