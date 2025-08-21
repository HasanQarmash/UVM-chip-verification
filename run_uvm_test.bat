@echo off
REM UVM Test Script for Windows

echo === UVM Interrupt Controller Test ===

REM Compile with VCS (if available) or ModelSim
echo Compiling UVM testbench...

REM For VCS
vcs -sverilog -ntb_opts uvm-1.2 +incdir+%UVM_HOME%/src %UVM_HOME%/src/uvm_pkg.sv uvm_design.sv uvm_testbench.sv -o simv_uvm +define+UVM_NO_RELNOTES

if %errorlevel% equ 0 (
    echo Compilation successful!
    
    echo.
    echo === Running Simple Test ===
    simv_uvm +UVM_TESTNAME=ic_single_irq_test +UVM_VERBOSITY=UVM_MEDIUM
    
    echo.
    echo === Running Priority Test ===
    simv_uvm +UVM_TESTNAME=ic_priority_test +UVM_VERBOSITY=UVM_MEDIUM
    
    echo.
    echo === Running Comprehensive Test ===
    simv_uvm +UVM_TESTNAME=ic_comprehensive_test +UVM_VERBOSITY=UVM_MEDIUM
    
) else (
    echo Compilation failed! Trying with Questa/ModelSim...
    
    REM For Questa/ModelSim
    vlog +incdir+%UVM_HOME%/src %UVM_HOME%/src/uvm_pkg.sv uvm_design.sv uvm_testbench.sv
    
    if %errorlevel% equ 0 (
        echo Compilation with Questa successful!
        
        echo.
        echo === Running Tests ===
        vsim -c work.uvm_testbench +UVM_TESTNAME=ic_comprehensive_test +UVM_VERBOSITY=UVM_MEDIUM -do "run -all; quit"
    ) else (
        echo Both compilations failed!
        exit /b 1
    )
)

echo.
echo === Test Complete ===
echo Check the simulation output for results.
echo Look for "*** ALL TESTS PASSED ***" or failure messages.

pause
