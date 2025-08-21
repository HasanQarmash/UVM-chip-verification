// Interrupt Test Class
// This class contains various test scenarios for the interrupt controller

class ic_interrupt_test extends uvm_test;
    `uvm_component_utils(ic_interrupt_test)
    
    // Environment handle
    ic_env env;
    
    // Configuration
    ic_config cfg;
    
    // Constructor
    function new(string name = "ic_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create configuration
        cfg = ic_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        cfg.num_transactions = 50;
        
        // Set configuration in database
        uvm_config_db#(ic_config)::set(this, "*", "cfg", cfg);
        
        // Create environment
        env = ic_env::type_id::create("env", this);
        
        `uvm_info("TEST", "Interrupt test build phase completed", UVM_LOW)
    endfunction
    
    // Run phase
    virtual task run_phase(uvm_phase phase);
        ic_random_sequence seq;
        
        phase.raise_objection(this, "Starting interrupt test");
        
        // Create and start sequence
        seq = ic_random_sequence::type_id::create("seq");
        seq.num_items = cfg.num_transactions;
        seq.start(env.agent.sequencer);
        
        // Small delay before ending
        #1000ns;
        
        phase.drop_objection(this, "Interrupt test completed");
    endtask
    
    // End of elaboration phase
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TEST", "Test topology:", UVM_LOW)
        this.print();
    endfunction
    
endclass

// Priority Test Class
class ic_priority_test extends uvm_test;
    `uvm_component_utils(ic_priority_test)
    
    ic_env env;
    ic_config cfg;
    
    function new(string name = "ic_priority_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = ic_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        
        uvm_config_db#(ic_config)::set(this, "*", "cfg", cfg);
        env = ic_env::type_id::create("env", this);
        
        `uvm_info("TEST", "Priority test build phase completed", UVM_LOW)
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_priority_test_sequence seq;
        
        phase.raise_objection(this, "Starting priority test");
        
        seq = ic_priority_test_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this, "Priority test completed");
    endtask
    
endclass

// Masking Test Class
class ic_masking_test extends uvm_test;
    `uvm_component_utils(ic_masking_test)
    
    ic_env env;
    ic_config cfg;
    
    function new(string name = "ic_masking_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = ic_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        
        uvm_config_db#(ic_config)::set(this, "*", "cfg", cfg);
        env = ic_env::type_id::create("env", this);
        
        `uvm_info("TEST", "Masking test build phase completed", UVM_LOW)
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_masking_test_sequence seq;
        
        phase.raise_objection(this, "Starting masking test");
        
        seq = ic_masking_test_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this, "Masking test completed");
    endtask
    
endclass

// Comprehensive Test Class
class ic_comprehensive_test extends uvm_test;
    `uvm_component_utils(ic_comprehensive_test)
    
    ic_env env;
    ic_config cfg;
    
    function new(string name = "ic_comprehensive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = ic_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        cfg.num_transactions = 200;
        
        uvm_config_db#(ic_config)::set(this, "*", "cfg", cfg);
        env = ic_env::type_id::create("env", this);
        
        `uvm_info("TEST", "Comprehensive test build phase completed", UVM_LOW)
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_random_sequence random_seq;
        ic_priority_test_sequence priority_seq;
        ic_masking_test_sequence masking_seq;
        
        phase.raise_objection(this, "Starting comprehensive test");
        
        `uvm_info("TEST", "Running priority test sequence...", UVM_LOW)
        priority_seq = ic_priority_test_sequence::type_id::create("priority_seq");
        priority_seq.start(env.agent.sequencer);
        
        #500ns;
        
        `uvm_info("TEST", "Running masking test sequence...", UVM_LOW)
        masking_seq = ic_masking_test_sequence::type_id::create("masking_seq");
        masking_seq.start(env.agent.sequencer);
        
        #500ns;
        
        `uvm_info("TEST", "Running random test sequence...", UVM_LOW)
        random_seq = ic_random_sequence::type_id::create("random_seq");
        random_seq.num_items = 100;
        random_seq.start(env.agent.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this, "Comprehensive test completed");
    endtask
    
endclass
