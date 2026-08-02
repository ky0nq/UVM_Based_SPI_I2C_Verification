class spi_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(spi_scoreboard)

	uvm_analysis_imp #(spi_seq_item, spi_scoreboard) imp;

	// Total PASS/FAIL
	int total_cnt = 0;
	int pass_cnt  = 0;
	int fail_cnt  = 0;
	
	// Operation PASS/FAIL
	int tx_pass = 0;  int tx_fail = 0;
	int rx_pass = 0;  int rx_fail = 0;
	int fd_pass = 0;  int fd_fail = 0;

	// Data Line Capture PASS/FAIL
	int mosi_pass = 0;  int mosi_fail = 0;  
	int miso_pass = 0;  int miso_fail = 0;  

	// Master <-> Slave PASS/FAIL
	int srx_pass  = 0;  int srx_fail  = 0;  
	int mrx_pass  = 0;  int mrx_fail  = 0;  

	function new(string name, uvm_component parent);
		super.new(name, parent);
		imp = new("imp", this);
	endfunction

	function void write(spi_seq_item tr);
    	bit tr_pass = 1;
    	total_cnt++;

		// Per-Operation Check summary 
    	case (tr.operation)
        	TX_ONLY: begin // Master TX data = Master to Slave
           	    check_phy("MOSI_CAP vs M_TX", tr.mosi_captured, tr.m_tx_data, tr_pass, mosi_pass, mosi_fail);
           	    check_par("S_RX vs M_TX",     tr.s_rx_data,     tr.m_tx_data, tr_pass, srx_pass,  srx_fail);
        		if (tr_pass) tx_pass++; else tx_fail++;
        	end
        	RX_ONLY: begin // Master RX data = Slave to Master
          	    check_phy("MISO_CAP vs S_TX", tr.miso_captured, tr.s_tx_data, tr_pass, miso_pass, miso_fail);
            	check_par("M_RX vs S_TX",     tr.m_rx_data,     tr.s_tx_data, tr_pass, mrx_pass,  mrx_fail);
        		if (tr_pass) rx_pass++; else rx_fail++;
        	end
        	FULL_DUPLEX: begin // Master to Slave && Slave to Master
				// inner capture signal vs. send data
        	    check_phy("MOSI_CAP vs M_TX", tr.mosi_captured, tr.m_tx_data, tr_pass, mosi_pass, mosi_fail);
        	    check_phy("MISO_CAP vs S_TX", tr.miso_captured, tr.s_tx_data, tr_pass, miso_pass, miso_fail);
        	    // Master data <-> Slave data PASS/FAIL
				check_par("S_RX vs M_TX",     tr.s_rx_data,     tr.m_tx_data, tr_pass, srx_pass,  srx_fail);
        	    check_par("M_RX vs S_TX",     tr.m_rx_data,     tr.s_tx_data, tr_pass, mrx_pass,  mrx_fail);
        		if (tr_pass) fd_pass++; else fd_fail++;
        	end
    	endcase

		// Total PASS/FAIL check print
    	if (tr_pass) begin
        	`uvm_info("SCB_PASS",
        	    $sformatf("[T%0d] %s  PASS", total_cnt, tr.operation.name()),
        	    UVM_MEDIUM)
        	pass_cnt++;
    	end else begin
        	`uvm_error("SCB_FAIL",
        	    $sformatf("[T%0d] %s  FAIL\n        %s",
        	              total_cnt, tr.operation.name(), tr.convert2string()))
        	fail_cnt++;
    	end
	endfunction
	
	// Detailed PASS/FAIL check print - MISO / MOSI signal PASS/FAIL
	function void check_phy(string tag,
	                        bit [7:0] actual,
	                        bit [7:0] expected,
	                        ref bit   pass_flag,
	                        ref int   p_pass,
	                        ref int   p_fail);
		if (actual !== expected) begin
			`uvm_error("SCB_PHY_FAIL",
				$sformatf("[PHY | %s] expected=0x%02X(%3d)  actual=0x%02X(%3d)  MISMATCH",
				          tag, expected, expected, actual, actual))
			pass_flag = 0;
			p_fail++;
		end else begin
			`uvm_info("SCB_PHY_OK",
				$sformatf("[PHY | %s] 0x%02X(%3d)  MATCH", tag, actual, actual),
				UVM_HIGH)
			p_pass++;
		end
	endfunction
	
	// Detailed PASS/FAIL check print - Master <-> Slave 
	function void check_par(string tag,
	                        bit [7:0] actual,
	                        bit [7:0] expected,
	                        ref bit   pass_flag,
	                        ref int   p_pass,
	                        ref int   p_fail);
		if (actual !== expected) begin
			`uvm_error("SCB_PAR_FAIL",
				$sformatf("[PAR | %s] expected=0x%02X(%3d)  actual=0x%02X(%3d)  MISMATCH",
				          tag, expected, expected, actual, actual))
			pass_flag = 0;
			p_fail++;
		end else begin
			`uvm_info("SCB_PAR_OK",
				$sformatf("[PAR | %s] 0x%02X(%3d)  MATCH", tag, actual, actual),
				UVM_HIGH)
			p_pass++;
		end
	endfunction

    function void report_phase(uvm_phase phase);
		`uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
		`uvm_info("SCB_REPORT", "         SPI Scoreboard Final Report                        ", UVM_NONE)
		`uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" Transactions    : %0d", total_cnt), UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" PASS            : %0d", pass_cnt),  UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" FAIL            : %0d", fail_cnt),  UVM_NONE)
		`uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [TX_ONLY ]  PASS : %0d  FAIL : %0d", tx_pass, tx_fail), UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [RX_ONLY ]  PASS : %0d  FAIL : %0d", rx_pass, rx_fail), UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [FULL_DPX]  PASS : %0d  FAIL : %0d", fd_pass, fd_fail), UVM_NONE)
		`uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [PHY Master→Slave] MOSI  PASS : %0d  FAIL : %0d", mosi_pass, mosi_fail), UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [PHY Slave→Master] MISO  PASS : %0d  FAIL : %0d", miso_pass, miso_fail), UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [PAR Master→Slave] S_RX  PASS : %0d  FAIL : %0d", srx_pass,  srx_fail),  UVM_NONE)
		`uvm_info("SCB_REPORT", $sformatf(" [PAR Slave→Master] M_RX  PASS : %0d  FAIL : %0d", mrx_pass,  mrx_fail),  UVM_NONE)
		`uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
		if (fail_cnt == 0)
		    `uvm_info("RESULT",  "*** ALL TESTS PASSED ***",                    UVM_NONE)
		else
		    `uvm_error("RESULT", $sformatf("*** %0d TEST(S) FAILED ***", fail_cnt))
    endfunction

endclass
