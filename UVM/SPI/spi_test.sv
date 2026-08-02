class spi_base_test extends uvm_test;
    `uvm_component_utils(spi_base_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// random
class spi_random_test extends spi_base_test;
    `uvm_component_utils(spi_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_random_seq seq;
        phase.raise_objection(this);
        seq = spi_random_seq::type_id::create("seq");
        if (!seq.randomize())
            `uvm_fatal(get_type_name(), "seq randomize failed")
        seq.num = 1000;			// randomize execute count
        seq.start(env.agt.sqr);	// uvm task 
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// directed
class spi_directed_test extends spi_base_test;
    `uvm_component_utils(spi_directed_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_directed_seq seq;
        phase.raise_objection(this);
        seq = spi_directed_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// boundary
class spi_boundary_test extends spi_base_test;
    `uvm_component_utils(spi_boundary_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_boundary_seq seq;
        phase.raise_objection(this);
        seq = spi_boundary_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Master rx_data -> Slave tx_data loopback
class spi_loopback_test extends spi_base_test;
    `uvm_component_utils(spi_loopback_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_loopback_seq seq;
        phase.raise_objection(this);
        seq = spi_loopback_seq::type_id::create("seq");
        if (!seq.randomize())
            `uvm_fatal(get_type_name(), "seq randomize failed")
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// only master -> slave test 
class spi_txonly_test extends spi_base_test;
    `uvm_component_utils(spi_txonly_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task check_txonly_phy(spi_seq_item item);
        if (item.mosi_captured === item.m_tx_data)
            `uvm_info("TXONLY_PHY",
                $sformatf("[TX_ONLY PHY] mosi_cap=0x%02X  m_tx=0x%02X  MATCH",
                          item.mosi_captured, item.m_tx_data), UVM_LOW)
        else
            `uvm_error("TXONLY_PHY",
                $sformatf("[TX_ONLY PHY] mosi_cap=0x%02X  m_tx=0x%02X  MISMATCH",
                          item.mosi_captured, item.m_tx_data))
    endtask

    task run_phase(uvm_phase phase);
        spi_txonly_seq seq;
        phase.raise_objection(this);
        seq = spi_txonly_seq::type_id::create("seq");
        if (!seq.randomize())
            `uvm_fatal(get_type_name(), "seq randomize failed")
        `uvm_info(get_type_name(),
            $sformatf("=== TX_ONLY test start (%0d transactions) ===", seq.num), UVM_LOW)
 		seq.num = 1000;
        seq.start(env.agt.sqr);       
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// only slave -> master test
class spi_rxonly_test extends spi_base_test;
    `uvm_component_utils(spi_rxonly_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task check_rxonly_phy(spi_seq_item item);
        if (item.miso_captured === item.s_tx_data)
            `uvm_info("RXONLY_PHY",
                $sformatf("[RX_ONLY PHY] miso_cap=0x%02X  s_tx=0x%02X  MATCH",
                          item.miso_captured, item.s_tx_data), UVM_LOW)
        else
            `uvm_error("RXONLY_PHY",
                $sformatf("[RX_ONLY PHY] miso_cap=0x%02X  s_tx=0x%02X  MISMATCH",
                          item.miso_captured, item.s_tx_data))
    endtask

    task run_phase(uvm_phase phase);
        spi_rxonly_seq seq;
        phase.raise_objection(this);
        seq = spi_rxonly_seq::type_id::create("seq");
        if (!seq.randomize())
            `uvm_fatal(get_type_name(), "seq randomize failed")
        `uvm_info(get_type_name(),
            $sformatf("=== RX_ONLY test start (%0d transactions) ===", seq.num), UVM_LOW)
        seq.num = 1000;
		seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass
