// Complete Testbench with All Modules Included
// This file includes all necessary modules for compilation

// Include all design modules

// Interrupt Controller Module
module ic_interrupt_controller (
    input  logic        clk,          // Clock signal
    input  logic        rstn,         // Active low reset signal
    input  logic [7:0]  irq_in,       // External interrupt requests (IRQ0-IRQ7)
    input  logic        ack,          // Acknowledge signal from CPU
    input  logic [7:0]  mask_reg,     // Mask register to enable/disable interrupts
    output logic        irq_out,      // Global interrupt output to CPU
    output logic [2:0]  irq_id        // ID of highest priority active interrupt
);

    // Internal registers
    logic [7:0] pending_reg;          // Pending interrupt register
    logic [7:0] masked_interrupts;    // Interrupts after masking
    logic [2:0] highest_priority_id;  // ID of highest priority interrupt
    logic       interrupt_pending;   // Flag indicating if any interrupt is pending

    // Apply mask to interrupt requests
    assign masked_interrupts = irq_in & mask_reg;

    // Priority encoder to find highest priority interrupt
    always_comb begin
        highest_priority_id = 3'b000;
        interrupt_pending = 1'b0;
        
        // Priority encoder (IRQ0 has highest priority, IRQ7 has lowest)
        if (pending_reg[0]) begin
            highest_priority_id = 3'b000;
            interrupt_pending = 1'b1;
        end else if (pending_reg[1]) begin
            highest_priority_id = 3'b001;
            interrupt_pending = 1'b1;
        end else if (pending_reg[2]) begin
            highest_priority_id = 3'b010;
            interrupt_pending = 1'b1;
        end else if (pending_reg[3]) begin
            highest_priority_id = 3'b011;
            interrupt_pending = 1'b1;
        end else if (pending_reg[4]) begin
            highest_priority_id = 3'b100;
            interrupt_pending = 1'b1;
        end else if (pending_reg[5]) begin
            highest_priority_id = 3'b101;
            interrupt_pending = 1'b1;
        end else if (pending_reg[6]) begin
            highest_priority_id = 3'b110;
            interrupt_pending = 1'b1;
        end else if (pending_reg[7]) begin
            highest_priority_id = 3'b111;
            interrupt_pending = 1'b1;
        end
    end

    // Pending register management
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pending_reg <= 8'b0;
        end else begin
            // Update pending register: set new requests and clear acknowledged ones
            logic [7:0] next_pending;
            next_pending = pending_reg | masked_interrupts;
            
            // Clear the acknowledged interrupt
            if (ack && interrupt_pending) begin
                next_pending[highest_priority_id] = 1'b0;
            end
            
            pending_reg <= next_pending;
        end
    end

    // Output assignments
    assign irq_out = interrupt_pending;
    assign irq_id = highest_priority_id;

endmodule

// Simple Processor Module
module ic_processor (
    input  logic       clk,        // Clock signal
    input  logic       rstn,       // Active low reset signal
    input  logic       irq_in,     // Interrupt request from controller
    input  logic [2:0] irq_id_in,  // Interrupt ID from controller
    output logic       ack,        // Acknowledge signal to controller
    output logic       busy        // Processor busy status
);

    // Internal state machine states
    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        ACKNOWLEDGE
    } state_t;

    state_t current_state, next_state;
    logic [3:0] process_counter;

    // State machine for processor behavior
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            current_state <= IDLE;
            process_counter <= 4'b0;
        end else begin
            current_state <= next_state;
            
            // Counter for processing delay
            if (current_state == PROCESSING) begin
                process_counter <= process_counter + 1;
            end else begin
                process_counter <= 4'b0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (irq_in) begin
                    next_state = PROCESSING;
                end
            end
            
            PROCESSING: begin
                // Process interrupt for a few clock cycles
                if (process_counter >= 4'd3) begin
                    next_state = ACKNOWLEDGE;
                end
            end
            
            ACKNOWLEDGE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    assign ack = (current_state == ACKNOWLEDGE);
    assign busy = (current_state == PROCESSING) || (current_state == ACKNOWLEDGE);

endmodule

// Design Module - Top Level Integration
module design (
    input  logic        clk,          // Clock signal
    input  logic        rstn,         // Active low reset signal
    input  logic [7:0]  irq_requests, // External interrupt requests
    output logic        irq_out,      // Global interrupt output
    output logic [2:0]  irq_id        // Interrupt ID output
);

    // Internal signals
    logic        ack_signal;
    logic [7:0]  mask_register;
    logic        processor_busy;

    // Simple processor model for acknowledgment
    ic_processor u_processor (
        .clk(clk),
        .rstn(rstn),
        .irq_in(irq_out),
        .irq_id_in(irq_id),
        .ack(ack_signal),
        .busy(processor_busy)
    );

    // Mask register management (can be configured via software)
    // For this example, all interrupts are enabled by default
    assign mask_register = 8'hFF;

    // Interrupt controller instance
    ic_interrupt_controller u_interrupt_controller (
        .clk(clk),
        .rstn(rstn),
        .irq_in(irq_requests),
        .ack(ack_signal),
        .mask_reg(mask_register),
        .irq_out(irq_out),
        .irq_id(irq_id)
    );

endmodule

// Complete Testbench
module complete_testbench;
    
    // Clock and reset signals
    logic clk;
    logic rstn;
    
    // Test stimulus signals
    logic [7:0] irq_requests;
    
    // DUT output signals
    logic       irq_out;
    logic [2:0] irq_id;
    
    // Test monitoring
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // DUT instantiation
    design dut (
        .clk(clk),
        .rstn(rstn),
        .irq_requests(irq_requests),
        .irq_out(irq_out),
        .irq_id(irq_id)
    );
    
    // Clock generation - 100MHz (10ns period)
    always #5ns clk = ~clk;
    
    // Main test execution
    initial begin
        // Initialize signals
        clk = 0;
        rstn = 0;
        irq_requests = 8'h00;
        
        // Enable waveform dumping
        $dumpfile("complete_test.vcd");
        $dumpvars(0, complete_testbench);
        
        // Reset sequence
        #20ns rstn = 1;
        #10ns;
        
        $display("=== Complete Interrupt Controller Test Started ===");
        $display("Time: %0t", $time);
        
        // Test 1: No interrupts
        test_no_interrupts();
        
        // Test 2: Single interrupt tests
        for (int i = 0; i < 8; i++) begin
            test_single_interrupt(i);
        end
        
        // Test 3: Priority tests
        test_priority_irq0_vs_irq7();
        test_priority_irq1_vs_irq4();
        test_priority_multiple();
        
        // Test 4: All interrupts
        test_all_interrupts();
        
        // Test 5: Sequential processing
        test_sequential_processing();
        
        // Final results
        #100ns;
        display_results();
        
        $finish;
    end
    
    // Test no interrupts
    task test_no_interrupts();
        $display("\n--- Test: No Interrupts ---");
        @(posedge clk);
        irq_requests = 8'h00;
        #20ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low when no interrupts");
        #10ns;
    endtask
    
    // Test single interrupt
    task test_single_interrupt(input int irq_num);
        $display("\n--- Test: Single Interrupt IRQ%0d ---", irq_num);
        @(posedge clk);
        irq_requests = (1 << irq_num);
        #20ns;
        
        check_result(irq_out == 1'b1, $sformatf("IRQ_OUT should be high for IRQ%0d", irq_num));
        check_result(irq_id == irq_num, $sformatf("IRQ_ID should be %0d for IRQ%0d", irq_num, irq_num));
        
        // Wait for acknowledgment
        wait(dut.ack_signal);
        #20ns;
        
        // Clear interrupt
        irq_requests = 8'h00;
        #20ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low after acknowledgment");
        #10ns;
    endtask
    
    // Test priority: IRQ0 vs IRQ7
    task test_priority_irq0_vs_irq7();
        $display("\n--- Test: Priority IRQ0 vs IRQ7 ---");
        @(posedge clk);
        irq_requests = 8'b10000001;  // IRQ0 and IRQ7
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd0, "IRQ0 should have priority over IRQ7");
        
        // Wait for acknowledgment of IRQ0
        wait(dut.ack_signal);
        #20ns;
        
        // IRQ7 should now be selected
        check_result(irq_out == 1'b1, "IRQ_OUT should still be high for IRQ7");
        check_result(irq_id == 3'd7, "IRQ7 should be selected after IRQ0 is acknowledged");
        
        // Wait for acknowledgment of IRQ7
        wait(dut.ack_signal);
        #20ns;
        
        irq_requests = 8'h00;
        #20ns;
    endtask
    
    // Test priority: IRQ1 vs IRQ4
    task test_priority_irq1_vs_irq4();
        $display("\n--- Test: Priority IRQ1 vs IRQ4 ---");
        @(posedge clk);
        irq_requests = 8'b00010010;  // IRQ1 and IRQ4
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd1, "IRQ1 should have priority over IRQ4");
        
        // Wait for acknowledgment
        wait(dut.ack_signal);
        #20ns;
        
        irq_requests = 8'h00;
        #20ns;
    endtask
    
    // Test priority with multiple interrupts
    task test_priority_multiple();
        $display("\n--- Test: Priority Multiple IRQs ---");
        @(posedge clk);
        irq_requests = 8'b11110000;  // IRQ7, IRQ6, IRQ5, IRQ4
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd4, "IRQ4 should have highest priority among 4,5,6,7");
        
        // Wait for acknowledgment
        wait(dut.ack_signal);
        #20ns;
        
        irq_requests = 8'h00;
        #20ns;
    endtask
    
    // Test all interrupts
    task test_all_interrupts();
        $display("\n--- Test: All Interrupts ---");
        @(posedge clk);
        irq_requests = 8'hFF;  // All interrupts
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd0, "IRQ0 should be selected from all interrupts");
        
        // Process all interrupts
        for (int i = 0; i < 8; i++) begin
            if (irq_out) begin
                $display("Processing IRQ%0d", irq_id);
                wait(dut.ack_signal);
                #20ns;
            end else begin
                break;
            end
        end
        
        irq_requests = 8'h00;
        #20ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low after all interrupts processed");
    endtask
    
    // Test sequential processing
    task test_sequential_processing();
        $display("\n--- Test: Sequential Processing ---");
        
        // Send interrupts in sequence
        for (int i = 7; i >= 0; i--) begin
            @(posedge clk);
            irq_requests[i] = 1'b1;
            #10ns;
        end
        
        // Should process IRQ0 first
        #20ns;
        check_result(irq_id == 3'd0, "Should process IRQ0 first in sequence");
        
        // Clear all
        irq_requests = 8'h00;
        #50ns;
    endtask
    
    // Check result and update counters
    task check_result(input bit condition, input string message);
        test_count++;
        if (condition) begin
            $display("  PASS: %s", message);
            pass_count++;
        end else begin
            $display("  FAIL: %s", message);
            fail_count++;
        end
    endtask
    
    // Display final results
    task display_results();
        $display("\n=== Test Results ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", fail_count);
        end
    endtask
    
    // Monitor interrupt activity
    always @(posedge clk) begin
        if (rstn && irq_out) begin
            $display("@%0t: IRQ active - ID=%0d, Requests=0x%02x", $time, irq_id, irq_requests);
        end
    end
    
    // Timeout protection
    initial begin
        #50ms;
        $display("ERROR: Test timeout!");
        $finish;
    end
    
endmodule
