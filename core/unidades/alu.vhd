library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    port (
        a       : in  std_logic_vector(31 downto 0);
        b       : in  std_logic_vector(31 downto 0);
        control : in  std_logic_vector(3 downto 0);
        result  : out std_logic_vector(31 downto 0);
        zero    : out std_logic
    );
end entity ALU;

architecture Behavioral of ALU is
    signal alu_result_internal : std_logic_vector(31 downto 0);
begin
    process(a, b, control)
    begin
        case control is
            when "0000" => -- AND
                alu_result_internal <= a and b;
            when "0001" => -- OR
                alu_result_internal <= a or b;
            when "0010" => -- ADD
                alu_result_internal <= std_logic_vector(signed(a) + signed(b));
            when "0110" => -- SUB
                alu_result_internal <= std_logic_vector(signed(a) - signed(b));
            when "0111" => -- SLT (Set on Less Than)
                if signed(a) < signed(b) then
                    alu_result_internal <= std_logic_vector(to_signed(1, 32));
                else
                    alu_result_internal <= std_logic_vector(to_signed(0, 32));
                end if;
            when others => -- Default / Undefined
                alu_result_internal <= (others => 'X'); -- Or some default value like all zeros
        end case;
    end process;

    result <= alu_result_internal;
    zero   <= '1' when alu_result_internal = std_logic_vector(to_signed(0, 32)) else '0';

end architecture Behavioral;
