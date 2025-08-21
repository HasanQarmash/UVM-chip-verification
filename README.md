# Interrupt Controller Project

This project implements a priority-based interrupt controller using SystemVerilog and UVM for verification.

## Project Overview

The interrupt controller receives eight external interrupt requests (IRQ0-IRQ7) from different peripherals and generates an interrupt request (IRQ) to the processor. The controller implements priority-based interrupt handling where IRQ0 has the highest priority and IRQ7 has the lowest priority.

## Features

- **8 External Interrupt Inputs**: IRQ0 to IRQ7 with configurable priority
- **Priority Encoding**: IRQ0 (highest) to IRQ7 (lowest) priority
- **Mask Register**: Software-configurable interrupt masking
- **Pending Register**: Tracks pending interrupt requests
- **Processor Interface**: IRQ output and acknowledgment handling

## File Structure

### RTL Design Files

- `ic_interrupt_controller.sv` - Main interrupt controller module
- `ic_processor.sv` - Simple processor model for testing
- `design.sv` - Top-level design integration
- `ic_interface.sv` - SystemVerilog interface definition
- `ic_ref_model.sv` - Golden reference model

### Verification Files

- `testbench.sv` - Top-level testbench
- `ic_env.sv` - UVM environment
- `ic_agent.sv` - UVM agent
- `ic_driver.sv` - UVM driver
- `ic_monitor.sv` - UVM monitor
- `ic_scoreboard.sv` - UVM scoreboard
- `ic_coverage.sv` - Functional coverage
- `ic_sequence.sv` - Test sequences
- `ic_seq_item.sv` - Sequence item definition
- `ic_config.sv` - Configuration class
- `ic_interrupt_test.sv` - Test classes

### Build Files

- `Makefile` - Build and simulation targets
- `README.md` - This file

## Getting Started

### Prerequisites

- QuestaSim/ModelSim simulator
- UVM library (typically included with simulator)
- SystemVerilog support

### Compilation and Simulation

1. **Compile the design:**

   ```bash
   make compile
   ```

2. **Run basic test:**

   ```bash
   make run
   ```

3. **Run specific tests:**

   ```bash
   make run_priority     # Priority encoding test
   make run_masking      # Interrupt masking test
   make run_comprehensive # All tests combined
   ```

4. **Run all tests:**

   ```bash
   make run_all
   ```

5. **GUI simulation:**
   ```bash
   make gui
   ```

### Test Scenarios

1. **Basic Interrupt Test** (`ic_interrupt_test`)

   - Random interrupt generation
   - Basic functionality verification

2. **Priority Test** (`ic_priority_test`)

   - Individual interrupt testing
   - Priority encoding verification
   - Multiple simultaneous interrupts

3. **Masking Test** (`ic_masking_test`)

   - Mask register functionality
   - Selective interrupt enabling/disabling

4. **Comprehensive Test** (`ic_comprehensive_test`)
   - Combination of all test scenarios
   - Extended verification coverage

## Design Specifications

### Input Ports

- `clk` - Clock signal
- `rstn` - Active low reset
- `irq_in[7:0]` - External interrupt requests
- `ack` - Acknowledgment from processor
- `mask_reg[7:0]` - Interrupt mask register

### Output Ports

- `irq_out` - Global interrupt output
- `irq_id[2:0]` - Highest priority interrupt ID

### Internal Registers

- **Pending Register**: 8-bit register tracking pending interrupts
- **Mask Register**: 8-bit register for enabling/disabling interrupts

### Priority Scheme

- IRQ0: Highest priority (000)
- IRQ1: Priority level 1 (001)
- IRQ2: Priority level 2 (010)
- ...
- IRQ7: Lowest priority (111)

## Verification Strategy

### Coverage Goals

- All interrupt lines tested individually
- All priority combinations covered
- All masking scenarios verified
- Acknowledgment and clearing mechanisms tested

### Assertion-Based Verification

- Priority encoding correctness
- Pending register management
- Mask register compliance
- Output signal validity

## EDA Tool Support

This project is designed to be compatible with major EDA tools:

- **Synopsys VCS**
- **Cadence Xcelium**
- **Mentor QuestaSim/ModelSim**
- **Aldec Riviera-PRO**

For tool-specific compilation, modify the Makefile accordingly.

## Usage in EDA Environment

1. Upload all `.sv` files to your EDA tool workspace
2. Set the top-level module as `testbench`
3. Configure UVM library paths if required
4. Run compilation and simulation

## Project Deliverables

1. ✅ RTL Design SystemVerilog Source Code
2. ✅ UVM TestBench Source Code
3. ✅ Golden Reference Model

## Future Enhancements

- Add edge/level triggered interrupt support
- Implement interrupt vector table
- Add nested interrupt capability
- Support for interrupt priorities beyond 8 levels

## Contact

For questions or issues, please refer to the project documentation or contact the development team.
