class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
    `uvm_component_utils(i2c_coverage)

    i2c_seq_item tr;

    covergroup i2c_cg;
        option.per_instance = 1;

        cp_operation: coverpoint tr.operation {
            bins write_op = {I2C_WRITE};
            bins read_op  = {I2C_READ};
        }
        cp_slave_addr: coverpoint tr.slave_addr {
            bins slave0  = {7'h10};
            bins slave1  = {7'h20};
            bins invalid = {7'h00, 7'h01, 7'h30, 7'h50, 7'h7E, 7'h7F};
        }
        cp_tx_data: coverpoint tr.tx_data {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3F]};
            bins mid      = {[8'h40:8'h7F]};
            bins high     = {[8'h80:8'hBF]};
            bins near_max = {[8'hC0:8'hFE]};
            bins max      = {8'hFF};
        }
        cp_s_tx_data: coverpoint tr.s_tx_data {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3F]};
            bins mid      = {[8'h40:8'h7F]};
            bins high     = {[8'h80:8'hBF]};
            bins near_max = {[8'hC0:8'hFE]};
            bins max      = {8'hFF};
        }
        cp_addr_ack: coverpoint tr.addr_ack {
            bins ack  = {1'b0};
            bins nack = {1'b1};
        }

        cx_op_addr   : cross cp_operation, cp_slave_addr;
        cx_addr_tx   : cross cp_slave_addr, cp_tx_data;
        cx_addr_s_tx : cross cp_slave_addr, cp_s_tx_data;
        cx_addr_ack  : cross cp_slave_addr, cp_addr_ack;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    function void write(i2c_seq_item t);
        $cast(tr, t.clone());
        i2c_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "==================================================================", UVM_LOW)
        `uvm_info("COV", "=============         Coverage Final Report        ===============", UVM_LOW)
        `uvm_info("COV", $sformatf("        total          : %6.2f %%", i2c_cg.get_inst_coverage()),                                   UVM_LOW)
        `uvm_info("COV", $sformatf("     operation         : %6.2f %% (WRITE / READ)",            i2c_cg.cp_operation.get_inst_coverage()),   UVM_LOW)
        `uvm_info("COV", $sformatf("     slave_addr        : %6.2f %% (0x10 / 0x20 / invalid)",  i2c_cg.cp_slave_addr.get_inst_coverage()),  UVM_LOW)
        `uvm_info("COV", $sformatf("     tx_data           : %6.2f %% (zero/low/mid/high/max)",   i2c_cg.cp_tx_data.get_inst_coverage()),     UVM_LOW)
        `uvm_info("COV", $sformatf("     s_tx_data         : %6.2f %% (zero/low/mid/high/max)",   i2c_cg.cp_s_tx_data.get_inst_coverage()),   UVM_LOW)
        `uvm_info("COV", $sformatf("     addr_ack          : %6.2f %% (ack / nack)",              i2c_cg.cp_addr_ack.get_inst_coverage()),    UVM_LOW)
        `uvm_info("COV", $sformatf("  op   X slave_addr    : %6.2f %% (cross,  6 bins)",          i2c_cg.cx_op_addr.get_inst_coverage()),     UVM_LOW)
        `uvm_info("COV", $sformatf("  addr X tx_data       : %6.2f %% (cross, 18 bins)",          i2c_cg.cx_addr_tx.get_inst_coverage()),     UVM_LOW)
        `uvm_info("COV", $sformatf("  addr X s_tx_data     : %6.2f %% (cross, 18 bins)",          i2c_cg.cx_addr_s_tx.get_inst_coverage()),   UVM_LOW)
        `uvm_info("COV", $sformatf("  addr X addr_ack      : %6.2f %% (cross,  6 bins)",          i2c_cg.cx_addr_ack.get_inst_coverage()),    UVM_LOW)
        `uvm_info("COV", "==================================================================", UVM_LOW)
        if (i2c_cg.get_inst_coverage() < 100.0)
            `uvm_warning("COV", "Coverage not 100%! More tests needed")
    endfunction

endclass