library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALUControl is
    port (
        ALUOp      : in  std_logic_vector(1 downto 0);
        Funct      : in  std_logic_vector(5 downto 0); -- solo se usa si R-type
        ALUControl : out std_logic_vector(3 downto 0)
    );
end entity ALUControl;

architecture Behavioral of ALUControl is
begin
    process(ALUOp, Funct)
    begin
        case ALUOp is
            when "00" =>  -- LW o SW -> Suma
                ALUControl <= "0010"; -- ADD

            when "01" =>  -- BEQ -> Resta
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
                        ALUControl <= "1111"; -- Instrucción R-type no válida / Undefined
                end case;

            when others =>
                ALUControl <= "1111"; -- ALUOp no válido / Undefined
        end case;
    end process;
end architecture Behavioral;
