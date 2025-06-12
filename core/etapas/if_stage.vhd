library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IF_stage is
    Port (
        clk : in std_logic;
        reset : in std_logic;
        PC_jump : in std_logic_vector(31 downto 0);
        PC_branch : in std_logic;
        PC_sel : in std_logic_vector(1 downto 0);
        M_out: in std_logic_vector(31 downto 0); -- salida del registro ex/mem  que luego va al mux

        -- register id/id
        Reg_IF_ID_out : out std_logic_vector(31 downto 0);
        Reg_IF_ID_PC_plus_4_out : out std_logic_vector(31 downto 0)
    );
end IF_stage;

architecture Behavioral of IF_stage is
    signal mux_out : std_logic_vector(31 downto 0);
    signal PC_plus_4 : std_logic_vector(31 downto 0);
    signal PC_out : std_logic_vector(31 downto 0);
    signal PC_in : std_logic_vector(31 downto 0);
    signal DataOut : std_logic_vector(31 downto 0);

    component Memory is
        generic(
            C_FUNC_CLK : std_logic := '1';
            C_ELF_FILENAME : string := "program";
            C_MEM_SIZE : integer := 1024
        );
        Port ( 
            Addr : in std_logic_vector(31 downto 0);
            DataIn : in std_logic_vector(31 downto 0);
            RdStb : in std_logic;
            WrStb : in std_logic;
            Clk : in std_logic;
            Reset : in std_logic;
            DataOut : out std_logic_vector(31 downto 0)
        );
    end component;

    component reg_if_id is
        Port (
            clk            : in  STD_LOGIC;               -- Reloj
            reset          : in  STD_LOGIC;               -- Reset asíncrono
            flush          : in  STD_LOGIC;               -- Limpiar registro (ej: en saltos)
            stall          : in  STD_LOGIC;               -- Congelar registro (riesgos)
            PC_plus_4_in   : in  STD_LOGIC_VECTOR(31 downto 0);  -- Entrada: PC + 4
            Instruction_in : in  STD_LOGIC_VECTOR(31 downto 0);  -- Entrada: Instrucción
            PC_plus_4_out  : out STD_LOGIC_VECTOR(31 downto 0);  -- Salida registrada: PC + 4
            Instruction_out: out STD_LOGIC_VECTOR(31 downto 0)   -- Salida registrada: Instrucción
        );
    end component;

begin
    mux_inst : entity work.mux2_1
        generic map (N => 32)
        port map (
            mux_ctl => PC_branch,
            mux_in0 => PC_plus_4,
            mux_in1 => M_out,
            mux_out => PC_in
        );

    -- sumacion de 4 para obtener la siguiente direccion de instruccion
    PC_plus_4 <= PC_in + 4;

    process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
        elsif rising_edge(clk) then
            PC_out <= PC_in;
        end if;
    end process;

    inst_memory: Memory
        generic map (
            C_FUNC_CLK => '1',
            C_ELF_FILENAME => "program",
            C_MEM_SIZE => 1024
        )
        port map (
            Addr => PC_out,
            DataIn => (others => '0'),
            RdStb => '1',
            WrStb => '0',
            Clk => clk,
            Reset => reset,
            DataOut => DataOut
        );

    inst_reg_if_id: reg_if_id
        port map (
            clk => clk,
            reset => reset,
            flush => '0',  -- Por defecto no hay flush
            stall => '0',  -- Por defecto no hay stall
            PC_plus_4_in => PC_plus_4,
            Instruction_in => DataOut,
            PC_plus_4_out => Reg_IF_ID_PC_plus_4_out,
            Instruction_out => Reg_IF_ID_out
        );

end Behavioral;