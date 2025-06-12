-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ControlUnit is
    port (
        -- Entradas
        OP          : in  std_logic_vector(5 downto 0);  -- Código de operación
        -- La entrada Funct se elimina
        
        -- Salidas de Control Principal
        RegWrite    : out std_logic;
        RegDst      : out std_logic;
        Branch      : out std_logic;
        MemRead     : out std_logic;
        MemtoReg    : out std_logic;
        MemWrite    : out std_logic;
        ALUSrc      : out std_logic;
        Jump        : out std_logic;
        
        -- Salida de Control ALU cambiada a ALUOp de 2 bits
        ALUOp_o     : out std_logic_vector(1 downto 0)
    );
end entity ControlUnit;

architecture Behavioral of ControlUnit is
    -- Señales internas
    signal ALUOp : std_logic_vector(1 downto 0); -- Esta señal es generada por la lógica de control principal
begin
    -- Lógica de Control Principal (determina ALUOp y otras señales de control)
    process(OP)
    begin
        case OP is
            -- Tipo R
            when "000000" =>
                RegWrite <= '1';
                RegDst   <= '1';
                Branch   <= '0';
                MemRead  <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc   <= '0';
                Jump     <= '0';
                ALUOp    <= "10"; -- ALUOp para tipo R
            
            -- lw
            when "100011" => 
                RegWrite <= '1';
                RegDst   <= '0';
                Branch   <= '0';
                MemRead  <= '1';
                MemtoReg <= '1';
                MemWrite <= '0';
                ALUSrc   <= '1';
                Jump     <= '0';
                ALUOp    <= "00"; -- ALUOp para lw/sw (suma)
                
            -- sw 
            when "101011" => 
                RegWrite <= '0';
                RegDst   <= '0'; -- Típicamente 'X' o no importa, pero establecer en 0 es seguro
                Branch   <= '0';
                MemRead  <= '0';
                MemtoReg <= '0'; -- Típicamente 'X'
                MemWrite <= '1';
                ALUSrc   <= '1';
                Jump     <= '0';
                ALUOp    <= "00"; -- ALUOp para lw/sw (suma)

            -- beq 
            when "000100" => 
                RegWrite <= '0';
                RegDst   <= '0'; -- Típicamente 'X'
                Branch   <= '1';
                MemRead  <= '0';
                MemtoReg <= '0'; -- Típicamente 'X'
                MemWrite <= '0';
                ALUSrc   <= '0';
                Jump     <= '0';
                ALUOp    <= "01"; -- ALUOp para beq (resta)
          
            -- jump
            when "000010" =>
                RegWrite <= '0';
                RegDst   <= '0'; -- Típicamente 'X'
                Branch   <= '0';
                MemRead  <= '0';
                MemtoReg <= '0'; -- Típicamente 'X'
                MemWrite <= '0';
                ALUSrc   <= '0'; -- Típicamente 'X'
                Jump     <= '1';
                ALUOp    <= "00"; -- ALUOp puede ser cualquiera, el resultado de ALU no se usa para la ruta principal
		
            -- otros (otros códigos de operación - por defecto a valores seguros/similares a NOP)
            when others =>		
                RegWrite <= '0';
                RegDst   <= '0';
                Branch   <= '0';
                MemRead  <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc   <= '0';
                Jump     <= '0';
                ALUOp    <= "00"; -- ALUOp por defecto
        end case;
    end process;

    -- Asignar el ALUOp de 2 bits generado al puerto de salida
    ALUOp_o <= ALUOp;

    -- El segundo proceso que generaba ALUControl de 4 bits basado en ALUOp y Funct se elimina.
    -- Esa lógica ahora está en el módulo ALUControl separado.

end architecture Behavioral;
