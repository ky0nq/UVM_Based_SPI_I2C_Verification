class spi_coverage extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_coverage)

    spi_seq_item tr;

    covergroup spi_cg;
        option.per_instance = 1;

        cp_operation: coverpoint tr.operation {
            bins tx_only     = {TX_ONLY};
            bins rx_only     = {RX_ONLY};
            bins full_duplex = {FULL_DUPLEX};
        }
        cp_m_tx: coverpoint tr.m_tx_data {
            bins min    = {8'h00};
            bins low     = {[8'h01:8'h3F]};
            bins mid     = {[8'h40:8'h7F]};
            bins high    = {[8'h80:8'hBF]};
            bins near_max= {[8'hC0:8'hFE]};
            bins max = {8'hFF};
        }
        cp_s_tx: coverpoint tr.s_tx_data {
            bins min    = {8'h00};
            bins low     = {[8'h01:8'h3F]};
            bins mid     = {[8'h40:8'h7F]};
            bins high    = {[8'h80:8'hBF]};
            bins near_max= {[8'hC0:8'hFE]};
            bins max = {8'hFF};
        }
        cx_op_m_tx: cross cp_operation, cp_m_tx;
        cx_op_s_tx: cross cp_operation, cp_s_tx;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    function void write(spi_seq_item t);
        tr = t;
        spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "==================================================================", UVM_LOW)
        `uvm_info("COV", "=============         Coverage Final Report        ===============", UVM_LOW)
        `uvm_info("COV", $sformatf("        total        : %6.2f %%", spi_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("     operation       : %6.2f %% (TX_ONLY/RX_ONLY/FULL_DUPLEX)", spi_cg.cp_operation.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("     m_tx_data       : %6.2f %% (min/low/mid/high/max)", spi_cg.cp_m_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("     s_tx_data       : %6.2f %% (min/low/mid/high/max)", spi_cg.cp_s_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  op X m_tx_data     : %6.2f %% (cross)", spi_cg.cx_op_m_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  op X s_tx_data     : %6.2f %% (cross)", spi_cg.cx_op_s_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", "==================================================================", UVM_LOW)

        if (spi_cg.get_inst_coverage() < 100.0)
            `uvm_warning("COV", "Coverage not 100%! More tests needed")
    endfunction

endclass