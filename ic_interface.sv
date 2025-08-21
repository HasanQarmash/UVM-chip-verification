// Interface Definition for Interrupt Controller
// This interface defines the communication protocol between 
// the interrupt controller and external components

interface ic_interface;
    // Clock and reset signals
    logic        clk;
    logic        rstn;
    
    // Interrupt request signals from peripherals
    logic [7:0]  irq_requests;
    
    // Signals to/from processor
    logic        irq_out;      // Global interrupt to processor
    logic [2:0]  irq_id;       // Interrupt ID to processor
    logic        ack;          // Acknowledge from processor
    
    // Mask register for enabling/disabling interrupts
    logic [7:0]  mask_reg;
    
    // Internal status signals
    logic [7:0]  pending_reg;  // Pending interrupts
    logic        busy;         // Processor busy status

    // Modport for interrupt controller
    modport controller (
        input  clk, rstn, irq_requests, ack, mask_reg,
        output irq_out, irq_id, pending_reg
    );
    
    // Modport for processor
    modport processor (
        input  clk, rstn, irq_out, irq_id,
        output ack, busy
    );
    
    // Modport for testbench
    modport tb (
        input  clk, rstn, irq_out, irq_id, pending_reg, busy,
        output irq_requests, mask_reg
    );

endinterface
