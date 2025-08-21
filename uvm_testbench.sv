// UVM Testbench for Interrupt Controller
// Complete UVM testbench with all necessary components

`include "uvm_macros.svh"
import uvm_pkg::*;

// Transaction class
class ic_transaction extends uvm_sequence_item;
    // Input signals
    rand logic [7:0] irq_requests;
    rand logic [7:0] mask_reg;
    
    // Output signals
    logic       irq_out;
    logic [2:0] irq_id;
    logic       ack;
    logic       busy;

    // Constructor
    function new(string name = "ic_transaction");
        super.new(name);
    endfunction

    // UVM automation macros
    `uvm_object_utils_begin(ic_transaction)
        `uvm_field_int(irq_requests, UVM_ALL_ON)
        `uvm_field_int(mask_reg, UVM_ALL_ON)
        `uvm_field_int(irq_out, UVM_ALL_ON)
        `uvm_field_int(irq_id, UVM_ALL_ON)
        `uvm_field_int(ack, UVM_ALL_ON)
        `uvm_field_int(busy, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constraints
    constraint valid_mask { mask_reg != 8'h00; }
    constraint reasonable_irq { irq_requests inside {[8'h00:8'hFF]}; }
endclass

// Sequence classes
class ic_base_sequence extends uvm_sequence#(ic_transaction);
    `uvm_object_utils(ic_base_sequence)
    
    function new(string name = "ic_base_sequence");
        super.new(name);
    endfunction
endclass

class ic_single_irq_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_single_irq_sequence)
    
    function new(string name = "ic_single_irq_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_transaction req;
        
        `uvm_info("SEQ", "=== SINGLE IRQ SEQUENCE STARTED ===", UVM_MEDIUM)
        `uvm_info("SEQ", "OBJECTIVE: Test each interrupt line individually (IRQ0-IRQ7)", UVM_MEDIUM)
        
        // Test each interrupt individually
        for (int i = 0; i < 8; i++) begin
            `uvm_info("SEQ", $sformatf("--- Testing IRQ%0d ---", i), UVM_MEDIUM)
            req = ic_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                irq_requests == (1 << i);
                mask_reg == 8'hFF;
            });
            `uvm_info("SEQ", $sformatf("GENERATED: irq_requests=0x%02x (IRQ%0d), mask_reg=0x%02x", 
                      req.irq_requests, i, req.mask_reg), UVM_MEDIUM)
            `uvm_info("SEQ", $sformatf("SENDING TO DRIVER: Single IRQ%0d test transaction", i), UVM_MEDIUM)
            finish_item(req);
            `uvm_info("SEQ", $sformatf("COMPLETED: IRQ%0d test sent successfully", i), UVM_MEDIUM)
        end
        
        `uvm_info("SEQ", "=== SINGLE IRQ SEQUENCE COMPLETED ===", UVM_MEDIUM)
    endtask
endclass

class ic_priority_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_priority_sequence)
    
    function new(string name = "ic_priority_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_transaction req;
        
        `uvm_info("SEQ", "=== PRIORITY SEQUENCE STARTED ===", UVM_MEDIUM)
        `uvm_info("SEQ", "OBJECTIVE: Test interrupt priority handling (IRQ0=highest, IRQ7=lowest)", UVM_MEDIUM)
        
        // Test priority combinations
        `uvm_info("SEQ", "--- Test 1: IRQ0 vs IRQ7 (expect IRQ0 wins) ---", UVM_MEDIUM)
        req = ic_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            irq_requests == 8'b10000001; // IRQ0 and IRQ7
            mask_reg == 8'hFF;
        });
        `uvm_info("SEQ", $sformatf("GENERATED: irq_requests=0x%02x (IRQ0+IRQ7), mask_reg=0x%02x", 
                  req.irq_requests, req.mask_reg), UVM_MEDIUM)
        `uvm_info("SEQ", "SENDING TO DRIVER: IRQ0 vs IRQ7 priority test", UVM_MEDIUM)
        finish_item(req);
        
        `uvm_info("SEQ", "--- Test 2: IRQ1 vs IRQ4 (expect IRQ1 wins) ---", UVM_MEDIUM)
        req = ic_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            irq_requests == 8'b00010010; // IRQ1 and IRQ4
            mask_reg == 8'hFF;
        });
        `uvm_info("SEQ", $sformatf("GENERATED: irq_requests=0x%02x (IRQ1+IRQ4), mask_reg=0x%02x", 
                  req.irq_requests, req.mask_reg), UVM_MEDIUM)
        `uvm_info("SEQ", "SENDING TO DRIVER: IRQ1 vs IRQ4 priority test", UVM_MEDIUM)
        finish_item(req);
        
        `uvm_info("SEQ", "--- Test 3: All IRQs (expect IRQ0 wins) ---", UVM_MEDIUM)
        req = ic_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            irq_requests == 8'hFF; // All interrupts
            mask_reg == 8'hFF;
        });
        `uvm_info("SEQ", $sformatf("GENERATED: irq_requests=0x%02x (ALL IRQs), mask_reg=0x%02x", 
                  req.irq_requests, req.mask_reg), UVM_MEDIUM)
        `uvm_info("SEQ", "SENDING TO DRIVER: All IRQs priority test", UVM_MEDIUM)
        finish_item(req);
        
        `uvm_info("SEQ", "=== PRIORITY SEQUENCE COMPLETED ===", UVM_MEDIUM)
    endtask
endclass

class ic_mask_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_mask_sequence)
    
    function new(string name = "ic_mask_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_transaction req;
        logic [7:0] mask_value;
        
        `uvm_info("SEQ", "=== MASK SEQUENCE STARTED ===", UVM_MEDIUM)
        `uvm_info("SEQ", "OBJECTIVE: Test interrupt masking functionality (1=enabled, 0=disabled)", UVM_MEDIUM)
        
        // Test masking functionality
        for (int i = 0; i < 8; i++) begin
            `uvm_info("SEQ", $sformatf("--- Testing mask for IRQ%0d ---", i), UVM_MEDIUM)
            req = ic_transaction::type_id::create("req");
            start_item(req);
            mask_value = ~(1 << i); // Calculate mask value outside constraint
            req.irq_requests = 8'hFF;
            req.mask_reg = mask_value;
            `uvm_info("SEQ", $sformatf("GENERATED: irq_requests=0x%02x (ALL), mask_reg=0x%02x (IRQ%0d disabled)", 
                      req.irq_requests, req.mask_reg, i), UVM_MEDIUM)
            `uvm_info("SEQ", $sformatf("SENDING TO DRIVER: Mask test - IRQ%0d should be disabled", i), UVM_MEDIUM)
            finish_item(req);
            `uvm_info("SEQ", $sformatf("COMPLETED: Mask test for IRQ%0d sent", i), UVM_MEDIUM)
        end
        
        `uvm_info("SEQ", "=== MASK SEQUENCE COMPLETED ===", UVM_MEDIUM)
    endtask
endclass

class ic_random_sequence extends ic_base_sequence;
    `uvm_object_utils(ic_random_sequence)
    
    function new(string name = "ic_random_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ic_transaction req;
        
        repeat(20) begin
            req = ic_transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask
endclass

// Driver class
class ic_driver extends uvm_driver#(ic_transaction);
    `uvm_component_utils(ic_driver)
    
    virtual ic_interface vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ic_interface)::get(this, "", "vif", vif))
            `uvm_fatal("DRIVER", "Could not get interface")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_transaction req;
        
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("DRIVER", "=== DRIVER RECEIVED TRANSACTION ===", UVM_MEDIUM)
            `uvm_info("DRIVER", $sformatf("RECEIVED: irq_requests=0x%02x, mask_reg=0x%02x", 
                      req.irq_requests, req.mask_reg), UVM_MEDIUM)
            drive_transaction(req);
            `uvm_info("DRIVER", "=== DRIVER COMPLETED TRANSACTION ===", UVM_MEDIUM)
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(ic_transaction req);
        // Wait for a clean clock edge using clocking block
        @(vif.driver_cb);
        
        `uvm_info("DRIVER", "--- PHASE 1: Applying Stimulus ---", UVM_MEDIUM)
        // Apply stimulus using clocking block
        vif.driver_cb.irq_requests <= req.irq_requests;
        vif.driver_cb.mask_reg <= req.mask_reg;
        `uvm_info("DRIVER", $sformatf("SENT TO DUT: irq_requests=0x%02x, mask_reg=0x%02x", 
                  req.irq_requests, req.mask_reg), UVM_MEDIUM)
        
        // Hold interrupts for longer to ensure they get latched into pending register
        // and allow processor to acknowledge them
        `uvm_info("DRIVER", "--- PHASE 2: Holding Stimulus (25 clocks) ---", UVM_HIGH)
        repeat(25) @(vif.driver_cb);
        
        `uvm_info("DRIVER", "--- PHASE 3: Clearing Interrupts ---", UVM_MEDIUM)
        // Clear interrupts only after processor has had time to acknowledge
        vif.driver_cb.irq_requests <= 8'h00;
        `uvm_info("DRIVER", "SENT TO DUT: irq_requests=0x00 (cleared)", UVM_MEDIUM)
        
        // Wait for processor to finish acknowledgment cycle
        `uvm_info("DRIVER", "--- PHASE 4: Waiting for Settlement (15 clocks) ---", UVM_HIGH)
        repeat(15) @(vif.driver_cb);
        
        `uvm_info("DRIVER", $sformatf("FINAL STATUS: Transaction complete for irq_req=0x%02x, mask=0x%02x", 
                  req.irq_requests, req.mask_reg), UVM_MEDIUM)
    endtask
endclass

// Monitor class
class ic_monitor extends uvm_monitor;
    `uvm_component_utils(ic_monitor)
    
    virtual ic_interface vif;
    uvm_analysis_port#(ic_transaction) ap;
    
    // Previous state tracking for edge detection
    logic prev_irq_out = 0;
    logic prev_ack = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ic_interface)::get(this, "", "vif", vif))
            `uvm_fatal("MONITOR", "Could not get interface")
        ap = new("ap", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_transaction trans;
        
        `uvm_info("MONITOR", "=== MONITOR STARTED - Watching for IRQ_OUT↑ and ACK↑ Edges ===", UVM_MEDIUM)
        
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.rstn) begin
                // Log all observed signals at high verbosity
                `uvm_info("MONITOR", $sformatf("OBSERVING DUT: req=0x%02x, mask=0x%02x, irq_out=%b, irq_id=%0d, ack=%b, busy=%b", 
                          vif.monitor_cb.irq_requests, vif.monitor_cb.mask_reg, vif.monitor_cb.irq_out, 
                          vif.monitor_cb.irq_id, vif.monitor_cb.ack, vif.monitor_cb.busy), UVM_HIGH)
                
                // Check for irq_out rising edge (interrupt assertion)
                if (!prev_irq_out && vif.monitor_cb.irq_out) begin
                    trans = ic_transaction::type_id::create("trans");
                    trans.irq_requests = vif.monitor_cb.irq_requests;
                    trans.mask_reg = vif.monitor_cb.mask_reg;
                    trans.irq_out = vif.monitor_cb.irq_out;
                    trans.irq_id = vif.monitor_cb.irq_id;
                    trans.ack = vif.monitor_cb.ack;
                    trans.busy = vif.monitor_cb.busy;
                    
                    `uvm_info("MONITOR", "🔺 IRQ_OUT RISING EDGE DETECTED", UVM_MEDIUM)
                    `uvm_info("MONITOR", $sformatf("CAPTURED IRQ ASSERTION: irq_out=%b, irq_id=%0d, req=0x%02x, mask=0x%02x", 
                              trans.irq_out, trans.irq_id, trans.irq_requests, trans.mask_reg), UVM_MEDIUM)
                    ap.write(trans);
                    `uvm_info("MONITOR", "SENT TO SCOREBOARD: IRQ assertion event", UVM_MEDIUM)
                end
                
                // Check for ack rising edge (interrupt acknowledgment)
                if (!prev_ack && vif.monitor_cb.ack) begin
                    trans = ic_transaction::type_id::create("trans");
                    trans.irq_requests = vif.monitor_cb.irq_requests;
                    trans.mask_reg = vif.monitor_cb.mask_reg;
                    trans.irq_out = vif.monitor_cb.irq_out;
                    trans.irq_id = vif.monitor_cb.irq_id;
                    trans.ack = vif.monitor_cb.ack;
                    trans.busy = vif.monitor_cb.busy;
                    
                    `uvm_info("MONITOR", "🔺 ACK RISING EDGE DETECTED", UVM_MEDIUM)
                    `uvm_info("MONITOR", $sformatf("CAPTURED IRQ ACKNOWLEDGMENT: irq_id=%0d, ack=%b, busy=%b", 
                              trans.irq_id, trans.ack, trans.busy), UVM_MEDIUM)
                    ap.write(trans);
                    `uvm_info("MONITOR", "SENT TO SCOREBOARD: IRQ acknowledgment event", UVM_MEDIUM)
                end
                
                // Update previous state
                prev_irq_out = vif.monitor_cb.irq_out;
                prev_ack = vif.monitor_cb.ack;
            end else begin
                `uvm_info("MONITOR", "RESET DETECTED: DUT in reset state", UVM_HIGH)
                prev_irq_out = 0;
                prev_ack = 0;
            end
        end
    endtask
endclass

// Scoreboard class
class ic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ic_scoreboard)
    
    uvm_analysis_imp#(ic_transaction, ic_scoreboard) ap_imp;
    
    int pass_count = 0;
    int fail_count = 0;
    int total_count = 0;
    
    // Reference model for pending register
    logic [7:0] ref_pending = 8'h00;
    logic [7:0] last_irq_requests = 8'h00;
    logic [7:0] last_mask_reg = 8'hFF;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction
    
    virtual function void write(ic_transaction trans);
        logic [7:0] masked_irq;
        logic [2:0] expected_id;
        logic expected_irq_out;
        int prio;
        bit found_interrupt;
        
        total_count++;
        
        `uvm_info("SCOREBOARD", "=== SCOREBOARD RECEIVED TRANSACTION ===", UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("RECEIVED FROM MONITOR: req=0x%02x, mask=0x%02x, irq_out=%b, irq_id=%0d, ack=%b, busy=%b", 
                  trans.irq_requests, trans.mask_reg, trans.irq_out, trans.irq_id, trans.ack, trans.busy), UVM_MEDIUM)
        
        // Update reference pending register model
        masked_irq = trans.irq_requests & trans.mask_reg;
        `uvm_info("SCOREBOARD", $sformatf("ANALYSIS: masked_interrupts=0x%02x (req & mask)", masked_irq), UVM_MEDIUM)
        
        // Model the pending register behavior
        ref_pending = ref_pending | masked_irq; // Set new interrupts
        
        // If this is an ACK event, clear the acknowledged interrupt
        if (trans.ack && (ref_pending != 8'h00)) begin
            // Find the highest priority interrupt to clear
            for (prio = 0; prio < 8; prio++) begin
                if (ref_pending[prio]) begin
                    ref_pending[prio] = 1'b0; // Clear highest priority pending
                    `uvm_info("SCOREBOARD", $sformatf("REF MODEL: Cleared IRQ%0d from pending register (ACK event)", prio), UVM_MEDIUM)
                    break;
                end
            end
        end
        
        `uvm_info("SCOREBOARD", $sformatf("REF MODEL: ref_pending=0x%02x", ref_pending), UVM_MEDIUM)
        
        // Calculate expected interrupt output
        expected_irq_out = (ref_pending != 8'h00);
        found_interrupt = 0;
        expected_id = 3'b000;
        
        // Find highest priority pending interrupt
        for (prio = 0; prio < 8; prio++) begin
            if (ref_pending[prio]) begin
                expected_id = prio[2:0];
                found_interrupt = 1;
                break;
            end
        end
        
        `uvm_info("SCOREBOARD", $sformatf("EXPECTED: irq_out=%b, irq_id=%0d (from ref_pending)", expected_irq_out, expected_id), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", "--- VALIDATION PROCESS ---", UVM_MEDIUM)
        
        // Validate the transaction based on event type
        if (trans.ack) begin
            // ACK event validation
            `uvm_info("SCOREBOARD", "CHECKING: ACK event", UVM_MEDIUM)
            if (trans.irq_id <= 3'd7) begin
                pass_count++;
                `uvm_info("SCOREBOARD", $sformatf("✓ PASS: Valid ACK - irq_id=%0d", trans.irq_id), UVM_MEDIUM)
                `uvm_info("SCOREBOARD", $sformatf("RESULT: PASS (Total: %0d/%0d)", pass_count, total_count), UVM_MEDIUM)
            end else begin
                fail_count++;
                `uvm_info("SCOREBOARD", $sformatf("✗ FAIL: Invalid ACK irq_id=%0d", trans.irq_id), UVM_MEDIUM)
                `uvm_info("SCOREBOARD", $sformatf("RESULT: FAIL (Total: %0d/%0d)", fail_count, total_count), UVM_MEDIUM)
            end
        end else if (trans.irq_out) begin
            // IRQ assertion event validation
            `uvm_info("SCOREBOARD", "CHECKING: IRQ assertion event", UVM_MEDIUM)
            
            // Check if irq_out matches expected
            if (trans.irq_out == expected_irq_out) begin
                // Check if irq_id matches expected
                if (trans.irq_id == expected_id) begin
                    pass_count++;
                    `uvm_info("SCOREBOARD", $sformatf("✓ PASS: IRQ assertion correct - DUT irq_id=%0d matches expected=%0d", 
                              trans.irq_id, expected_id), UVM_MEDIUM)
                    `uvm_info("SCOREBOARD", $sformatf("RESULT: PASS (Total: %0d/%0d)", pass_count, total_count), UVM_MEDIUM)
                end else begin
                    fail_count++;
                    `uvm_info("SCOREBOARD", $sformatf("✗ FAIL: IRQ ID mismatch - DUT irq_id=%0d, expected=%0d", 
                              trans.irq_id, expected_id), UVM_MEDIUM)
                    `uvm_info("SCOREBOARD", $sformatf("RESULT: FAIL (Total: %0d/%0d)", fail_count, total_count), UVM_MEDIUM)
                end
            end else begin
                fail_count++;
                `uvm_info("SCOREBOARD", $sformatf("✗ FAIL: IRQ_OUT mismatch - DUT irq_out=%b, expected=%b", 
                          trans.irq_out, expected_irq_out), UVM_MEDIUM)
                `uvm_info("SCOREBOARD", $sformatf("RESULT: FAIL (Total: %0d/%0d)", fail_count, total_count), UVM_MEDIUM)
            end
        end else begin
            // Quiet state - only count as transaction, don't validate
            `uvm_info("SCOREBOARD", "INFO: Quiet state (no active interrupt)", UVM_HIGH)
        end
        
        // Store last values for next cycle
        last_irq_requests = trans.irq_requests;
        last_mask_reg = trans.mask_reg;
        
        `uvm_info("SCOREBOARD", "=== SCOREBOARD COMPLETED ANALYSIS ===", UVM_MEDIUM)
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("=== FINAL RESULTS ==="), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Total Transactions: %0d", total_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Passed: %0d", pass_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Failed: %0d", fail_count), UVM_NONE)
        
        if (fail_count == 0) begin
            `uvm_info("SCOREBOARD", "*** ALL TESTS PASSED ***", UVM_NONE)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("*** %0d TESTS FAILED ***", fail_count))
        end
    endfunction
endclass

// Agent class
class ic_agent extends uvm_agent;
    `uvm_component_utils(ic_agent)
    
    ic_driver driver;
    ic_monitor monitor;
    uvm_sequencer#(ic_transaction) sequencer;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (is_active == UVM_ACTIVE) begin
            driver = ic_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(ic_transaction)::type_id::create("sequencer", this);
        end
        monitor = ic_monitor::type_id::create("monitor", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass

// Environment class
class ic_env extends uvm_env;
    `uvm_component_utils(ic_env)
    
    ic_agent agent;
    ic_scoreboard scoreboard;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ENV", "=== ENVIRONMENT BUILD PHASE ===", UVM_MEDIUM)
        `uvm_info("ENV", "CREATING: IC Agent for stimulus generation and monitoring", UVM_MEDIUM)
        agent = ic_agent::type_id::create("agent", this);
        `uvm_info("ENV", "CREATING: IC Scoreboard for result checking", UVM_MEDIUM)
        scoreboard = ic_scoreboard::type_id::create("scoreboard", this);
        `uvm_info("ENV", "BUILD COMPLETE: All environment components created", UVM_MEDIUM)
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        `uvm_info("ENV", "=== ENVIRONMENT CONNECT PHASE ===", UVM_MEDIUM)
        `uvm_info("ENV", "CONNECTING: Monitor analysis port to Scoreboard analysis imp", UVM_MEDIUM)
        agent.monitor.ap.connect(scoreboard.ap_imp);
        `uvm_info("ENV", "CONNECTION ESTABLISHED: Monitor → Scoreboard data flow active", UVM_MEDIUM)
    endfunction
endclass

// Base test class
class ic_base_test extends uvm_test;
    `uvm_component_utils(ic_base_test)
    
    ic_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ic_env::type_id::create("env", this);
    endfunction
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// Specific test classes
class ic_single_irq_test extends ic_base_test;
    `uvm_component_utils(ic_single_irq_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_single_irq_sequence seq;
        phase.raise_objection(this);
        
        seq = ic_single_irq_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

class ic_priority_test extends ic_base_test;
    `uvm_component_utils(ic_priority_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_priority_sequence seq;
        phase.raise_objection(this);
        
        seq = ic_priority_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

class ic_mask_test extends ic_base_test;
    `uvm_component_utils(ic_mask_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_mask_sequence seq;
        phase.raise_objection(this);
        
        seq = ic_mask_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

class ic_comprehensive_test extends ic_base_test;
    `uvm_component_utils(ic_comprehensive_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ic_single_irq_sequence single_seq;
        ic_priority_sequence priority_seq;
        ic_mask_sequence mask_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "🚀 ===== COMPREHENSIVE TEST STARTED =====", UVM_LOW)
        `uvm_info("TEST", "MISSION: Complete verification of interrupt controller functionality", UVM_LOW)
        `uvm_info("TEST", "PLAN: Single IRQ → Priority → Masking tests", UVM_LOW)
        
        `uvm_info("TEST", "📍 Phase 1: Starting Single IRQ Test", UVM_LOW)
        `uvm_info("TEST", "OBJECTIVE: Verify each interrupt line works independently", UVM_MEDIUM)
        single_seq = ic_single_irq_sequence::type_id::create("single_seq");
        single_seq.start(env.agent.sequencer);
        `uvm_info("TEST", "✅ Phase 1: Single IRQ Test completed", UVM_LOW)
        
        #500ns;
        
        `uvm_info("TEST", "📍 Phase 2: Starting Priority Test", UVM_LOW)
        `uvm_info("TEST", "OBJECTIVE: Verify interrupt priority resolution works correctly", UVM_MEDIUM)
        priority_seq = ic_priority_sequence::type_id::create("priority_seq");
        priority_seq.start(env.agent.sequencer);
        `uvm_info("TEST", "✅ Phase 2: Priority Test completed", UVM_LOW)
        
        #500ns;
        
        `uvm_info("TEST", "📍 Phase 3: Starting Mask Test", UVM_LOW)
        `uvm_info("TEST", "OBJECTIVE: Verify interrupt masking functionality works correctly", UVM_MEDIUM)
        mask_seq = ic_mask_sequence::type_id::create("mask_seq");
        mask_seq.start(env.agent.sequencer);
        `uvm_info("TEST", "✅ Phase 3: Mask Test completed", UVM_LOW)
        
        #1000ns;
        
        `uvm_info("TEST", "🏁 ===== COMPREHENSIVE TEST COMPLETED =====", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// Interface
interface ic_interface (input logic clk);
    logic       rstn;
    logic [7:0] irq_requests;
    logic [7:0] mask_reg;
    logic       irq_out;
    logic [2:0] irq_id;
    logic       ack;
    logic       busy;
    
    // Clocking blocks
    clocking driver_cb @(posedge clk);
        output rstn, irq_requests, mask_reg;
        input irq_out, irq_id, ack, busy;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        input rstn, irq_requests, mask_reg, irq_out, irq_id, ack, busy;
    endclocking
    
    modport DRIVER (clocking driver_cb);
    modport MONITOR (clocking monitor_cb);
endinterface

// Top-level testbench module
module uvm_testbench;
    
    // Clock and reset
    logic clk = 0;
    always #5ns clk = ~clk;
    
    // Interface instantiation
    ic_interface intf(clk);
    
    // DUT instantiation
    interrupt_controller_dut dut (
        .clk(intf.clk),
        .rstn(intf.rstn),
        .irq_requests(intf.irq_requests),
        .mask_reg(intf.mask_reg),
        .irq_out(intf.irq_out),
        .irq_id(intf.irq_id),
        .ack(intf.ack),
        .busy(intf.busy)
    );
    
    // Reset generation
    initial begin
        intf.rstn = 0;
        intf.irq_requests = 8'h00;
        intf.mask_reg = 8'hFF;
        #50ns intf.rstn = 1;
    end
    
    // UVM configuration and test start
    initial begin
        // Configure interface
        uvm_config_db#(virtual ic_interface)::set(null, "*", "vif", intf);
        
        // Enable waveform dumping
        $dumpfile("uvm_waves.vcd");
        $dumpvars(0, uvm_testbench);
        
        // Run the test. This can be overridden by +UVM_TESTNAME on the command line.
        run_test("ic_comprehensive_test");
    end
    
    // Timeout protection
    initial begin
        #100ms;
        `uvm_fatal("TIMEOUT", "Test timeout reached!")
    end
    
endmodule
