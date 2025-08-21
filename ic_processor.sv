// Simple Processor Model
// This module simulates a basic processor that can acknowledge interrupts

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
