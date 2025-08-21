// Interrupt Controller Module
// This module implements a priority-based interrupt controller
// that handles 8 external interrupt requests (IRQ0-IRQ7)

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
            // Set pending bits for new interrupt requests
            pending_reg <= (pending_reg | masked_interrupts);
            
            // Clear the acknowledged interrupt
            if (ack && interrupt_pending) begin
                pending_reg[highest_priority_id] <= 1'b0;
            end
        end
    end

    // Output assignments
    assign irq_out = interrupt_pending;
    assign irq_id = highest_priority_id;

endmodule
