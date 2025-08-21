#!/bin/bash
# Simple UVM Test Script

echo "=== UVM Interrupt Controller Test ==="

# Compile with VCS
echo "Compiling UVM testbench..."
vcs -sverilog -ntb_opts uvm-1.2 \
    +incdir+$UVM_HOME/src \
    $UVM_HOME/src/uvm_pkg.sv \
    uvm_design.sv uvm_testbench.sv \
    -o simv_uvm \
    +define+UVM_NO_RELNOTES

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    
    # Run simple test first
    echo ""
    echo "=== Running Simple Test ==="
    ./simv_uvm +UVM_TESTNAME=ic_single_irq_test +UVM_VERBOSITY=UVM_MEDIUM
    
    echo ""
    echo "=== Running Priority Test ==="
    ./simv_uvm +UVM_TESTNAME=ic_priority_test +UVM_VERBOSITY=UVM_MEDIUM
    
    echo ""
    echo "=== Running Mask Test ==="
    ./simv_uvm +UVM_TESTNAME=ic_mask_test +UVM_VERBOSITY=UVM_MEDIUM
    
    echo ""
    echo "=== Running Comprehensive Test ==="
    ./simv_uvm +UVM_TESTNAME=ic_comprehensive_test +UVM_VERBOSITY=UVM_MEDIUM
    
else
    echo "Compilation failed!"
    exit 1
fi

echo ""
echo "=== Test Summary ==="
echo "Check the simulation output for results."
echo "Look for '*** ALL TESTS PASSED ***' or failure messages."
