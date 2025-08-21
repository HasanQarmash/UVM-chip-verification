// Monitor Class for Interrupt Controller
// This class observes the DUT interface and creates transactions

class ic_monitor extends uvm_monitor;
    `uvm_component_utils(ic_monitor)
    
    // Virtual interface handle
    virtual ic_interface vif;
    
    // Analysis port for broadcasting transactions
    uvm_analysis_port #(ic_sequence_item) analysis_port;
    
    // Configuration
    ic_config cfg;
    
    // Constructor
    function new(string name = "ic_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(ic_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("MONITOR", "Configuration object not found!")
        end
        
        // Get virtual interface
        if (!uvm_config_db#(virtual ic_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MONITOR", "Virtual interface not found!")
        end
    endfunction
    
    // Run phase
    virtual task run_phase(uvm_phase phase);
        ic_sequence_item item;
        
        wait(vif.rstn);  // Wait for reset deassertion
        
        forever begin
            // Create new transaction
            item = ic_sequence_item::type_id::create("item");
            
            // Collect transaction
            collect_transaction(item);
            
            // Broadcast transaction
            analysis_port.write(item);
        end
    endtask
    
    // Collect transaction from interface
    virtual task collect_transaction(ic_sequence_item item);
        // Wait for clock edge
        @(posedge vif.clk);
        
        // Capture input signals
        item.irq_requests = vif.irq_requests;
        item.mask_reg     = vif.mask_reg;
        
        // Capture output signals
        item.irq_out      = vif.irq_out;
        item.irq_id       = vif.irq_id;
        item.ack          = vif.ack;
        item.pending_reg  = vif.pending_reg;
        
        // Add timestamp
        item.timestamp = $time;
        
        `uvm_info("MONITOR", $sformatf("Collected transaction: %s", item.convert2string()), UVM_HIGH)
    endtask
    
endclass
