library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- For to_integer, unsigned

entity instruction_rom is
    Port (
        -- Word address input (e.g., PC(9 downto 2) for up to 256 words)
        Addr_Word_i   : in  STD_LOGIC_VECTOR(7 downto 0);
        Instruction_o : out STD_LOGIC_VECTOR(31 downto 0)
    );
end instruction_rom;

architecture Behavioral of instruction_rom is
    -- Define the type for the ROM array
    type rom_array_t is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);

    -- Program 1 provided by the user
    constant PROGRAM1 : rom_array_t := (
        0   => x"8c090000",  -- LW $9, 0($0)
        1   => x"8c0a0004",  -- LW $10, 4($0)
        2   => x"8c0b0008",  -- LW $11, 8($0)
        3   => x"8c0c000c",  -- LW $12, 12($0)
        4   => x"8c0d0010",  -- LW $13, 16($0)
        5   => x"8c0e0014",  -- LW $14, 20($0)
        6   => x"ac090018",  -- SW $9, 24($0)
        7   => x"ac0a001c",  -- SW $10, 28($0)
        8   => x"ac0b0020",  -- SW $11, 32($0)
        9   => x"ac0c0024",  -- SW $12, 36($0)
        10  => x"ac0d0028",  -- SW $13, 40($0)
        11  => x"ac0e002c",  -- SW $14, 44($0)
        12  => x"8c090018",  -- LW $9, 24($0)   ; Reads back what was written by instr 6
        13  => x"8c0a001c",  -- LW $10, 28($0)  ; Reads back what was written by instr 7
        14  => x"8c0b0020",  -- LW $11, 32($0)  ; Reads back what was written by instr 8
        15  => x"8c0c0024",  -- LW $12, 36($0)  ; Reads back what was written by instr 9
        16  => x"8c0d0028",  -- LW $13, 40($0)  ; Reads back what was written by instr 10
        17  => x"8c0e002c",  -- LW $14, 44($0)  ; Reads back what was written by instr 11
        18  => x"012a7820",  -- ADD $15, $9, $10
        19  => x"016c8020",  -- ADD $16, $11, $12
        20  => x"01a98822",  -- SUB $17, $13, $9
        21  => x"01ca9022",  -- SUB $18, $14, $10
        22  => x"012a9824",  -- AND $19, $9, $10
        23  => x"01eaa024",  -- AND $20, $23, $10 ; Note: $23 is used before being explicitly set by this program, unless it's an SLT result
        24  => x"012aa825",  -- OR  $21, $9, $10
        25  => x"020ab025",  -- OR  $22, $16, $11
        26  => x"012ab82a",  -- SLT $23, $9, $11
        27  => x"020ac02a",  -- SLT $24, $16, $12
        28  => x"0800001c",  -- J 0x00000070 (Jump to instruction at ROM index 28, which is this same jump instruction)

        -- Initialize the rest of the ROM with NOPs (x"00000000")
        others => x"00000000"
    );

    -- ROM content signal (optional if using constant directly, but good for clarity/FPGA synthesis)
    signal rom_content : rom_array_t := PROGRAM1;

begin
    -- Combinational read from the ROM
    -- Convert std_logic_vector address to integer for array indexing
    Instruction_o <= rom_content(to_integer(unsigned(Addr_Word_i)))
                     when (to_integer(unsigned(Addr_Word_i)) < PROGRAM1'length) else
                     x"00000000"; -- NOP for out-of-bounds (though 'length applies to type here, better to use a fixed size or actual program length)

    -- A safer way for out-of-bounds if PROGRAM1 is not fully defined up to 255:
    -- process(Addr_Word_i, rom_content)
    --     variable addr_int : integer;
    -- begin
    --     addr_int := to_integer(unsigned(Addr_Word_i));
    --     if addr_int >= 0 and addr_int < 29 then -- Actual number of instructions in Program 1
    --         Instruction_o <= rom_content(addr_int);
    --     else
    --         Instruction_o <= x"00000000"; -- NOP for out-of-bounds
    --     end if;
    -- end process;
    -- For simplicity, the direct access with 'length check on type is used,
    -- assuming 'others' initializes up to the type's length.
    -- The provided solution using PROGRAM1'length will actually refer to the length of the type rom_array_t (256).
    -- A more precise check would be against the actual number of defined instructions if we don't want to rely on 'others' for safety for undefined higher addresses.
    -- However, since 'others' initializes them to NOP, the direct access is fine.
    -- The provided solution above the process block is more typical for a ROM.

end Behavioral;
