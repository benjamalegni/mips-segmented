library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ControlUnit is
    port (
        -- Inputs
        OP          : in  std_logic_vector(5 downto 0);  -- Opcode
        Funct       : in  std_logic_vector(5 downto 0);  -- Function field for R-type
        
        -- Main Control Outputs
        RegWrite    : out std_logic;
        RegDst      : out std_logic;
        Branch      : out std_logic;
        MemRead     : out std_logic;
        MemtoReg    : out std_logic;
        MemWrite    : out std_logic;
        ALUSrc      : out std_logic;
        Jump        : out std_logic;
        
        -- ALU Control Output
        ALUControl  : out std_logic_vector(3 downto 0)
    );
end entity ControlUnit;

architecture Behavioral of ControlUnit is
    -- Internal signals
    signal ALUOp : std_logic_vector(1 downto 0);
begin
    -- Main Control Logic
    process(OP)
    begin
        case OP is
            -- R-type
            when "000000" =>
                RegWrite <= '1';
                RegDst <= '1';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "10";
            
            -- lw
            when "100011" => 
                RegWrite <= '1';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '1';
                MemtoReg <= '1';
                MemWrite <= '0';
                ALUSrc <= '1';
                Jump <= '0';
                ALUOp <= "00";
                
            -- sw 
            when "101011" => 
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '1';
                ALUSrc <= '1';
                Jump <= '0';
                ALUOp <= "00";

            -- beq 
            when "000100" => 
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '1';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "01";
          
            -- jump
            when "000010" =>
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '1';
                ALUOp <= "00";        
		
            -- otros
            when others =>		
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "00";		
        end case;
    end process;

    -- ALU Control Logic
    process(ALUOp, Funct)
    begin
        case ALUOp is
            when "00" =>  -- LW o SW → Suma
                ALUControl <= "0010"; -- ADD

            when "01" =>  -- BEQ → Resta
                ALUControl <= "0110"; -- SUB

            when "10" =>  -- R-type: usar funct
                case Funct is
                    when "100000" =>  -- ADD
                        ALUControl <= "0010";
                    when "100010" =>  -- SUB
                        ALUControl <= "0110";
                    when "100100" =>  -- AND
                        ALUControl <= "0000";
                    when "100101" =>  -- OR
                        ALUControl <= "0001";
                    when "101010" =>  -- SLT
                        ALUControl <= "0111";
                    when others =>
                        ALUControl <= "1111"; -- Instrucción R-type no válida
                end case;

            when others =>
                ALUControl <= "1111"; -- ALUOp no válido
        end case;
    end process;
end architecture Behavioral; 