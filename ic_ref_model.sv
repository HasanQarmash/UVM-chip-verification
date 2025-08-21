// Reference Model for Interrupt Controller
// This module provides the golden reference behavior for verification

module ic_ref_model (
    input  logic        clk,
    input  logic        rstn,
    input  logic [7:0]  irq_in,
    input  logic        ack,
    input  logic [7:0]  mask_reg,
    output logic        irq_out,
    output logic [2:0]  irq_id,
    output logic [7:0]  pending_reg_out
);

    // Internal registers
    logic [7:0] pending_register;
    logic [7:0] masked_interrupts;
    logic [2:0] highest_priority;
    logic       any_pending;

    // Apply mask to incoming interrupts
    assign masked_interrupts = irq_in & mask_reg;

    // Priority encoder for finding highest priority interrupt
    always_comb begin
        highest_priority = 3'b000;
        any_pending = 1'b0;
        
        // Check from highest priority (IRQ0) to lowest (IRQ7)
        for (int i = 0; i < 8; i++) begin
            if (pending_register[i]) begin
                highest_priority = i[2:0];
                any_pending = 1'b1;
                break;
            end
        end
    end

    // Pending register management
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pending_register <= 8'b0;
        end else begin
            // Set bits for new masked interrupt requests
            pending_register <= pending_register | masked_interrupts;
            
            // Clear acknowledged interrupt
            if (ack && any_pending) begin
                pending_register[highest_priority] <= 1'b0;
            end
        end
    end

    // Output assignments
    assign irq_out = any_pending;
    assign irq_id = highest_priority;
    assign pending_reg_out = pending_register;

    // Assertions for verification
    
    // Assert that IRQ_ID is valid when interrupt is active
    property p_valid_irq_id;
        @(posedge clk) disable iff (!rstn)
        irq_out |-> (irq_id <= 3'd7);
    endproperty
    assert property(p_valid_irq_id) else $error("Invalid IRQ_ID when interrupt active");
    
    // Assert that IRQ_OUT is high only when there are pending interrupts
    property p_irq_out_when_pending;
        @(posedge clk) disable iff (!rstn)
        irq_out |-> (|pending_register);
    endproperty
    assert property(p_irq_out_when_pending) else $error("IRQ_OUT high but no pending interrupts");
    
    // Assert that pending register only has masked interrupts
    property p_pending_masked_only;
        @(posedge clk) disable iff (!rstn)
        (pending_register & ~mask_reg) == 8'b0;
    endproperty
    assert property(p_pending_masked_only) else $error("Pending register has unmasked interrupts");
    
    // Assert priority encoding correctness
    property p_priority_encoding;
        @(posedge clk) disable iff (!rstn)
        irq_out |-> (pending_register[irq_id] == 1'b1);
    endproperty
    assert property(p_priority_encoding) else $error("Priority encoding incorrect");

endmodule
