// Sequencer Class for Interrupt Controller
// This class manages the flow of sequence items to the driver

class ic_sequencer extends uvm_sequencer #(ic_sequence_item);
    `uvm_component_utils(ic_sequencer)
    
    // Constructor
    function new(string name = "ic_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SEQUENCER", "Sequencer build phase completed", UVM_HIGH)
    endfunction
    
endclass

// Base Sequence Class
class ic_base_sequence extends uvm_sequence #(ic_sequence_item);
    `uvm_object_utils(ic_base_sequence)
    
    // Constructor
    function new(string name = "ic_base_sequence");
        super.new(name);
    endfunction
    
    // Pre-body task
    virtual task pre_body();
        if (starting_phase != null) begin
            starting_phase.raise_objection(this, "Starting sequence");
        end
    endtask
    
    // Post-body task
    virtual task post_body();
        if (starting_phase != null) begin
            starting_phase.drop_objection(this, "Ending sequence");
        end
    endtask
    
endclass

// Random Sequence
class ic_random_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_random_sequence)
    
    rand int num_items;
    
    constraint c_num_items {
        num_items inside {[10:50]};
    }
    
    function new(string name = "ic_random_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_sequence_item item;
        
        `uvm_info("SEQUENCE", $sformatf("Starting random sequence with %0d items", num_items), UVM_LOW)
        
        for (int i = 0; i < num_items; i++) begin
            item = ic_sequence_item::type_id::create("item");
            start_item(item);
            if (!item.randomize()) begin
                `uvm_fatal("SEQUENCE", "Failed to randomize item")
            end
            finish_item(item);
        end
        
        `uvm_info("SEQUENCE", "Random sequence completed", UVM_LOW)
    endtask
    
endclass

// Priority Test Sequence
class ic_priority_test_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_priority_test_sequence)
    
    function new(string name = "ic_priority_test_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_sequence_item item;
        
        `uvm_info("SEQUENCE", "Starting priority test sequence", UVM_LOW)
        
        // Test each interrupt individually (priority test)
        for (int i = 0; i < 8; i++) begin
            item = ic_sequence_item::type_id::create("item");
            start_item(item);
            item.irq_requests = (1 << i);
            item.mask_reg = 8'hFF;
            item.duration = 5;
            item.clear_after_duration = 1;
            finish_item(item);
            
            // Wait a bit between interrupts
            item = ic_sequence_item::type_id::create("item");
            start_item(item);
            item.irq_requests = 8'h00;
            item.mask_reg = 8'hFF;
            item.duration = 2;
            item.clear_after_duration = 0;
            finish_item(item);
        end
        
        // Test multiple interrupts simultaneously
        item = ic_sequence_item::type_id::create("item");
        start_item(item);
        item.irq_requests = 8'hFF;  // All interrupts
        item.mask_reg = 8'hFF;
        item.duration = 10;
        item.clear_after_duration = 1;
        finish_item(item);
        
        `uvm_info("SEQUENCE", "Priority test sequence completed", UVM_LOW)
    endtask
    
endclass

// Masking Test Sequence
class ic_masking_test_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_masking_test_sequence)
    
    function new(string name = "ic_masking_test_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_sequence_item item;
        
        `uvm_info("SEQUENCE", "Starting masking test sequence", UVM_LOW)
        
        // Test with all interrupts masked
        item = ic_sequence_item::type_id::create("item");
        start_item(item);
        item.irq_requests = 8'hFF;
        item.mask_reg = 8'h00;  // All masked
        item.duration = 5;
        item.clear_after_duration = 1;
        finish_item(item);
        
        // Test with selective masking
        for (int mask = 1; mask < 8'hFF; mask = mask << 1) begin
            item = ic_sequence_item::type_id::create("item");
            start_item(item);
            item.irq_requests = 8'hFF;
            item.mask_reg = mask[7:0];
            item.duration = 3;
            item.clear_after_duration = 1;
            finish_item(item);
        end
        
        `uvm_info("SEQUENCE", "Masking test sequence completed", UVM_LOW)
    endtask
    
endclass
