library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IF_stage is
    Port (
        clk : in std_logic;
        reset : in std_logic;
        PC_in : in std_logic_vector(31 downto 0);
        PC_out : out std_logic_vector(31 downto 0);
        I_data_IN : in std_logic_vector(31 downto 0);
        IN_adder : out std_logic_vector(31 downto 0)
    );
end IF_stage;

architecture Behavioral of IF_stage is
    -- Señales internas
    signal mux_out : std_logic_vector(31 downto 0);
    signal sum_out : std_logic_vector(31 downto 0);
    signal cout    : std_logic;
    constant CUATRO : std_logic_vector(3 downto 0) := "0100";  -- 4 constante 
    
 -- Señales internas
    signal IF_Inst : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Componente Memory (Instruction Memory)
    component Memory is
        generic(
            C_FUNC_CLK    : std_logic := '1';
            C_ELF_FILENAME    : string := "program";
            C_MEM_SIZE        : integer := 1024
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

    -- Componente reg_if_id
    component reg_if_id is
        Port ( 
            Clk     : in  STD_LOGIC;
            Reset   : in  STD_LOGIC;
            IF_Inst : in  STD_LOGIC_VECTOR(31 downto 0);
            ID_Inst : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin
    -- Instanciar el multiplexor
    mux_inst : entity work.mux2_1
        generic map (
            N => 32
        )
        port map (
            mux_ctl => '0',  -- el control viene de pc_branch
            mux_in0 => PC_in,
            mux_in1 => (others => '0'),
            mux_out => mux_out
        );

    -- Instanciar el sumador completo
    adder_inst : entity work.full_adder
        generic map (
            N => 4
        )
        port map (
            A    => mux_out(3 downto 0),  -- solo los 4 bits menos significativos
            B    => CUATRO,               -- constante 4 en 4 bits
            CIN  => '0',
            SUM  => sum_out(3 downto 0),  -- solo los 4 bits menos significativos
            COUT => cout
        );



    -- Proceso del registro PC
    process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
            IN_adder <= (others => '0');
        elsif rising_edge(clk) then
            PC_out <= mux_out;
            IN_adder <= sum_out;
        end if;
    end process;

-- Instancia de la memoria de instrucciones
    inst_memory: Memory
        generic map (
            C_FUNC_CLK => '1',
            C_ELF_FILENAME => "program",
            C_MEM_SIZE => 1024
        )
        port map (
            Addr    => PC,
            DataIn  => (others => '0'),  -- No se escribe en la memoria de instrucciones
            RdStb   => '1',              -- Siempre leemos instrucciones
            WrStb   => '0',              -- No escribimos en la memoria de instrucciones
            Clk     => Clk,
            Reset   => Reset,
            DataOut => IF_Inst
        );

    -- Instancia del registro IF/ID
    inst_reg_if_id: reg_if_id
        port map (
            Clk     => Clk,
            Reset   => Reset,
            IF_Inst => IF_Inst,
            ID_Inst => ID_Inst
        );


end Behavioral;
