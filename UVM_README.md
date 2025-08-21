# UVM Interrupt Controller Project

This project contains a complete UVM (Universal Verification Methodology) testbench for an 8-input priority interrupt controller.

## Files Overview

### Design Files

- **uvm_design.sv** - Contains all design modules:
  - `ic_interrupt_controller` - Main interrupt controller with priority encoding
  - `ic_processor` - Simple processor model with state machine
  - `interrupt_controller_dut` - Top-level DUT wrapper

### Testbench Files

- **uvm_testbench.sv** - Complete UVM testbench including:
  - Transaction class with randomization
  - Multiple sequence types (single IRQ, priority, masking, random)
  - Driver, Monitor, Scoreboard components
  - Agent and Environment classes
  - Multiple test classes
  - Interface with clocking blocks
  - Top-level testbench module

### Build Files

- **uvm_makefile** - Makefile supporting multiple EDA tools

## Design Features

### Interrupt Controller

- 8 interrupt inputs (IRQ0-IRQ7) with IRQ0 having highest priority
- Mask register for enabling/disabling individual interrupts
- Pending register with atomic set/clear operations
- Priority encoder with proper precedence handling
- Global interrupt output and interrupt ID output

### Processor Model

- Simple 3-state machine: IDLE → PROCESSING → ACKNOWLEDGE
- Configurable processing delay
- Automatic acknowledgment generation

## UVM Testbench Features

### Test Sequences

1. **Single IRQ Test** - Tests each interrupt individually
2. **Priority Test** - Verifies priority encoding (IRQ0 > IRQ1 > ... > IRQ7)
3. **Mask Test** - Validates interrupt masking functionality
4. **Random Test** - Stress testing with random combinations
5. **Comprehensive Test** - Runs all test types in sequence

### UVM Components

- **Transaction**: Randomizable stimulus with constraints
- **Sequences**: Multiple pre-defined test scenarios
- **Driver**: Applies stimulus to DUT interface
- **Monitor**: Observes DUT behavior and outputs
- **Scoreboard**: Checks expected vs actual behavior
- **Agent**: Contains driver, monitor, and sequencer
- **Environment**: Top-level verification environment
- **Tests**: Different test scenarios and configurations

## How to Use

### Compilation and Simulation

#### Using Questa (Default)

```bash
make                              # Compile and run comprehensive test
make test_single                  # Run single interrupt test
make gui                          # Open with GUI
```

#### Using VCS

```bash
make SIM=vcs                      # Compile and run with VCS
make SIM=vcs TEST=ic_priority_test # Run priority test with VCS
```

#### Using Xcelium

```bash
make SIM=xcelium                  # Compile and run with Xcelium
make SIM=xcelium test_mask        # Run mask test with Xcelium
```

### Available Tests

- `ic_single_irq_test` - Individual interrupt testing
- `ic_priority_test` - Priority verification
- `ic_mask_test` - Masking functionality
- `ic_comprehensive_test` - All tests combined (default)

### Run All Tests

```bash
make test_all                     # Run all individual tests
```

## EDA Tool Compatibility

This testbench is compatible with:

- **Mentor Questa/ModelSim** (default)
- **Synopsys VCS**
- **Cadence Xcelium**

## Expected Results

The testbench validates:

1. ✅ Correct priority encoding (IRQ0 highest, IRQ7 lowest)
2. ✅ Proper interrupt masking behavior
3. ✅ Atomic pending register operations
4. ✅ Acknowledgment handling
5. ✅ Edge cases and corner scenarios

## Quick Start for EDA Upload

### For Two-File Setup:

1. Upload **uvm_design.sv** (design file)
2. Upload **uvm_testbench.sv** (testbench file)
3. Set top module to `uvm_testbench`
4. Run simulation

### Command Line Examples:

```bash
# Questa
vlog +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv uvm_design.sv uvm_testbench.sv
vsim work.uvm_testbench +UVM_TESTNAME=ic_comprehensive_test

# VCS
vcs -sverilog -ntb_opts uvm-1.2 uvm_design.sv uvm_testbench.sv
./simv +UVM_TESTNAME=ic_comprehensive_test

# Xcelium
xrun -sv -uvm uvm_design.sv uvm_testbench.sv +UVM_TESTNAME=ic_comprehensive_test
```

## Test Output

Successful run will show:

- Individual test results with PASS/FAIL status
- Scoreboard summary with total transactions
- Final result: "**_ ALL TESTS PASSED _**"
- Waveform file: `uvm_waves.vcd`

## Troubleshooting

1. **UVM Library Issues**: Ensure UVM_HOME points to correct UVM installation
2. **Compilation Errors**: Check SystemVerilog-2012 support in your simulator
3. **Missing Interface**: Verify interface configuration in testbench setup
