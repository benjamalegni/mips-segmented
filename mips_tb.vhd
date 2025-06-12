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

        -- Example Test Program (conceptual - loaded via ELF file "program")
        -- 00: ADDI $1, $0, 5       (Load 5 into r1)
        -- 04: ADDI $2, $0, 10      (Load 10 into r2)
        -- 08: ADD  $3, $1, $2       (r3 = r1 + r2 = 15)
        -- 0C: SW   $3, 0($0)        (Store r3 to data memory addr 0)
        -- 10: LW   $4, 0($0)        (Load from data memory addr 0 to r4; r4 should be 15)
        -- 14: NOP                    (Alignment for branch, or useful work)
        -- 18: BEQ  $3, $4, +8_bytes (skip_one: PC+4+8 = PC+12 if r3==r4) (Target: address 0x24)
        -- 1C: ADDI $5, $0, 1       (This instruction should be skipped if branch taken)
        -- 20: NOP                    (Delay slot or other instruction)
        -- 24: <skip_one_target_addr>: ADDI $6, $0, 100 (r6 = 100)
        -- 28: J    0x28             (Infinite loop to signify end for this simple TB / or J to a specific end address)
        -- 2C: ADDI $7, $0, 200     (Should not be reached if jump is effective)

        -- Let the simulation run for enough cycles to complete the above program.
        -- For example, ~20-30 instructions, 3-stage pipeline might take ~ (N + P-1) + stalls
        -- For 10 key instructions, maybe 10 + 2 = 12 cycles ideal, plus some overhead.
        -- Let's give it 50 cycles for this hypothetical program.
        wait for CLK_PERIOD * 100;

        report "Stimulus: Nominal program execution time finished.";

        -- Add more specific checks here if outputs were available from MIPS
        -- e.g., check values in a simulated data memory or register file if accessible.

        report "Stimulus: Testbench finished." severity failure; -- Use 'failure' to stop simulation in some tools
        wait; -- Will wait forever
    end process stim_proc;

end Behavioral;
