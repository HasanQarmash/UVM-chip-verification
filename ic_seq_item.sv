// Sequence Item Class for Interrupt Controller
// This class defines the transaction structure for interrupt controller verification

class ic_sequence_item extends uvm_sequence_item;
    
    // Input fields
    rand logic [7:0] irq_requests;     // Interrupt request signals
    rand logic [7:0] mask_reg;         // Mask register
    rand int         duration;         // Duration to hold the stimulus
    rand bit         clear_after_duration; // Whether to clear interrupts after duration
    
    // Output fields (captured by monitor)
    logic        irq_out;              // Global interrupt output
    logic [2:0]  irq_id;               // Interrupt ID
    logic        ack;                  // Acknowledge signal
    logic [7:0]  pending_reg;          // Pending register state
    
    // Timing information
    time         timestamp;            // Transaction timestamp
    
    // Constraints
    constraint c_duration {
        duration inside {[1:10]};
    }
    
    constraint c_irq_requests {
        // Generate various interrupt patterns
        irq_requests dist {
            8'h00      := 20,  // No interrupts
            8'h01      := 15,  // Single interrupt (highest priority)
            8'h80      := 15,  // Single interrupt (lowest priority)
            [8'h01:8'h7F] := 30,  // Multiple interrupts
            8'hFF      := 20   // All interrupts
        };
    }
    
    constraint c_mask_reg {
        // Most of the time, enable all interrupts
        mask_reg dist {
            8'hFF      := 70,  // All enabled
            8'h00      := 10,  // All disabled
            [8'h01:8'hFE] := 20   // Partial masking
        };
    }
    
    constraint c_clear_after {
        clear_after_duration dist {
            1'b1 := 70,  // Usually clear after duration
            1'b0 := 30   // Sometimes keep active
        };
    }
    
    // UVM macros
    `uvm_object_utils_begin(ic_sequence_item)
        `uvm_field_int(irq_requests, UVM_ALL_ON)
        `uvm_field_int(mask_reg, UVM_ALL_ON)
        `uvm_field_int(duration, UVM_ALL_ON)
        `uvm_field_int(clear_after_duration, UVM_ALL_ON)
        `uvm_field_int(irq_out, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(irq_id, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(ack, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(pending_reg, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_NOCOMPARE | UVM_TIME)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "ic_sequence_item");
        super.new(name);
    endfunction
    
    // Convert to string for printing
    virtual function string convert2string();
        string s;
        s = $sformatf("IRQ_REQ=0x%02x MASK=0x%02x DUR=%0d CLEAR=%b | IRQ_OUT=%b IRQ_ID=%0d ACK=%b PEND=0x%02x @%0t",
                     irq_requests, mask_reg, duration, clear_after_duration,
                     irq_out, irq_id, ack, pending_reg, timestamp);
        return s;
    endfunction
    
    // Additional constraint functions
    function void post_randomize();
        // Ensure duration is reasonable
        if (duration < 1) duration = 1;
        if (duration > 20) duration = 20;
    endfunction
    
endclass
