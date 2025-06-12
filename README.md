[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/benjamalegni/mips-segmented)

Purpose and Scope
This document provides a high-level introduction to the MIPS processor implementation located in this repository. The system implements a complete 3-stage pipelined MIPS processor with Harvard architecture, hazard detection, and comprehensive testing infrastructure.

This overview covers the system architecture, pipeline organization, and key component relationships. For detailed implementation of individual pipeline stages, see Pipeline Stages. For hazard detection mechanisms, see Hazard Detection and Resolution. For testing procedures, see Testing and Verification.

System Architecture
The MIPS processor is implemented as a coordinated 3-stage pipeline system with separate instruction and data memory paths. The top-level MIPS entity orchestrates all pipeline stages and shared resources.

Top-Level System Organization
MIPS Processor System

Testing

Storage Components

Control System

Pipeline Registers

Pipeline Stages

mips_tb
mips_tb.vhd

MIPS
MIPS.vhd
Top-Level Orchestrator

if_stage
core/etapas/if_stage.vhd
Instruction Fetch

idex_stage
core/etapas/idex_stage.vhd
Decode/Execute

memwb_stage
core/etapas/memwb_stage.vhd
Memory/Write-Back

reg_if_id
IF-ID Pipeline Register

reg_idex_memwb
ID-MEM Pipeline Register

ControlUnit
core/control/control_unit.vhd

ALUControl
core/control/alu_control.vhd

HazardUnit
core/hazard_unit.vhd

Memory
Instruction Memory Component

DataMemory
Data Memory Component

register_file
core/unidades/register_file.vhd

program.hex
program2.hex

Sources: 
MIPS.vhd
 
core/etapas/if_stage.vhd
 
core/etapas/idex_stage.vhd
 
core/etapas/memwb_stage.vhd
 
core/control/control_unit.vhd
 
core/control/alu_control.vhd
 
core/hazard_unit.vhd
 
core/unidades/register_file.vhd
 
mips_tb.vhd

Pipeline Organization
The processor implements a 3-stage pipeline with dedicated pipeline registers for inter-stage communication and hazard management.

Pipeline Data Flow
Shared Resources

Stage 3: MEM-WB

Pipeline Register 2

Stage 2: ID-EX

Pipeline Register 1

Stage 1: IF

Program Counter

Instruction Fetch Logic

Instruction Memory
1KB capacity

reg_if_id
32-bit instruction
32-bit PC+4

Instruction Decode

ALU Execution

Control Generation

Hazard Detection

reg_idex_memwb
ALU Result
Control Signals
Write Data

Memory Access

Register Writeback

Data Memory
Byte addressable

register_file
32x32-bit registers
Dual-port read

HazardUnit
Forwarding & Stalling

Sources: 
core/etapas/if_stage.vhd
 
core/etapas/idex_stage.vhd
 
core/etapas/memwb_stage.vhd
 
core/hazard_unit.vhd
 
core/unidades/register_file.vhd

Key Subsystems
Pipeline Stages
IF Stage (if_stage): Manages program counter and fetches instructions from instruction memory
ID-EX Stage (idex_stage): Decodes instructions, performs ALU operations, and generates control signals
MEM-WB Stage (memwb_stage): Handles data memory access and register file write-back operations
Control Hierarchy
Main Control Unit (ControlUnit): Generates high-level control signals from instruction opcodes
ALU Control Unit (ALUControl): Produces specific ALU operation codes based on instruction type
Hazard Unit (HazardUnit): Manages data forwarding, pipeline stalling, and bubble insertion
Memory System
Harvard Architecture: Separate instruction memory (Memory) and data memory (DataMemory)
Register File (register_file): 32-register storage with dual-port read capability
Pipeline Registers: reg_if_id and reg_idex_memwb for inter-stage data buffering
Supported Instructions
The processor implements core MIPS instruction types:

Category	Instructions	Control Unit
R-type	add, sub, and, or, slt	ControlUnit + ALUControl
Load	lw (load word)	ControlUnit
Store	sw (store word)	ControlUnit
Branch	beq (branch equal)	ControlUnit
Jump	j (jump)	ControlUnit
Testing Infrastructure
Testbench (mips_tb): Comprehensive verification environment
Test Programs: program.hex and program2.hex for functional verification
ELF Loading: Support for loading executable programs into instruction memory
Sources: 
README.md
1-90
 
core/control/control_unit.vhd
 
core/control/alu_control.vhd
 
mips_tb.vhd

Implementation Features
The MIPS processor includes several advanced features for pipeline efficiency:

Data Forwarding: Resolves data hazards through forwarding paths between pipeline stages
Hazard Detection: Identifies load-use hazards and control hazards
Pipeline Control: Implements stalling and bubble insertion for hazard resolution
Harvard Memory Model: Optimizes instruction and data access with separate memory spaces
Comprehensive Testing: Includes testbench and multiple test programs for verification
This implementation provides a complete, functional MIPS processor suitable for educational purposes and basic computation tasks.
