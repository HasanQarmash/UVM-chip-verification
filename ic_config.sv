// Configuration Class for Interrupt Controller Verification
// This class contains configuration parameters for the testbench

class ic_config extends uvm_object;
    `uvm_object_utils(ic_config)
    
    // Agent configuration
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    // Test configuration parameters
    int unsigned num_transactions = 100;
    int unsigned timeout_cycles = 1000;
    
    // DUT configuration
    bit enable_coverage = 1;
    bit enable_scoreboard = 1;
    
    // Clock and reset configuration
    time clock_period = 10ns;
    int unsigned reset_cycles = 10;
    
    // Interrupt configuration
    bit [7:0] default_mask = 8'hFF;  // Enable all interrupts by default
    
    // Debug and verbosity
    int verbosity_level = UVM_MEDIUM;
    bit enable_transaction_recording = 1;
    
    // Constructor
    function new(string name = "ic_config");
        super.new(name);
    endfunction
    
    // Convert to string for printing
    virtual function string convert2string();
        string s;
        s = $sformatf("is_active=%s, num_trans=%0d, timeout=%0d, clk_period=%0t, reset_cycles=%0d",
                     is_active.name(), num_transactions, timeout_cycles, clock_period, reset_cycles);
        return s;
    endfunction
    
endclass
