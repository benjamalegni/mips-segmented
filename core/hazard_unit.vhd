-- ======================
-- ====    Autor LB Malegni
-- ====    Arquitectura de Computadoras 1 - 2025
--
-- ====== MIPS
-- ======================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- No es estrictamente necesario pero es buena práctica

entity HazardUnit is
    Port (
        -- Entradas desde el Registro IF/ID (para la instrucción actualmente en la etapa ID/EX)
        IF_ID_Rs_addr_i         : in  STD_LOGIC_VECTOR(4 downto 0); -- Rs de la instrucción ID/EX
        IF_ID_Rt_addr_i         : in  STD_LOGIC_VECTOR(4 downto 0); -- Rt de la instrucción ID/EX
        IF_ID_Inst_is_LW_i      : in  STD_LOGIC; -- ¿Es la instrucción en IF/ID un LW (necesario para algunas verificaciones de riesgo, aunque el riesgo primario de carga-uso se basa en EX/MEM)
                                                -- Simplifiquemos: no es directamente necesario si verificamos EXMEM_MemToReg para el bloqueo por LW.

        -- Entradas desde las salidas de la etapa ID/EX (que van al Registro EX/MEM)
        -- No son estrictamente necesarias para las decisiones de adelantamiento/bloqueo, ya que estas son para la instrucción *actual*
        -- cuyos riesgos se evalúan en función de las instrucciones *anteriores*.
        -- Sin embargo, EXMEM_RegWrite y EXMEM_WriteRegAddr son el *resultado* de la etapa ID/EX.

        -- Entradas desde las salidas del Registro EX/MEM (para la instrucción actualmente en la etapa MEM/WB)
        EXMEM_RegWrite_i        : in  STD_LOGIC; -- RegWrite para la instrucción en la etapa MEM/WB
        EXMEM_WriteRegAddr_i    : in  STD_LOGIC_VECTOR(4 downto 0); -- Rd para la instrucción en la etapa MEM/WB
        EXMEM_MemToReg_i        : in  STD_LOGIC; -- MemToReg para la instrucción en la etapa MEM/WB (identifica LW)

        -- Entradas desde las salidas de la etapa MEM/WB (escritura de retorno al Archivo de Registros)
        MEMWB_RegWrite_i        : in  STD_LOGIC; -- RegWrite para la instrucción que completa WB
        MEMWB_WriteRegAddr_i    : in  STD_LOGIC_VECTOR(4 downto 0); -- Rd para la instrucción que completa WB

        -- Salidas
        ForwardA_sel_o          : out STD_LOGIC_VECTOR(1 downto 0); -- Selección del Mux para la entrada A de la ALU
        ForwardB_sel_o          : out STD_LOGIC_VECTOR(1 downto 0); -- Selección del Mux para la entrada B de la ALU
        PC_Stall_o              : out STD_LOGIC; -- Bloquear PC y registro IF/ID
        IF_ID_Reg_Stall_o       : out STD_LOGIC; -- Bloquear registro IF/ID (igual que PC_Stall)
        IDEX_Bubble_o           : out STD_LOGIC  -- Insertar NOP/burbuja en la salida de la etapa ID/EX (al registro EX/MEM)
    );
end HazardUnit;

architecture Behavioral of HazardUnit is
    signal load_use_hazard : STD_LOGIC;
begin

    -- ** Detección de Bloqueo (Riesgo de Carga-Uso) **
    -- Bloquear si la instrucción en ID/EX (usando IF_ID_Rs_addr_i o IF_ID_Rt_addr_i)
    -- depende de una instrucción LW actualmente en EX/MEM (EXMEM_MemToReg_i = '1').
    load_use_hazard <= '1' when (EXMEM_RegWrite_i = '1' and EXMEM_MemToReg_i = '1' and EXMEM_WriteRegAddr_i /= "00000") and
                               ((EXMEM_WriteRegAddr_i = IF_ID_Rs_addr_i) or
                                (EXMEM_WriteRegAddr_i = IF_ID_Rt_addr_i))
                       else '0';

    PC_Stall_o        <= load_use_hazard;
    IF_ID_Reg_Stall_o <= load_use_hazard; -- Bloquear IF/ID si PC está bloqueado
    IDEX_Bubble_o     <= load_use_hazard; -- Insertar burbuja si la instrucción ID/EX está bloqueada debido a carga-uso

    -- ** Lógica de Adelantamiento **
    -- Prioridad: Adelantar desde el límite EX/MEM primero, luego desde el límite MEM/WB.
    -- El adelantamiento solo se considera si no está bloqueado (aunque típicamente la lógica de adelantamiento es independiente,
    -- y el bloqueo simplemente retrasa la instrucción dependiente hasta que el adelantamiento sea posible o los datos estén en el archivo de registros).
    -- Para simplificar aquí, las señales de adelantamiento siempre se calculan. El bloqueo asegurará que
    -- los datos correctos estén finalmente disponibles para el adelantamiento o desde el archivo de registros.

    -- Adelantamiento para la Entrada A de la ALU (proviene de IF_ID_Rs_addr_i)
    process(EXMEM_RegWrite_i, EXMEM_WriteRegAddr_i, MEMWB_RegWrite_i, MEMWB_WriteRegAddr_i, IF_ID_Rs_addr_i)
    begin
        if (EXMEM_RegWrite_i = '1' and EXMEM_WriteRegAddr_i = IF_ID_Rs_addr_i and EXMEM_WriteRegAddr_i /= "00000") then
            ForwardA_sel_o <= "01"; -- Adelantar desde EX/MEM (resultado ALU de la instrucción anterior)
        elsif (MEMWB_RegWrite_i = '1' and MEMWB_WriteRegAddr_i = IF_ID_Rs_addr_i and MEMWB_WriteRegAddr_i /= "00000") then
            ForwardA_sel_o <= "10"; -- Adelantar desde MEM/WB (datos que se están escribiendo de retorno)
        else
            ForwardA_sel_o <= "00"; -- Sin adelantamiento, usar archivo de registros
        end if;
    end process;

    -- Adelantamiento para la Entrada B de la ALU (proviene de IF_ID_Rt_addr_i)
    process(EXMEM_RegWrite_i, EXMEM_WriteRegAddr_i, MEMWB_RegWrite_i, MEMWB_WriteRegAddr_i, IF_ID_Rt_addr_i)
    begin
        if (EXMEM_RegWrite_i = '1' and EXMEM_WriteRegAddr_i = IF_ID_Rt_addr_i and EXMEM_WriteRegAddr_i /= "00000") then
            ForwardB_sel_o <= "01"; -- Adelantar desde EX/MEM
        elsif (MEMWB_RegWrite_i = '1' and MEMWB_WriteRegAddr_i = IF_ID_Rt_addr_i and MEMWB_WriteRegAddr_i /= "00000") then
            ForwardB_sel_o <= "10"; -- Adelantar desde MEM/WB
        else
            ForwardB_sel_o <= "00"; -- Sin adelantamiento, usar archivo de registros
        end if;
    end process;

end Behavioral;
