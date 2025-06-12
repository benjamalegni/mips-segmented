-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- For (others => '0') with std_logic_vector

entity reg_if_id is
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
end reg_if_id;

architecture Behavioral of reg_if_id is
    signal s_pc_plus_4   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin

    process(clk, reset)
    begin
        if reset = '1' then
            s_pc_plus_4   <= (others => '0');
            s_instruction <= (others => '0');
        elsif rising_edge(clk) then
            if flush = '1' then
                s_pc_plus_4   <= (others => '0');
                s_instruction <= (others => '0');
            elsif stall = '0' then -- Only load if not stalling
                s_pc_plus_4   <= PC_plus_4_in;
                s_instruction <= Instruction_in;
            end if;
            -- If stall is '1' and not flush/reset, values remain unchanged
        end if;
    end process;

    PC_plus_4_out   <= s_pc_plus_4;
    Instruction_out <= s_instruction;

end Behavioral;
