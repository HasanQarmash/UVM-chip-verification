# Interrupt Controller Project Makefile
# This makefile provides targets for compiling and running the interrupt controller verification

# Tool configuration
SIMULATOR ?= questa

# Source files
RTL_FILES = design.sv \
           ic_interrupt_controller.sv \
           ic_processor.sv \
           ic_interface.sv \
           ic_ref_model.sv

TB_FILES = testbench.sv
SIMPLE_TB = simple_testbench.sv
COMPLETE_TB = complete_testbench.sv

# Compilation flags
VLOG_OPTS = +incdir+.

# Runtime options
VSIM_OPTS = -coverage \
           -sv_seed=random

# Default target
all: compile run_complete

# Compile target
compile:
	@echo "Compiling RTL and Testbench files..."
	vlib work
	vlog $(VLOG_OPTS) $(RTL_FILES) $(TB_FILES) $(SIMPLE_TB) $(COMPLETE_TB)

# Run complete test (all modules included)
run_complete:
	@echo "Running complete interrupt controller test..."
	vsim -c complete_testbench $(VSIM_OPTS) -do "run -all; quit"

# Run simple test (no UVM)
run_simple:
	@echo "Running simple interrupt controller test..."
	vsim -c simple_testbench $(VSIM_OPTS) -do "run -all; quit"

# Run advanced test (with testbench)
run:
	@echo "Running interrupt controller test..."
	vsim -c testbench $(VSIM_OPTS) -do "run -all; quit"

# Run priority test
run_priority:
	@echo "Running priority test..."
	vsim -c testbench $(VSIM_OPTS) -do "run -all; quit"

# Run masking test  
run_masking:
	@echo "Running masking test..."
	vsim -c testbench $(VSIM_OPTS) -do "run -all; quit"

# Run comprehensive test
run_comprehensive:
	@echo "Running comprehensive test..."
	vsim -c testbench $(VSIM_OPTS) -do "run -all; quit"

# Run all tests
run_all: run_simple run

# GUI simulation (complete)
gui_complete:
	@echo "Running GUI simulation (complete)..."
	vsim complete_testbench $(VSIM_OPTS) &

# GUI simulation (simple)
gui_simple:
	@echo "Running GUI simulation (simple)..."
	vsim simple_testbench $(VSIM_OPTS) &

# GUI simulation (advanced)
gui:
	@echo "Running GUI simulation (advanced)..."
	vsim testbench $(VSIM_OPTS) &

# Coverage report
coverage:
	@echo "Generating coverage report..."
	vcover report -html work

# Clean workspace
clean:
	@echo "Cleaning workspace..."
	rm -rf work
	rm -rf transcript
	rm -rf *.vcd
	rm -rf *.log
	rm -rf *.wlf
	rm -rf covhtmlreport

# Lint check
lint:
	@echo "Running lint check..."
	vlog -lint $(RTL_FILES)

# Help target
help:
	@echo "Available targets:"
	@echo "  all           - Compile and run complete test"
	@echo "  compile       - Compile RTL and testbench"
	@echo "  run_complete  - Run complete test (all modules included)"
	@echo "  run_simple    - Run simple test (no dependencies)"
	@echo "  run           - Run advanced test"
	@echo "  run_priority  - Run priority test"
	@echo "  run_masking   - Run masking test"
	@echo "  run_comprehensive - Run comprehensive test"
	@echo "  run_all       - Run all tests"
	@echo "  gui_complete  - Run complete GUI simulation"
	@echo "  gui_simple    - Run simple GUI simulation"
	@echo "  gui           - Run advanced GUI simulation"
	@echo "  coverage      - Generate coverage report"
	@echo "  lint          - Run lint check"
	@echo "  clean         - Clean workspace"
	@echo "  help          - Show this help"

.PHONY: all compile run_complete run_simple run run_priority run_masking run_comprehensive run_all gui_complete gui_simple gui coverage clean lint help
