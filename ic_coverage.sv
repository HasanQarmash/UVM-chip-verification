// Coverage Class for Interrupt Controller
// This class collects functional coverage for verification completeness

class ic_coverage extends uvm_subscriber #(ic_sequence_item);
    `uvm_component_utils(ic_coverage)
    
    // Coverage groups
    covergroup interrupt_requests_cg;
        option.per_instance = 1;
        option.name = "interrupt_requests_coverage";
        
        // Cover each interrupt request line
        irq0: coverpoint item.irq_requests[0] {
            bins active = {1};
            bins inactive = {0};
        }
        irq1: coverpoint item.irq_requests[1] {
            bins active = {1};
            bins inactive = {0};
        }
        irq2: coverpoint item.irq_requests[2] {
            bins active = {1};
            bins inactive = {0};
        }
        irq3: coverpoint item.irq_requests[3] {
            bins active = {1};
            bins inactive = {0};
        }
        irq4: coverpoint item.irq_requests[4] {
            bins active = {1};
            bins inactive = {0};
        }
        irq5: coverpoint item.irq_requests[5] {
            bins active = {1};
            bins inactive = {0};
        }
        irq6: coverpoint item.irq_requests[6] {
            bins active = {1};
            bins inactive = {0};
        }
        irq7: coverpoint item.irq_requests[7] {
            bins active = {1};
            bins inactive = {0};
        }
        
        // Cover interrupt request patterns
        irq_pattern: coverpoint item.irq_requests {
            bins no_interrupts = {8'h00};
            bins single_irq = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins multiple_irq = {[8'h03:8'hFE]};
            bins all_interrupts = {8'hFF};
        }
    endgroup
    
    covergroup mask_register_cg;
        option.per_instance = 1;
        option.name = "mask_register_coverage";
        
        // Cover mask register patterns
        mask_pattern: coverpoint item.mask_reg {
            bins all_masked = {8'h00};
            bins all_enabled = {8'hFF};
            bins partial_mask = {[8'h01:8'hFE]};
        }
        
        // Cover each mask bit
        mask0: coverpoint item.mask_reg[0];
        mask1: coverpoint item.mask_reg[1];
        mask2: coverpoint item.mask_reg[2];
        mask3: coverpoint item.mask_reg[3];
        mask4: coverpoint item.mask_reg[4];
        mask5: coverpoint item.mask_reg[5];
        mask6: coverpoint item.mask_reg[6];
        mask7: coverpoint item.mask_reg[7];
    endgroup
    
    covergroup output_signals_cg;
        option.per_instance = 1;
        option.name = "output_signals_coverage";
        
        // Cover IRQ output
        irq_out: coverpoint item.irq_out {
            bins active = {1};
            bins inactive = {0};
        }
        
        // Cover IRQ ID
        irq_id: coverpoint item.irq_id {
            bins irq_ids[] = {[0:7]};
        }
        
        // Cover acknowledge signal
        ack: coverpoint item.ack {
            bins active = {1};
            bins inactive = {0};
        }
    endgroup
    
    covergroup priority_cg;
        option.per_instance = 1;
        option.name = "priority_coverage";
        
        // Cross coverage between interrupt requests and selected ID
        priority_cross: cross item.irq_requests, item.irq_id {
            // Only consider cases where interrupt is active
            ignore_bins inactive = binsof(item.irq_out) intersect {0};
        }
    endgroup
    
    covergroup mask_interaction_cg;
        option.per_instance = 1;
        option.name = "mask_interaction_coverage";
        
        // Cross coverage between requests and mask
        mask_interaction: cross item.irq_requests, item.mask_reg;
    endgroup
    
    // Local item for coverage
    ic_sequence_item item;
    
    // Constructor
    function new(string name = "ic_coverage", uvm_component parent = null);
        super.new(name, parent);
        interrupt_requests_cg = new();
        mask_register_cg = new();
        output_signals_cg = new();
        priority_cg = new();
        mask_interaction_cg = new();
    endfunction
    
    // Write method called by analysis port
    virtual function void write(ic_sequence_item t);
        item = t;
        
        // Sample coverage groups
        interrupt_requests_cg.sample();
        mask_register_cg.sample();
        output_signals_cg.sample();
        priority_cg.sample();
        mask_interaction_cg.sample();
        
        `uvm_info("COVERAGE", $sformatf("Sampled coverage for transaction: %s", t.convert2string()), UVM_HIGH)
    endfunction
    
    // Report coverage at end of test
    virtual function void report_phase(uvm_phase phase);
        real coverage_percent;
        
        super.report_phase(phase);
        
        `uvm_info("COVERAGE", "=== COVERAGE REPORT ===", UVM_LOW)
        
        coverage_percent = interrupt_requests_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Interrupt Requests Coverage: %.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = mask_register_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Mask Register Coverage: %.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = output_signals_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Output Signals Coverage: %.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = priority_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Priority Coverage: %.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = mask_interaction_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Mask Interaction Coverage: %.2f%%", coverage_percent), UVM_LOW)
        
        // Overall coverage
        coverage_percent = $get_coverage();
        `uvm_info("COVERAGE", $sformatf("Overall Coverage: %.2f%%", coverage_percent), UVM_LOW)
    endfunction
    
endclass
