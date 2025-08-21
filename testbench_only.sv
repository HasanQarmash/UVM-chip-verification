// Complete Testbench File - Interrupt Controller Verification
// This file contains the complete testbench for testing the interrupt controller

module testbench_only;
    
    // Clock and reset signals
    logic clk;
    logic rstn;
    
    // Test stimulus signals
    logic [7:0] irq_requests;
    
    // DUT output signals
    logic       irq_out;
    logic [2:0] irq_id;
    
    // Test monitoring variables
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
        $dumpfile("interrupt_test.vcd");
        $dumpvars(0, testbench_only);
        
        // Reset sequence
        #20ns rstn = 1;
        #10ns;
        
        $display("=== Interrupt Controller Test Started ===");
        $display("Time: %0t", $time);
        
        // Test 1: No interrupts
        test_no_interrupts();
        
        // Test 2: Single interrupt tests for each IRQ line
        for (int i = 0; i < 8; i++) begin
            test_single_interrupt(i);
        end
        
        // Test 3: Priority tests
        test_priority_irq0_vs_irq7();
        test_priority_irq1_vs_irq4();
        test_priority_multiple();
        
        // Test 4: All interrupts simultaneously
        test_all_interrupts();
        
        // Test 5: Sequential processing
        test_sequential_processing();
        
        // Test 6: Rapid interrupt changes
        test_rapid_interrupts();
        
        // Final results
        #100ns;
        display_final_results();
        
        $finish;
    end
    
    // Test: No interrupts
    task test_no_interrupts();
        $display("\n--- Test: No Interrupts ---");
        @(posedge clk);
        irq_requests = 8'h00;
        #20ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low when no interrupts");
        #10ns;
    endtask
    
    // Test: Single interrupt
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
    
    // Test: Priority IRQ0 vs IRQ7
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
    
    // Test: Priority IRQ1 vs IRQ4
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
    
    // Test: Priority with multiple interrupts
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
    
    // Test: All interrupts
    task test_all_interrupts();
        $display("\n--- Test: All Interrupts ---");
        @(posedge clk);
        irq_requests = 8'hFF;  // All interrupts
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd0, "IRQ0 should be selected from all interrupts");
        
        // Process all interrupts one by one with proper timing
        for (int i = 0; i < 8; i++) begin
            if (irq_out) begin
                $display("Processing IRQ%0d", irq_id);
                wait(dut.ack_signal);
                #30ns;  // Wait longer for processing to complete
            end else begin
                break;
            end
        end
        
        // Clear all interrupt requests
        irq_requests = 8'h00;
        #30ns;
        
        // Give extra time for all internal states to settle
        #50ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low after all interrupts processed");
    endtask
    
    // Test: Sequential processing
    task test_sequential_processing();
        $display("\n--- Test: Sequential Processing ---");
        
        // Clear any previous interrupts
        irq_requests = 8'h00;
        #30ns;
        
        // Send interrupts in reverse order (IRQ7 to IRQ0) one by one
        for (int i = 7; i >= 0; i--) begin
            @(posedge clk);
            irq_requests[i] = 1'b1;
            #5ns;  // Short delay between setting each bit
        end
        
        // Wait for processing to stabilize
        #30ns;
        
        // Should process IRQ0 first (highest priority)
        check_result(irq_id == 3'd0, "Should process IRQ0 first in sequence");
        
        // Clear all interrupts
        irq_requests = 8'h00;
        #50ns;
    endtask
    
    // Test: Rapid interrupt changes
    task test_rapid_interrupts();
        $display("\n--- Test: Rapid Interrupt Changes ---");
        
        // Generate rapid interrupt pattern
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            irq_requests = $random & 8'hFF;
            @(posedge clk);
            #5ns;
        end
        
        @(posedge clk);
        irq_requests = 8'h00;
        #50ns;
        
        $display("Rapid interrupt test completed");
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
    task display_final_results();
        $display("\n=== Test Results Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Success Rate: %.1f%%", (real'(pass_count)/real'(test_count))*100.0);
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
            $display("✓ Interrupt Controller is working correctly!");
        end else begin
            $display("*** %0d TESTS FAILED ***", fail_count);
            $display("✗ Please check the design implementation.");
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
        $display("ERROR: Test timeout reached!");
        $finish;
    end
    
endmodule
