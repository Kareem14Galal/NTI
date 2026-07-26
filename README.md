# NTI - Digital Design using FPGA

## Overview
This repository contains the practical coursework and the capstone graduation project completed during the 90-hour NTI training program. The project focuses on digital design using Verilog HDL, progressing from basic logic gates to a complex System-on-Chip (SoC) and a full graduation project.

##  Graduation Project: FPGA-Based Multi-Antenna Controller for Microwave Head Imaging
The capstone project is a custom digital controller intended for synthesis on an FPGA. It serves as the digital nervous system for a diagnostic sensing helmet equipped with a 16-antenna array, used for non-invasive microwave head imaging.

###  System Architecture
The FPGA acts as the central 'Microwave Controller', orchestrating precise timing and sequential switching without the software interrupt latency of standard microcontrollers:
* **UART RX & TX**: The communication bridge with the host PC.
* **Antenna Selector**: A synchronous counter generating a 4-bit select code for the active antenna.
* **Switch Controller**: Decodes the select code into a 16-bit "One-Hot" signal for the RF Switch Matrix.
* **ADC Controller & Memory**: Triggers the external ADC, captures valid samples, and stores them in internal FPGA RAM.
* **Main FSM**: Orchestrates the sequential scanning cycle, managing settling times and data routing.

##  Digital Design Labs
The repository is structured into multiple directories showcasing various levels of digital design abstraction:
1. **Adders (`Lab_1_Q1`, `Full_Adder_B`, `Full_Adder_g`)**: Dataflow, Behavioral, and Gate-Level Structural modeling of Full Adders.
2. **Counters (`Counter_behavioral`, `Counter_gate`, `counter`, `Lab_9_counter`)**: Synchronous sequential logic, state control, and Program Counter (PC) mechanics.
3. **FSM (`Fsm`)**: Finite State Machine control logic with Moore and Mealy outputs.
4. **Datapath & Processing (`Lab_5_alu`, `Lab_7_register`)**: Parameterizable ALU and general-purpose data registers.
5. **Memory & Interfaces (`Lab_8_memory`, `Lab_3_sheft`)**: SRAM modeling and Serial-to-Parallel (SIPO) interfacing.
6. **Advanced Integration (`Lab_6_controller`, `Lab_4_Top_module`)**: CPU Instruction Decoder and SoC-level data routing combining Memory, PISO, SIPO, and ALU.
