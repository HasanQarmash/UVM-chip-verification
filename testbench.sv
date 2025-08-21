// Testbench Top Module
// This module instantiates the DUT and provides stimulus for testing

module testbench;
    
    // Clock and reset signals
    logic clk;
    logic rstn;
    
    // Test stimulus signals
    logic [7:0] irq_requests;
    logic [7:0] mask_reg;
    
    // DUT output signals
    logic       irq_out;
    logic [2:0] irq_id;
    
    // Internal monitoring signals
    logic       ack_signal;
    logic [7:0] pending_reg;
    logic       processor_busy;
    
    // DUT instantiation
    design dut (
        .clk(clk),
        .rstn(rstn),
        .irq_requests(irq_requests),
        .irq_out(irq_out),
        .irq_id(irq_id)
    );
    
    // Connect internal signals for monitoring
    assign ack_signal = dut.ack_signal;
    assign mask_reg = dut.mask_register;
    assign pending_reg = dut.u_interrupt_controller.pending_reg;
    assign processor_busy = dut.u_processor.busy;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;  // 100MHz clock (10ns period)
    end
    
    // Reset generation
    initial begin
        rstn = 0;
        irq_requests = 8'h00;
        #50ns rstn = 1;
        #10ns;
        
        // Start test execution
        $display("=== Interrupt Controller Test Started ===");
        run_test_sequence();
    end
    
    // Test sequence task
    task run_test_sequence();
        $display("@%0t: Starting test sequences...", $time);
        
        // Test 1: Single interrupt requests
        test_single_interrupts();
        
        // Test 2: Priority testing
        test_priority_encoding();
        
        // Test 3: Multiple simultaneous interrupts
        test_multiple_interrupts();
        
        // Test 4: Rapid interrupt sequences
        test_rapid_interrupts();
        
        #1000ns;
        $display("=== All Tests Completed Successfully ===");
        $finish;
    endtask
    
    // Test single interrupt requests
    task test_single_interrupts();
        $display("@%0t: Testing single interrupt requests...", $time);
        
        for (int i = 0; i < 8; i++) begin
            @(posedge clk);
            irq_requests = (1 << i);
            $display("@%0t: Asserting IRQ%0d", $time, i);
            
            // Wait for interrupt to be processed
            wait_for_interrupt_processing();
            
            @(posedge clk);
            irq_requests = 8'h00;
            #20ns;
        end
        
        $display("@%0t: Single interrupt test completed", $time);
    endtask
    
    // Test priority encoding
    task test_priority_encoding();
        $display("@%0t: Testing priority encoding...", $time);
        
        // Test multiple interrupts to verify priority
        @(posedge clk);
        irq_requests = 8'b11000000;  // IRQ7 and IRQ6
        wait_for_interrupt_processing();
        check_priority(6, "IRQ6 should have priority over IRQ7");
        
        @(posedge clk);
        irq_requests = 8'b10000001;  // IRQ7 and IRQ0
        wait_for_interrupt_processing();
        check_priority(0, "IRQ0 should have highest priority");
        
        @(posedge clk);
        irq_requests = 8'b01010101;  // IRQ6, IRQ4, IRQ2, IRQ0
        wait_for_interrupt_processing();
        check_priority(0, "IRQ0 should have highest priority among multiple");
        
        @(posedge clk);
        irq_requests = 8'h00;
        #20ns;
        
        $display("@%0t: Priority encoding test completed", $time);
    endtask
    
    // Test multiple simultaneous interrupts
    task test_multiple_interrupts();
        $display("@%0t: Testing multiple simultaneous interrupts...", $time);
        
        @(posedge clk);
        irq_requests = 8'hFF;  // All interrupts
        wait_for_interrupt_processing();
        check_priority(0, "IRQ0 should be selected from all interrupts");
        
        @(posedge clk);
        irq_requests = 8'hFE;  // All except IRQ0
        wait_for_interrupt_processing();
        check_priority(1, "IRQ1 should be selected when IRQ0 is not present");
        
        @(posedge clk);
        irq_requests = 8'h00;
        #20ns;
        
        $display("@%0t: Multiple interrupts test completed", $time);
    endtask
    
    // Test rapid interrupt sequences
    task test_rapid_interrupts();
        $display("@%0t: Testing rapid interrupt sequences...", $time);
        
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
        
        $display("@%0t: Rapid interrupts test completed", $time);
    endtask
    
    // Wait for interrupt processing
    task wait_for_interrupt_processing();
        @(posedge clk);
        if (irq_out) begin
            wait(ack_signal);
            @(posedge clk);
        end
    endtask
    
    // Check priority correctness
    task check_priority(input [2:0] expected_id, input string message);
        if (irq_out) begin
            if (irq_id == expected_id) begin
                $display("@%0t: PASS - %s (Expected: %0d, Got: %0d)", 
                        $time, message, expected_id, irq_id);
            end else begin
                $error("@%0t: FAIL - %s (Expected: %0d, Got: %0d)", 
                      $time, message, expected_id, irq_id);
            end
        end else begin
            $error("@%0t: FAIL - No interrupt output when expected", $time);
        end
    endtask
    
    // Timeout watchdog
    initial begin
        #10ms;
        $error("TIMEOUT: Test timeout reached!");
        $finish;
    end
    
    // Continuous monitoring
    initial begin
        wait(rstn);
        forever begin
            @(posedge clk);
            if (irq_out) begin
                $display("@%0t: IRQ_OUT asserted, IRQ_ID=%0d, IRQ_REQUESTS=0x%02x, PENDING=0x%02x", 
                        $time, irq_id, irq_requests, pending_reg);
            end
            if (ack_signal) begin
                $display("@%0t: ACK signal asserted for IRQ_ID=%0d", $time, irq_id);
            end
        end
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("interrupt_controller.vcd");
        $dumpvars(0, testbench);
    end
    
endmodule
