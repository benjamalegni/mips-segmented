library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    Port (
        clk_i           : in  STD_LOGIC;
        reset_i         : in  STD_LOGIC; -- Optional: for resetting register values

        ReadAddr1_i     : in  STD_LOGIC_VECTOR(4 downto 0);
        ReadAddr2_i     : in  STD_LOGIC_VECTOR(4 downto 0);

        WriteAddr_i     : in  STD_LOGIC_VECTOR(4 downto 0);
        WriteData_i     : in  STD_LOGIC_VECTOR(31 downto 0);
        RegWrite_i      : in  STD_LOGIC; -- Write enable

        ReadData1_o     : out STD_LOGIC_VECTOR(31 downto 0);
        ReadData2_o     : out STD_LOGIC_VECTOR(31 downto 0)
    );
end register_file;

architecture Behavioral of register_file is
    -- Declare the type for the register array (32 registers, 32 bits each)
    type reg_array_t is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);

    -- Declare the register file signal, initialized to all zeros
    -- Using 'signal' makes it a registered element, sensitive to clock for writes.
    -- For simulation, initial values can be set here. For synthesis, reset is preferred.
    signal regs : reg_array_t := (others => (others => '0'));

    -- Constant for register zero address
    constant ZERO_REG_ADDR : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

begin

    -- Read Port 1 (combinational read)
    -- Register $0 always reads as 0
    ReadData1_o <= (others => '0') when ReadAddr1_i = ZERO_REG_ADDR else
                   regs(to_integer(unsigned(ReadAddr1_i)));

    -- Read Port 2 (combinational read)
    -- Register $0 always reads as 0
    ReadData2_o <= (others => '0') when ReadAddr2_i = ZERO_REG_ADDR else
                   regs(to_integer(unsigned(ReadAddr2_i)));

    -- Write Port (synchronous write)
    write_process: process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            -- Optional: Reset all registers to zero.
            -- This might be resource-intensive for FPGAs if not optimized.
            -- Often, individual register initialization or relying on system startup is done.
            -- For this example, let's include a full reset.
            regs <= (others => (others => '0'));
        elsif rising_edge(clk_i) then
            if RegWrite_i = '1' and WriteAddr_i /= ZERO_REG_ADDR then
                -- Only write if RegWrite is asserted and not writing to register $0
                regs(to_integer(unsigned(WriteAddr_i))) <= WriteData_i;
            end if;
        end if;
    end process write_process;

end Behavioral;
