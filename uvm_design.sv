// UVM Design File - Interrupt Controller
// This file contains all design modules for UVM testbench

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

// Top Level Design Module
module interrupt_controller_dut (
    input  logic        clk,          // Clock signal
    input  logic        rstn,         // Active low reset signal
    input  logic [7:0]  irq_requests, // External interrupt requests
    input  logic [7:0]  mask_reg,     // Mask register
    output logic        irq_out,      // Global interrupt output
    output logic [2:0]  irq_id,       // Interrupt ID output
    output logic        ack,          // Acknowledge signal
    output logic        busy          // Processor busy status
);

    // Internal signals
    logic        ack_signal;
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

    // Interrupt controller instance
    ic_interrupt_controller u_interrupt_controller (
        .clk(clk),
        .rstn(rstn),
        .irq_in(irq_requests),
        .ack(ack_signal),
        .mask_reg(mask_reg),
        .irq_out(irq_out),
        .irq_id(irq_id)
    );

    // Output assignments
    assign ack = ack_signal;
    assign busy = processor_busy;

endmodule
