library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Not strictly needed but good practice

entity HazardUnit is
    Port (
        -- Inputs from IF/ID Register (for instruction currently in ID/EX stage)
        IF_ID_Rs_addr_i         : in  STD_LOGIC_VECTOR(4 downto 0); -- Rs of ID/EX instruction
        IF_ID_Rt_addr_i         : in  STD_LOGIC_VECTOR(4 downto 0); -- Rt of ID/EX instruction
        IF_ID_Inst_is_LW_i      : in  STD_LOGIC; -- Is the instruction in IF/ID an LW (needed for some hazard checks, though primary load-use is based on EX/MEM)
                                                -- Let's simplify: not directly needed if we check EXMEM_MemToReg for LW stalling.

        -- Inputs from ID/EX stage outputs (going into EX/MEM Register)
        -- Not strictly needed for forwarding/stall decisions as these are for the *current* instruction
        -- whose hazards are being evaluated based on *previous* instructions.
        -- However, EXMEM_RegWrite and EXMEM_WriteRegAddr are the *result* of the ID/EX stage.

        -- Inputs from EX/MEM Register outputs (for instruction currently in MEM/WB stage)
        EXMEM_RegWrite_i        : in  STD_LOGIC; -- RegWrite for instruction in MEM/WB stage
        EXMEM_WriteRegAddr_i    : in  STD_LOGIC_VECTOR(4 downto 0); -- Rd for instruction in MEM/WB stage
        EXMEM_MemToReg_i        : in  STD_LOGIC; -- MemToReg for instruction in MEM/WB stage (identifies LW)

        -- Inputs from MEM/WB stage outputs (write-back to Register File)
        MEMWB_RegWrite_i        : in  STD_LOGIC; -- RegWrite for instruction completing WB
        MEMWB_WriteRegAddr_i    : in  STD_LOGIC_VECTOR(4 downto 0); -- Rd for instruction completing WB

        -- Outputs
        ForwardA_sel_o          : out STD_LOGIC_VECTOR(1 downto 0); -- Mux select for ALU input A
        ForwardB_sel_o          : out STD_LOGIC_VECTOR(1 downto 0); -- Mux select for ALU input B
        PC_Stall_o              : out STD_LOGIC; -- Stall PC and IF/ID register
        IF_ID_Reg_Stall_o       : out STD_LOGIC; -- Stall IF/ID register (same as PC_Stall)
        IDEX_Bubble_o           : out STD_LOGIC  -- Insert NOP/bubble in ID/EX stage output (to EX/MEM reg)
    );
end HazardUnit;

architecture Behavioral of HazardUnit is
    signal load_use_hazard : STD_LOGIC;
begin

    -- ** Stall Detection (Load-Use Hazard) **
    -- Stall if instruction in ID/EX (using IF_ID_Rs_addr_i or IF_ID_Rt_addr_i)
    -- depends on an LW instruction currently in EX/MEM (EXMEM_MemToReg_i = '1').
    load_use_hazard <= '1' when (EXMEM_RegWrite_i = '1' and EXMEM_MemToReg_i = '1' and EXMEM_WriteRegAddr_i /= "00000") and
                               ((EXMEM_WriteRegAddr_i = IF_ID_Rs_addr_i) or
                                (EXMEM_WriteRegAddr_i = IF_ID_Rt_addr_i))
                       else '0';

    PC_Stall_o        <= load_use_hazard;
    IF_ID_Reg_Stall_o <= load_use_hazard; -- Stall IF/ID if PC is stalled
    IDEX_Bubble_o     <= load_use_hazard; -- Insert bubble if ID/EX instruction is stalled due to load-use

    -- ** Forwarding Logic **
    -- Priority: Forward from EX/MEM boundary first, then from MEM/WB boundary.
    -- Forwarding is only considered if not stalled (though typically forwarding logic is independent,
    -- and the stall simply delays the dependent instruction until forwarding is possible or data is in reg file).
    -- For simplicity here, forwarding signals are always calculated. The stall will ensure the
    -- correct data is eventually available for forwarding or from reg file.

    -- Forwarding for ALU Input A (sourced from IF_ID_Rs_addr_i)
    process(EXMEM_RegWrite_i, EXMEM_WriteRegAddr_i, MEMWB_RegWrite_i, MEMWB_WriteRegAddr_i, IF_ID_Rs_addr_i)
    begin
        if (EXMEM_RegWrite_i = '1' and EXMEM_WriteRegAddr_i = IF_ID_Rs_addr_i and EXMEM_WriteRegAddr_i /= "00000") then
            ForwardA_sel_o <= "01"; -- Forward from EX/MEM (ALU result of previous instruction)
        elsif (MEMWB_RegWrite_i = '1' and MEMWB_WriteRegAddr_i = IF_ID_Rs_addr_i and MEMWB_WriteRegAddr_i /= "00000") then
            ForwardA_sel_o <= "10"; -- Forward from MEM/WB (data being written back)
        else
            ForwardA_sel_o <= "00"; -- No forwarding, use register file
        end if;
    end process;

    -- Forwarding for ALU Input B (sourced from IF_ID_Rt_addr_i)
    process(EXMEM_RegWrite_i, EXMEM_WriteRegAddr_i, MEMWB_RegWrite_i, MEMWB_WriteRegAddr_i, IF_ID_Rt_addr_i)
    begin
        if (EXMEM_RegWrite_i = '1' and EXMEM_WriteRegAddr_i = IF_ID_Rt_addr_i and EXMEM_WriteRegAddr_i /= "00000") then
            ForwardB_sel_o <= "01"; -- Forward from EX/MEM
        elsif (MEMWB_RegWrite_i = '1' and MEMWB_WriteRegAddr_i = IF_ID_Rt_addr_i and MEMWB_WriteRegAddr_i /= "00000") then
            ForwardB_sel_o <= "10"; -- Forward from MEM/WB
        else
            ForwardB_sel_o <= "00"; -- No forwarding, use register file
        end if;
    end process;

end Behavioral;
