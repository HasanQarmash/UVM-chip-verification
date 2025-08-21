// Driver Class for Interrupt Controller
// This class drives stimulus to the DUT interface

class ic_driver extends uvm_driver #(ic_sequence_item);
    `uvm_component_utils(ic_driver)
    
    // Virtual interface handle
    virtual ic_interface vif;
    
    // Configuration
    ic_config cfg;
    
    // Constructor
    function new(string name = "ic_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(ic_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("DRIVER", "Configuration object not found!")
        end
        
        // Get virtual interface
        if (!uvm_config_db#(virtual ic_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRIVER", "Virtual interface not found!")
        end
    endfunction
    
    // Run phase
    virtual task run_phase(uvm_phase phase);
        ic_sequence_item req;
        
        // Initialize interface
        initialize_interface();
        
        forever begin
            // Get next item from sequencer
            seq_item_port.get_next_item(req);
            
            // Drive the item
            drive_item(req);
            
            // Indicate item is done
            seq_item_port.item_done();
        end
    endtask
    
    // Initialize interface signals
    virtual task initialize_interface();
        vif.irq_requests <= 8'h00;
        vif.mask_reg     <= 8'hFF;  // Enable all interrupts by default
        wait(vif.rstn);  // Wait for reset deassertion
        @(posedge vif.clk);
    endtask
    
    // Drive sequence item to interface
    virtual task drive_item(ic_sequence_item req);
        `uvm_info("DRIVER", $sformatf("Driving item: %s", req.convert2string()), UVM_HIGH)
        
        // Drive interrupt requests
        @(posedge vif.clk);
        vif.irq_requests <= req.irq_requests;
        vif.mask_reg     <= req.mask_reg;
        
        // Hold the values for the specified duration
        repeat(req.duration) @(posedge vif.clk);
        
        // Clear interrupt requests if specified
        if (req.clear_after_duration) begin
            vif.irq_requests <= 8'h00;
        end
    endtask
    
endclass
