// Scoreboard Class for Interrupt Controller
// This class checks the correctness of DUT behavior

class ic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ic_scoreboard)
    
    // Analysis export for receiving transactions from monitor
    uvm_analysis_export #(ic_sequence_item) analysis_export;
    
    // Internal TLM FIFO for storing transactions
    uvm_tlm_analysis_fifo #(ic_sequence_item) item_fifo;
    
    // Statistics
    int transactions_checked;
    int transactions_passed;
    int transactions_failed;
    
    // Expected state tracking
    logic [7:0] expected_pending;
    logic       expected_irq_out;
    logic [2:0] expected_irq_id;
    
    // Constructor
    function new(string name = "ic_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        item_fifo = new("item_fifo", this);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        analysis_export.connect(item_fifo.analysis_export);
    endfunction
    
    // Run phase
    virtual task run_phase(uvm_phase phase);
        ic_sequence_item item;
        
        forever begin
            // Get transaction from FIFO
            item_fifo.get(item);
            
            // Check the transaction
            check_transaction(item);
        end
    endtask
    
    // Check transaction correctness
    virtual function void check_transaction(ic_sequence_item item);
        bit check_passed = 1;
        
        transactions_checked++;
        
        // Predict expected behavior
        predict_expected_outputs(item);
        
        // Check IRQ output
        if (item.irq_out !== expected_irq_out) begin
            `uvm_error("SCOREBOARD", $sformatf("IRQ_OUT mismatch! Expected: %b, Actual: %b", 
                      expected_irq_out, item.irq_out))
            check_passed = 0;
        end
        
        // Check IRQ ID (only when interrupt is active)
        if (item.irq_out && (item.irq_id !== expected_irq_id)) begin
            `uvm_error("SCOREBOARD", $sformatf("IRQ_ID mismatch! Expected: %0d, Actual: %0d", 
                      expected_irq_id, item.irq_id))
            check_passed = 0;
        end
        
        // Check priority encoding
        if (!check_priority_encoding(item)) begin
            check_passed = 0;
        end
        
        // Update statistics
        if (check_passed) begin
            transactions_passed++;
            `uvm_info("SCOREBOARD", $sformatf("Transaction PASSED: %s", item.convert2string()), UVM_HIGH)
        end else begin
            transactions_failed++;
            `uvm_error("SCOREBOARD", $sformatf("Transaction FAILED: %s", item.convert2string()))
        end
    endfunction
    
    // Predict expected outputs based on inputs
    virtual function void predict_expected_outputs(ic_sequence_item item);
        logic [7:0] masked_requests;
        
        // Apply mask to interrupt requests
        masked_requests = item.irq_requests & item.mask_reg;
        
        // Determine if any interrupt is pending
        expected_irq_out = |masked_requests;
        
        // Determine highest priority interrupt ID
        expected_irq_id = 3'b000;
        for (int i = 0; i < 8; i++) begin
            if (masked_requests[i]) begin
                expected_irq_id = i[2:0];
                break;  // Found highest priority (lowest index)
            end
        end
    endfunction
    
    // Check priority encoding correctness
    virtual function bit check_priority_encoding(ic_sequence_item item);
        logic [7:0] masked_requests;
        bit encoding_correct = 1;
        
        masked_requests = item.irq_requests & item.mask_reg;
        
        // If interrupt is active, check that higher priority interrupts are not pending
        if (item.irq_out) begin
            for (int i = 0; i < item.irq_id; i++) begin
                if (masked_requests[i]) begin
                    `uvm_error("SCOREBOARD", $sformatf("Priority encoding error! Higher priority IRQ%0d is pending but IRQ%0d is selected", i, item.irq_id))
                    encoding_correct = 0;
                end
            end
        end
        
        return encoding_correct;
    endfunction
    
    // Report phase
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", $sformatf("=== SCOREBOARD REPORT ==="), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Transactions: %0d", transactions_checked), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Passed: %0d", transactions_passed), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Failed: %0d", transactions_failed), UVM_LOW)
        
        if (transactions_failed == 0) begin
            `uvm_info("SCOREBOARD", "TEST PASSED!", UVM_LOW)
        end else begin
            `uvm_error("SCOREBOARD", "TEST FAILED!")
        end
    endfunction
    
endclass
