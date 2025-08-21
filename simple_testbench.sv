// Simple Testbench for Interrupt Controller (No UVM Dependencies)
// This testbench provides basic stimulus and checking for the interrupt controller

module simple_testbench;
    
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
        $dumpfile("simple_test.vcd");
        $dumpvars(0, simple_testbench);
        
        // Reset sequence
        #20ns rstn = 1;
        #10ns;
        
        $display("=== Simple Interrupt Controller Test Started ===");
        $display("Time: %0t", $time);
        
        // Test 1: No interrupts
        test_no_interrupts();
        
        // Test 2: Single interrupt IRQ0 (highest priority)
        test_single_interrupt(0);
        
        // Test 3: Single interrupt IRQ7 (lowest priority)
        test_single_interrupt(7);
        
        // Test 4: Multiple interrupts - priority test
        test_priority_1();
        test_priority_2();
        
        // Test 5: All interrupts
        test_all_interrupts();
        
        // Final results
        #100ns;
        $display("\n=== Test Results ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", fail_count);
        end
        
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
    task test_priority_1();
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
    task test_priority_2();
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
    
    // Test all interrupts
    task test_all_interrupts();
        $display("\n--- Test: All Interrupts ---");
        @(posedge clk);
        irq_requests = 8'hFF;  // All interrupts
        #20ns;
        
        check_result(irq_out == 1'b1, "IRQ_OUT should be high");
        check_result(irq_id == 3'd0, "IRQ0 should be selected from all interrupts");
        
        // Acknowledge all interrupts one by one
        for (int i = 0; i < 8; i++) begin
            if (irq_out) begin
                $display("Processing IRQ%0d", irq_id);
                wait(dut.ack_signal);
                #20ns;
            end
        end
        
        irq_requests = 8'h00;
        #20ns;
        
        check_result(irq_out == 1'b0, "IRQ_OUT should be low after all interrupts processed");
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
    
    // Monitor interrupt activity
    always @(posedge clk) begin
        if (rstn && irq_out) begin
            $display("@%0t: IRQ active - ID=%0d, Requests=0x%02x", $time, irq_id, irq_requests);
        end
    end
    
endmodule
