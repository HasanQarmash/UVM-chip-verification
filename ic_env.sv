// Environment Class for Interrupt Controller Verification
// This class sets up the verification environment including
// agents, drivers, monitors, and scoreboards

class ic_env extends uvm_env;
    `uvm_component_utils(ic_env)
    
    // Environment components
    ic_agent_sv     agent;
    ic_scoreboard   scoreboard;
    ic_coverage     coverage;
    
    // Configuration object
    ic_config       cfg;
    
    // Constructor
    function new(string name = "ic_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration from test
        if (!uvm_config_db#(ic_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("ENV", "Configuration object not found!")
        end
        
        // Create agent
        agent = ic_agent_sv::type_id::create("agent", this);
        
        // Create scoreboard
        scoreboard = ic_scoreboard::type_id::create("scoreboard", this);
        
        // Create coverage collector
        coverage = ic_coverage::type_id::create("coverage", this);
        
        // Set configuration for agent
        uvm_config_db#(ic_config)::set(this, "agent", "cfg", cfg);
    endfunction
    
    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agent monitor to scoreboard
        agent.monitor.analysis_port.connect(scoreboard.analysis_export);
        
        // Connect agent monitor to coverage collector
        agent.monitor.analysis_port.connect(coverage.analysis_export);
    endfunction
    
    // End of elaboration phase
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("ENV", "Environment build completed", UVM_LOW)
    endfunction
    
endclass
