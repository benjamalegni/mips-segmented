library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mips_tb is
    -- Testbench entity is typically empty
end entity mips_tb;

architecture Behavioral of mips_tb is
    -- Component Declaration for the Unit Under Test (UUT)
    component MIPS is
        port (
            clk   : in  STD_LOGIC;
            reset : in  STD_LOGIC
        );
    end component;

    -- Inputs
    signal tb_clk   : STD_LOGIC := '0';
    signal tb_reset : STD_LOGIC := '0';

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns; -- Example clock period (100 MHz)

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.MIPS -- Assuming MIPS entity is compiled into 'work' library
        port map (
            clk   => tb_clk,
            reset => tb_reset
        );

    -- Clock process definition
    clk_process :process
    begin
        tb_clk <= '0';
        wait for CLK_PERIOD/2;
        tb_clk <= '1';
        wait for CLK_PERIOD/2;
    end process clk_process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Step 1: Apply Reset
        report "Stimulus: Applying Reset";
        tb_reset <= '1';
        wait for CLK_PERIOD * 5; -- Hold reset for 5 clock cycles
        tb_reset <= '0';
        report "Stimulus: Reset Released";
        wait for CLK_PERIOD * 2; -- Wait a couple of cycles after reset

        -- Step 2: Run for a number of cycles to execute a test program
        -- The actual instructions are assumed to be loaded into the
        -- instruction memory (Memory component in if_stage) via an
        -- ELF file named "program" as per its generic C_ELF_FILENAME.

        report "Stimulus: Starting main program execution phase.";

        -- Program 3 (conceptual - loaded via file "program", all addresses are byte addresses)
        -- Assuming $t1=R9, $t2=R10, $t3=R11, $t4=R12, $t5=R13
        -- Addr  Machine Code  Instruction
        -- 0x00: 8C090000      lw $t1, 0($zero)
        -- 0x04: 8C0A0004      lw $t2, 4($zero)
        -- 0x08: 012A6020      add $t4, $t1, $t2
        -- 0x0C: 8C0B0008      lw $t3, 8($zero)
        -- 0x10: 018B6022      sub $t4, $t4, $t3
        -- 0x14: 014C6820      add $t5, $t2, $t4
        -- 0x18: 08000005      j 0x00000014 (jumps to the `add $t5` instruction at address 0x14)
        -- 0x1C: 00000000      nop (padding)
        -- 0x20: 00000000      nop (padding)
        -- 0x24: 00000000      nop (padding)

        -- Let the simulation run for enough cycles.
        -- Program 3 has 7 significant instructions. The jump creates a small loop.
        -- 100 cycles should be sufficient to observe behavior.
        wait for CLK_PERIOD * 100;

        report "Stimulus: Nominal program execution time finished.";

        -- Add more specific checks here if outputs were available from MIPS
        -- e.g., check values in a simulated data memory or register file if accessible.

        report "Stimulus: Testbench finished." severity failure; -- Use 'failure' to stop simulation in some tools
        wait; -- Will wait forever
    end process stim_proc;

end Behavioral;
