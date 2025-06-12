-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Para to_integer, unsigned

entity instruction_rom is
    Port (
        -- Entrada de dirección de palabra (ej., PC(9 downto 2) para hasta 256 palabras)
        Addr_Word_i   : in  STD_LOGIC_VECTOR(7 downto 0);
        Instruction_o : out STD_LOGIC_VECTOR(31 downto 0)
    );
end instruction_rom;

architecture Behavioral of instruction_rom is
    -- Definir el tipo para el array ROM
    type rom_array_t is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);

    -- Programa 1 proporcionado por el usuario
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
        12  => x"8c090018",  -- LW $9, 24($0)   ; Lee lo que escribió la instr 6
        13  => x"8c0a001c",  -- LW $10, 28($0)  ; Lee lo que escribió la instr 7
        14  => x"8c0b0020",  -- LW $11, 32($0)  ; Lee lo que escribió la instr 8
        15  => x"8c0c0024",  -- LW $12, 36($0)  ; Lee lo que escribió la instr 9
        16  => x"8c0d0028",  -- LW $13, 40($0)  ; Lee lo que escribió la instr 10
        17  => x"8c0e002c",  -- LW $14, 44($0)  ; Lee lo que escribió la instr 11
        18  => x"012a7820",  -- ADD $15, $9, $10
        19  => x"016c8020",  -- ADD $16, $11, $12
        20  => x"01a98822",  -- SUB $17, $13, $9
        21  => x"01ca9022",  -- SUB $18, $14, $10
        22  => x"012a9824",  -- AND $19, $9, $10
        23  => x"01eaa024",  -- AND $20, $23, $10 ; Nota: $23 se usa antes de ser establecido explícitamente por este programa, a menos que sea un resultado SLT
        24  => x"012aa825",  -- OR  $21, $9, $10
        25  => x"020ab025",  -- OR  $22, $16, $11
        26  => x"012ab82a",  -- SLT $23, $9, $11
        27  => x"020ac02a",  -- SLT $24, $16, $12
        28  => x"0800001c",  -- J 0x00000070 (Salta a la instrucción en el índice ROM 28, que es esta misma instrucción de salto)

        -- Inicializar el resto de la ROM con NOPs (x"00000000")
        others => x"00000000"
    );

    -- Señal de contenido de la ROM (opcional si se usa la constante directamente, pero bueno para claridad/síntesis FPGA)
    signal rom_content : rom_array_t := PROGRAM1;

begin
    -- Lectura combinacional desde la ROM
    -- Convertir dirección std_logic_vector a entero para indexación de array
    Instruction_o <= rom_content(to_integer(unsigned(Addr_Word_i)))
                     when (to_integer(unsigned(Addr_Word_i)) < PROGRAM1'length) else
                     x"00000000"; -- NOP para fuera de límites (aunque 'length se aplica al tipo aquí, mejor usar un tamaño fijo o la longitud real del programa)

    -- Una forma más segura para fuera de límites si PROGRAM1 no está completamente definido hasta 255:
    -- process(Addr_Word_i, rom_content)
    --     variable addr_int : integer;
    -- begin
    --     addr_int := to_integer(unsigned(Addr_Word_i));
    --     if addr_int >= 0 and addr_int < 29 then -- Número real de instrucciones en Programa 1
    --         Instruction_o <= rom_content(addr_int);
    --     else
    --         Instruction_o <= x"00000000"; -- NOP para fuera de límites
    --     end if;
    -- end process;
    -- Por simplicidad, se usa el acceso directo con la verificación 'length sobre el tipo,
    -- suponiendo que 'others' inicializa hasta la longitud del tipo.
    -- La solución proporcionada sobre el bloque de proceso es más típica para una ROM.
    -- La solución proporcionada PROGRAM1'length en realidad se referirá a la longitud del tipo rom_array_t (256).
    -- Una verificación más precisa sería contra el número real de instrucciones definidas si no queremos depender de 'others' por seguridad para direcciones superiores indefinidas.
    -- Sin embargo, dado que 'others' las inicializa a NOP, el acceso directo está bien.

end Behavioral;
