// Agent Class for Interrupt Controller
// This class contains the driver, monitor, and sequencer
// for generating and observing interrupt controller transactions

class ic_agent_sv extends uvm_agent;
    `uvm_component_utils(ic_agent_sv)
    
    // Agent components
    ic_driver       driver;
    ic_monitor      monitor;
    ic_sequencer    sequencer;
    
    // Configuration
    ic_config       cfg;
    
    // Constructor
    function new(string name = "ic_agent_sv", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(ic_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("AGENT", "Configuration object not found!")
        end
        
        // Create monitor (always needed)
        monitor = ic_monitor::type_id::create("monitor", this);
        
        // Create driver and sequencer only if agent is active
        if (cfg.is_active == UVM_ACTIVE) begin
            driver = ic_driver::type_id::create("driver", this);
            sequencer = ic_sequencer::type_id::create("sequencer", this);
        end
        
        // Set configuration for components
        uvm_config_db#(ic_config)::set(this, "*", "cfg", cfg);
    endfunction
    
    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect driver and sequencer if agent is active
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
    // End of elaboration phase
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("AGENT", $sformatf("Agent mode: %s", 
                  cfg.is_active == UVM_ACTIVE ? "ACTIVE" : "PASSIVE"), UVM_LOW)
    endfunction
    
endclass
