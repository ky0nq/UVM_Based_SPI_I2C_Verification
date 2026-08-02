class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) imp;
	
	// Total PASS/FAIL
    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;

	// Operation PASS/FAIL
    int wr_pass = 0;  int wr_fail = 0;
    int rd_pass = 0;  int rd_fail = 0;

	// SDA (Data Line) Capture PASS/FAIL
    int phy_addr_pass = 0;  int phy_addr_fail = 0;
    int phy_data_pass = 0;  int phy_data_fail = 0;
	// Master <-> Slave PASS/FAIL
    int par_pass      = 0;  int par_fail      = 0;
    int addr_ack_pass = 0;  int addr_ack_fail = 0;
    int data_ack_pass = 0;  int data_ack_fail = 0;

	// Invalid Address (NACK) PASS/FAIL
    int inv_addr_pass = 0;  int inv_addr_fail = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    // Verification-valid slave address list (0x10, 0x20)
    function bit is_valid_addr(logic [6:0] addr);
        return (addr inside {7'h10, 7'h20});
    endfunction

    function void write(i2c_seq_item tr);
        bit tr_pass = 1;
        bit valid_addr;
        total_cnt++;

        valid_addr = is_valid_addr(tr.slave_addr);

        // Address Capture in SDA (physical capture is checked regardless of address validity)
        begin
            logic [7:0] exp_addr = {tr.slave_addr, 1'(tr.operation)};
            check_phy("ADDR_CAP vs {addr,R/W}",
                      tr.addr_byte_cap, exp_addr, tr_pass, phy_addr_pass, phy_addr_fail);
        end

        // Address ACK/NACK : valid addr -> ACK(0) expected, invalid addr -> NACK(1) expected
        check_ack(valid_addr ? "ADDR_ACK=0 (slave ACK)" : "ADDR_ACK=1 (invalid addr NACK)",
                  tr.addr_ack, valid_addr ? 1'b0 : 1'b1, tr_pass, addr_ack_pass, addr_ack_fail);

        if (valid_addr) begin
            // Data Capture in SDA + Final Data + ACK (only meaningful when address was ACKed)
            case (tr.operation)
                I2C_WRITE: begin
                    check_phy("DATA_CAP vs TX_DATA",
                              tr.data_byte_cap, tr.tx_data, tr_pass, phy_data_pass, phy_data_fail);
                    check_par("S_RX vs TX_DATA",
                              tr.s_rx_data, tr.tx_data, tr_pass, par_pass, par_fail);
                    check_ack("DATA_ACK=0 (slave ACK)",
                              tr.data_ack, 1'b0, tr_pass, data_ack_pass, data_ack_fail);
                end
                I2C_READ: begin
                    check_phy("DATA_CAP vs S_TX_DATA",
                              tr.data_byte_cap, tr.s_tx_data, tr_pass, phy_data_pass, phy_data_fail);
                    check_par("M_RX vs S_TX_DATA",
                              tr.m_rx_data, tr.s_tx_data, tr_pass, par_pass, par_fail);
                    check_ack("DATA_ACK=1 (master NACK)",
                              tr.data_ack, 1'b1, tr_pass, data_ack_pass, data_ack_fail);
                end
            endcase
        end else begin
            `uvm_info("SCB_INVALID_ADDR",
                $sformatf("[T%0d] addr=0x%02X is INVALID -> data phase check skipped (NACK expected)",
                          total_cnt, tr.slave_addr), UVM_MEDIUM)
            if (tr_pass) inv_addr_pass++; else inv_addr_fail++;
        end

        if (tr_pass) begin
            `uvm_info("SCB_PASS",
                $sformatf("[T%0d] %-5s  addr=0x%02X  PASS",
                          total_cnt, tr.operation.name(), tr.slave_addr),
                UVM_MEDIUM)
            pass_cnt++;
            if (tr.operation == I2C_WRITE) wr_pass++; else rd_pass++;
        end else begin
            `uvm_error("SCB_FAIL",
                $sformatf("[T%0d] %-5s  addr=0x%02X  FAIL\n        %s",
                          total_cnt, tr.operation.name(), tr.slave_addr, tr.convert2string()))
            fail_cnt++;
            if (tr.operation == I2C_WRITE) wr_fail++; else rd_fail++;
        end
    endfunction

    // check function =======================================================================
    function void check_phy(string tag,
                            logic [7:0] actual, logic [7:0] expected,
                            ref bit pass_flag, ref int p_pass, ref int p_fail);
        if (actual !== expected) begin
            `uvm_error("SCB_PHY_FAIL",
                $sformatf("[PHY | %-28s] expected=0x%02X(%3d)  actual=0x%02X(%3d)  MISMATCH",
                          tag, expected, expected, actual, actual))
            pass_flag = 0; p_fail++;
        end else begin
            `uvm_info("SCB_PHY_OK",
                $sformatf("[PHY | %-28s] 0x%02X(%3d)  MATCH", tag, actual, actual),
                UVM_HIGH)
            p_pass++;
        end
    endfunction

    function void check_par(string tag,
                            logic [7:0] actual, logic [7:0] expected,
                            ref bit pass_flag, ref int p_pass, ref int p_fail);
        if (actual !== expected) begin
            `uvm_error("SCB_PAR_FAIL",
                $sformatf("[PAR | %-28s] expected=0x%02X(%3d)  actual=0x%02X(%3d)  MISMATCH",
                          tag, expected, expected, actual, actual))
            pass_flag = 0; p_fail++;
        end else begin
            `uvm_info("SCB_PAR_OK",
                $sformatf("[PAR | %-28s] 0x%02X(%3d)  MATCH", tag, actual, actual),
                UVM_HIGH)
            p_pass++;
        end
    endfunction

    function void check_ack(string tag,
                            logic actual, logic expected,
                            ref bit pass_flag, ref int p_pass, ref int p_fail);
        if (actual !== expected) begin
            `uvm_error("SCB_ACK_FAIL",
                $sformatf("[ACK | %-28s] expected=%b  actual=%b  MISMATCH", tag, expected, actual))
            pass_flag = 0; p_fail++;
        end else begin
            `uvm_info("SCB_ACK_OK",
                $sformatf("[ACK | %-28s] %b  MATCH", tag, actual),
                UVM_HIGH)
            p_pass++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
        `uvm_info("SCB_REPORT", "         I2C Scoreboard Final Report                        ", UVM_NONE)
        `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Transactions  : %0d",  total_cnt),  UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" PASS          : %0d",  pass_cnt),   UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" FAIL          : %0d",  fail_cnt),   UVM_NONE)
        `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [WRITE ]  PASS : %0d  FAIL : %0d", wr_pass, wr_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [READ  ]  PASS : %0d  FAIL : %0d", rd_pass, rd_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [PHY ADDR ]  PASS : %0d  FAIL : %0d", phy_addr_pass, phy_addr_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [PHY DATA ]  PASS : %0d  FAIL : %0d", phy_data_pass, phy_data_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [PAR DATA ]  PASS : %0d  FAIL : %0d", par_pass,      par_fail),      UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [ADDR ACK ]  PASS : %0d  FAIL : %0d", addr_ack_pass, addr_ack_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [DATA ACK ]  PASS : %0d  FAIL : %0d", data_ack_pass, data_ack_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" [INVALID ADDR / NACK]  PASS : %0d  FAIL : %0d", inv_addr_pass, inv_addr_fail), UVM_NONE)
        `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
        if (fail_cnt == 0)
            `uvm_info ("RESULT", "*** ALL TESTS PASSED ***",                    UVM_NONE)
        else
            `uvm_error("RESULT", $sformatf("*** %0d TEST(S) FAILED ***", fail_cnt))
    endfunction

endclass