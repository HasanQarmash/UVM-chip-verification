// Design Module - Top Level Integration
// This module integrates the interrupt controller with a simple processor

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
