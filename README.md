[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/benjamalegni/mips-segmented)

# Resumen del Procesador MIPS

Este documento proporciona una visión general de alto nivel de la implementación del procesador MIPS con pipeline, enfocándose en la arquitectura general del sistema, el diseño del pipeline y las interacciones entre componentes clave.

## Propósito y Alcance

Este documento cubre la entidad `MIPS` de nivel superior y la coordinación entre las tres etapas principales del pipeline: Instruction Fetch (IF), Instruction Decode/Execute (ID-EX), y Memory/Write-Back (MEM-WB). [1](#0-0) 

## Arquitectura del Sistema

El procesador MIPS está implementado como una arquitectura de pipeline de 3 etapas coordinada por la entidad `MIPS` de nivel superior. El sistema sigue una arquitectura Harvard con rutas separadas para memoria de instrucciones y datos.

### Organización del Sistema de Nivel Superior

La entidad `MIPS` orquesta tres etapas de pipeline conectadas por registros de pipeline, con componentes dedicados de almacenamiento y control. [2](#0-1) 

### Flujo de Datos del Pipeline

El procesador implementa un pipeline de 3 etapas donde las instrucciones fluyen a través de registros de pipeline dedicados entre etapas:

| Etapa | Componente | Registro de Entrada | Registro de Salida | Función Principal |
|-------|------------|--------------------|--------------------|-------------------|
| 1 | `if_stage` | - | `reg_if_id` | Búsqueda de instrucciones, gestión de PC |
| 2 | `id_ex_stage` | `reg_if_id` | `reg_idex_memwb` | Decodificación, ejecución, generación de control |
| 3 | `mem_wb_stage` | `reg_idex_memwb` | - | Acceso a memoria, write-back de registros |

## Interfaces de Componentes Clave

### Enrutamiento de Señales a través de la Entidad MIPS

La entidad `MIPS` actúa como coordinador central, enrutando señales entre etapas del pipeline y recursos compartidos:

#### Interfaz de la Etapa IF
- **Entradas**: `PCSrc_i`, `Branch_Target_Addr_i`, `Jump_Target_Addr_i` desde la etapa ID-EX [3](#0-2) 
- **Salidas**: `Reg_IF_ID_out`, `Reg_IF_ID_PC_plus_4_out` al registro de pipeline [4](#0-3) 
- **Memoria**: Conexión directa al componente `Memory` de instrucciones

#### Interfaz de la Etapa ID-EX
- **Entradas**: Instrucción y PC+4 desde `reg_if_id`, datos de registro desde `register_file` [5](#0-4) 
- **Salidas**: Resultados de ALU y señales de control a `reg_idex_memwb`, control de PC a etapa IF [6](#0-5) 
- **Componentes**: Contiene instancias de `ControlUnit`, `ALUControl`, y `ALU`

#### Interfaz de la Etapa MEM-WB
- **Entradas**: Resultados de ALU y señales de control desde `reg_idex_memwb`
- **Salidas**: Datos de write-back y control a `register_file`
- **Memoria**: Conexión directa al componente `DataMemory`

### Mecanismo de Control del Pipeline

El procesador implementa controles de flush y stall para el manejo de riesgos del pipeline: [7](#0-6) 

El control de flush se genera basado en decisiones de branch/jump: [8](#0-7) 

## Jerarquía de Memoria

El sistema implementa una arquitectura Harvard con espacios de memoria separados para instrucciones y datos:

### Ruta de Memoria de Instrucciones
- **Componente**: `Memory` con carga configurable de archivos ELF [9](#0-8) 
- **Interfaz**: Dirección desde PC, salida de instrucción de 32 bits
- **Configuración**: Capacidad de 1KB (256 x palabras de 32 bits)

### Ruta de Memoria de Datos
- **Componente**: `DataMemory` con almacenamiento direccionable por bytes
- **Interfaz**: Dirección desde resultado de ALU, datos desde archivo de registros
- **Control**: Señales `MemRead` y `MemWrite` desde unidad de control

### Archivo de Registros
- **Componente**: `register_file` con capacidad de lectura de puerto dual [10](#0-9) 
- **Configuración**: 32 registros x ancho de 32 bits
- **Interfaz**: Direcciones de lectura desde etapa ID-EX, puerto de escritura desde etapa MEM-WB

## Generación de Señales de Control

Las señales de control se generan en la etapa ID-EX a través de una jerarquía de dos niveles:

1. **Unidad de Control Principal**: Genera señales de control de alto nivel desde el opcode de la instrucción
2. **Unidad de Control de ALU**: Genera códigos específicos de operación de ALU desde ALUOp y campo de función

Las señales de control luego se almacenan en buffer a través del registro de pipeline `reg_idex_memwb` para sincronizar con las operaciones de la etapa MEM-WB.

## Notas

Esta implementación representa un procesador MIPS clásico de 3 etapas con arquitectura Harvard. El diseño incluye mecanismos de control de pipeline para manejar riesgos, y utiliza registros de pipeline dedicados para mantener la sincronización entre etapas. La entidad `MIPS` de nivel superior actúa como el coordinador central que conecta todas las etapas y componentes de memoria.

Wiki pages you might want to explore:
- [MIPS Processor Overview (benjamalegni/tp3)](/wiki/benjamalegni/tp3#1)
