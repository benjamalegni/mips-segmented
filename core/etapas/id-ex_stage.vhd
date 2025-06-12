library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Importar componentes necesarios
library work;
use work.ram.all;
use work.alu_control.all;

entity id_ex_stage is
    Port (
        -- Señales básicas
        clk     : in  STD_LOGIC;                    -- Reloj
        reset   : in  STD_LOGIC;                    -- Reset
        
        -- Entradas de la etapa ID
        Reg_IF_ID_out : in std_logic_vector(31 downto 0);    -- Instrucción actual
        Reg_write: in std_logic;                             -- Señal de escritura en registros
        Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0);  -- PC+4

        -- Entradas para el banco de registros
        write_data: in std_logic_vector(31 downto 0);        -- Dato a escribir
        write_reg: in std_logic_vector(4 downto 0);          -- Registro destino

        -- Salidas del registro ID-EX
        id_ex_jump_out      : out std_logic;                 -- Señal de salto
        id_ex_pc_branch_out : out std_logic_vector(31 downto 0);  -- PC para branch
        id_ex_pc_adder_out  : out std_logic_vector(31 downto 0);  -- PC+4 o destino branch
        id_ex_alu_result_out: out std_logic_vector(31 downto 0);  -- Resultado ALU
        id_ex_read_data2_out: out std_logic_vector(31 downto 0);  -- Dato leído 2
        id_ex_mux_out_out   : out std_logic_vector(4 downto 0);   -- Selección rt/rd
        id_ex_mem_write_out : out std_logic;                 -- Escritura memoria
        id_ex_mem_read_out  : out std_logic;                 -- Lectura memoria
        id_ex_branch_out    : out std_logic                  -- Señal branch
    );
end id_ex_stage;

architecture Behavioral of id_ex_stage is
    -- Campos de la instrucción
    signal rs : std_logic_vector(4 downto 0);        -- Registro fuente 1
    signal rt : std_logic_vector(4 downto 0);        -- Registro fuente 2
    signal rd : std_logic_vector(4 downto 0);        -- Registro destino
    signal immediate : std_logic_vector(31 downto 0); -- Valor inmediato
    signal opcode : std_logic_vector(5 downto 0);     -- Código de operación

    -- Señales del banco de registros
    signal read_data1 : std_logic_vector(31 downto 0); -- Dato leído 1
    signal read_data2 : std_logic_vector(31 downto 0); -- Dato leído 2

    -- Señales de la unidad de control
    signal RegWrite    : std_logic;                  -- Escritura en registros
    signal RegDst      : std_logic;                  -- Selección registro destino
    signal Branch      : std_logic;                  -- Señal de branch
    signal MemRead     : std_logic;                  -- Lectura de memoria
    signal MemtoReg    : std_logic;                  -- Memoria a registro
    signal MemWrite    : std_logic;                  -- Escritura en memoria
    signal ALUSrc      : std_logic;                  -- Fuente ALU
    signal Jump        : std_logic;                  -- Salto
    signal ALUOp       : std_logic_vector(1 downto 0); -- Operación ALU

    -- Señales de la ALU
    signal ALU_oper_b : std_logic_vector(31 downto 0); -- Segundo operando ALU
    signal ALU_control : std_logic_vector(3 downto 0);  -- Control ALU
    signal ALU_zero : std_logic;                       -- Flag cero
    signal ALU_result : std_logic_vector(31 downto 0); -- Resultado ALU

    -- Señales internas del registro ID-EX
    signal id_ex_jump : std_logic;                     -- Salto
    signal id_ex_pc_branch : std_logic_vector(31 downto 0); -- PC branch
    signal id_ex_pc_adder : std_logic_vector(31 downto 0);  -- PC+4/branch
    signal id_ex_alu_result : std_logic_vector(31 downto 0); -- Resultado ALU
    signal id_ex_read_data2 : std_logic_vector(31 downto 0); -- Dato leído 2
    signal id_ex_mux_out : std_logic_vector(4 downto 0);     -- Selección rt/rd
    signal id_ex_mem_write : std_logic;                      -- Escritura memoria
    signal id_ex_mem_read : std_logic;                       -- Lectura memoria
    signal id_ex_branch : std_logic;                         -- Branch

    -- Componente banco de registros
    component Registers is
        port (
            CLK         : in  std_logic;                     -- Reloj
            RESET       : in  std_logic;                     -- Reset
            RegWrite    : in  std_logic;                     -- Escritura
            ReadReg1    : in  std_logic_vector(4 downto 0);  -- Registro lectura 1
            ReadReg2    : in  std_logic_vector(4 downto 0);  -- Registro lectura 2
            WriteReg    : in  std_logic_vector(4 downto 0);  -- Registro escritura
            WriteData   : in  std_logic_vector(31 downto 0); -- Dato escritura
            ReadData1   : out std_logic_vector(31 downto 0); -- Dato lectura 1
            ReadData2   : out std_logic_vector(31 downto 0)  -- Dato lectura 2
        );
    end component;

    -- Componente unidad de control
    component ControlUnit is
        port (
            I_DataIn    : in  std_logic_vector(31 downto 0); -- Instrucción
            RegWrite    : out std_logic;                     -- Escritura registros
            RegDst      : out std_logic;                     -- Selección destino
            Branch      : out std_logic;                     -- Branch
            MemRead     : out std_logic;                     -- Lectura memoria
            MemtoReg    : out std_logic;                     -- Memoria a registro
            MemWrite    : out std_logic;                     -- Escritura memoria
            ALUSrc      : out std_logic;                     -- Fuente ALU
            Jump        : out std_logic;                     -- Salto
            ALUOp       : out std_logic_vector(1 downto 0)   -- Operación ALU
        );
    end component;

    -- Componente ALU
    component ALU is
        port (
            a       : in  std_logic_vector(31 downto 0); -- Operando 1
            b       : in  std_logic_vector(31 downto 0); -- Operando 2
            control : in  std_logic_vector(3 downto 0);  -- Control
            zero    : out std_logic;                     -- Flag cero
            result  : out std_logic_vector(31 downto 0)  -- Resultado
        );
    end component;

    -- Componente control ALU
    component ALUControl is
        port (
            ALUOp : in std_logic_vector(1 downto 0);     -- Operación ALU
            Funct : in std_logic_vector(5 downto 0);     -- Función
            ALUControlOut : out std_logic_vector(3 downto 0) -- Control ALU
        );
    end component;

begin
    -- Extraer campos de la instrucción
    rs <= Reg_IF_ID_out(25 downto 21);        -- Registro fuente 1
    rt <= Reg_IF_ID_out(20 downto 16);        -- Registro fuente 2
    rd <= Reg_IF_ID_out(15 downto 11);        -- Registro destino
    immediate <= Reg_IF_ID_out(15 downto 0);  -- Valor inmediato
    opcode <= Reg_IF_ID_out(31 downto 26);    -- Código operación

    -- Instanciar banco de registros
    reg_file: Registers port map (
        CLK => clk,
        RESET => reset,
        RegWrite => Reg_write,
        ReadReg1 => rs,
        ReadReg2 => rt,
        WriteReg => write_reg,
        WriteData => write_data,
        ReadData1 => read_data1,
        ReadData2 => read_data2
    );

    -- Instanciar unidad de control
    control_unit: ControlUnit port map (
        I_DataIn => Reg_IF_ID_out,
        RegWrite => RegWrite,
        RegDst => RegDst,
        Branch => Branch,
        MemRead => MemRead,
        MemtoReg => MemtoReg,
        MemWrite => MemWrite,
        ALUSrc => ALUSrc,
        Jump => Jump,
        ALUOp => ALUOp
    );

    -- Instanciar control ALU
    alu_control_unit: ALUControl port map (
        ALUOp => ALUOp,
        Funct => Reg_IF_ID_out(5 downto 0),
        ALUControlOut => ALU_control
    );

    -- Multiplexor segundo operando ALU
    ALU_oper_b <= read_data2 when (ALUSrc = '0') else immediate;

    -- Instanciar ALU
    alu_unit: ALU port map(
        a => read_data1,
        b => ALU_oper_b,
        control => ALU_control,
        zero => ALU_zero,
        result => ALU_result
    );

    -- Proceso registro ID-EX
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset de todas las salidas
            id_ex_jump <= '0';
            id_ex_pc_branch <= (others => '0');
            id_ex_pc_adder <= (others => '0');
            id_ex_alu_result <= (others => '0');
            id_ex_read_data2 <= (others => '0');
            id_ex_mux_out <= (others => '0');
            id_ex_mem_write <= '0';
            id_ex_mem_read <= '0';
            id_ex_branch <= '0';
        elsif rising_edge(clk) then
            -- Propagar señales
            id_ex_jump <= Jump;
            id_ex_pc_branch <= Reg_IF_ID_out;  -- PC para branch
            id_ex_pc_adder <= Reg_IF_ID_out;   -- PC+4 o destino branch
            id_ex_alu_result <= ALU_result;    -- Resultado ALU
            id_ex_read_data2 <= read_data2;    -- Dato leído 2
            id_ex_mux_out <= rt when (RegDst = '0') else rd;  -- Selección rt/rd
            id_ex_mem_write <= MemWrite;       -- Escritura memoria
            id_ex_mem_read <= MemRead;         -- Lectura memoria
            id_ex_branch <= Branch;            -- Branch
        end if;
    end process;

    -- Conectar señales internas a puertos de salida
    id_ex_jump_out <= id_ex_jump;
    id_ex_pc_branch_out <= id_ex_pc_branch;
    id_ex_pc_adder_out <= id_ex_pc_adder;
    id_ex_alu_result_out <= id_ex_alu_result;
    id_ex_read_data2_out <= id_ex_read_data2;
    id_ex_mux_out_out <= id_ex_mux_out;
    id_ex_mem_write_out <= id_ex_mem_write;
    id_ex_mem_read_out <= id_ex_mem_read;
    id_ex_branch_out <= id_ex_branch;

end Behavioral;

