class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    task send(spi_op_e operation, bit [7:0] m_tx_data, bit [7:0] s_tx_data);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.operation = operation;
        item.m_tx_data = m_tx_data;
        item.s_tx_data = s_tx_data;
        finish_item(item);
    endtask
endclass

// Randomize
class spi_random_seq extends spi_base_seq;
    `uvm_object_utils(spi_random_seq)

    rand int num;
    constraint c_num { num inside {[10:30]}; }

    function new(string name = "spi_random_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("random scenario start (%0d repeat, FULL_DUPLEX only)", num), UVM_LOW)
        repeat (num) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                operation == FULL_DUPLEX;       
                m_tx_data inside {[8'h00:8'hFF]};
                s_tx_data inside {[8'h00:8'hFF]};
            })
                `uvm_fatal("SEQ", "Randomize Fail")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "random scenario done", UVM_LOW)
    endtask
endclass

// Directed
class spi_directed_seq extends spi_base_seq;
    `uvm_object_utils(spi_directed_seq)

    function new(string name = "spi_directed_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "=== Phase1: TX_ONLY (M→S) ===", UVM_LOW)
        send(TX_ONLY, 8'h1E, 8'h00);
        send(TX_ONLY, 8'h32, 8'h00);
        send(TX_ONLY, 8'h64, 8'h00);
        send(TX_ONLY, 8'hFF, 8'h00);

        `uvm_info(get_type_name(), "=== Phase2: RX_ONLY (S→M) ===", UVM_LOW)
        send(RX_ONLY, 8'h00, 8'hA5);
        send(RX_ONLY, 8'h00, 8'h5A);
        send(RX_ONLY, 8'h00, 8'hFF);
        send(RX_ONLY, 8'h00, 8'h01);

        `uvm_info(get_type_name(), "=== Phase3: FULL_DUPLEX ===", UVM_LOW)
        send(FULL_DUPLEX, 8'hA5, 8'h5A);
        send(FULL_DUPLEX, 8'h5A, 8'hA5);
        send(FULL_DUPLEX, 8'hF0, 8'h0F);
        send(FULL_DUPLEX, 8'h0F, 8'hF0);
    endtask
endclass

// Boundary
class spi_boundary_seq extends spi_base_seq;
    `uvm_object_utils(spi_boundary_seq)

    function new(string name = "spi_boundary_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "=== Boundary Values ===", UVM_LOW)
        send(FULL_DUPLEX, 8'h00, 8'h00);
        send(FULL_DUPLEX, 8'hFF, 8'hFF);
        send(FULL_DUPLEX, 8'h55, 8'h55);
        send(FULL_DUPLEX, 8'hAA, 8'hAA);
        send(FULL_DUPLEX, 8'h00, 8'hFF);
        send(FULL_DUPLEX, 8'hFF, 8'h00);
        send(FULL_DUPLEX, 8'h55, 8'hAA);
        send(FULL_DUPLEX, 8'hAA, 8'h55);
        send(FULL_DUPLEX, 8'h01, 8'h80);
        send(FULL_DUPLEX, 8'h80, 8'h01);
    endtask
endclass

// Master rx_data -> Slave tx_data loopback
class spi_loopback_seq extends spi_base_seq;
    `uvm_object_utils(spi_loopback_seq)

    rand int num;
    constraint c_num { num inside {[5:15]}; }

    function new(string name = "spi_loopback_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        bit [7:0] echo_data;

        `uvm_info(get_type_name(),
            $sformatf("=== Loopback Test Start (%0d iterations) ===", num), UVM_LOW)

        repeat (num) begin
            item = spi_seq_item::type_id::create("item_tx");
            start_item(item);
            if (!item.randomize() with { operation == TX_ONLY; })
                `uvm_fatal("SEQ", "Loopback step1 randomize fail")
            echo_data = item.m_tx_data;
            `uvm_info(get_type_name(),
                $sformatf("[Loopback Step1] TX  m_tx=0x%02X", echo_data), UVM_LOW)
            finish_item(item);

            item = spi_seq_item::type_id::create("item_rx");
            start_item(item);
            item.operation = RX_ONLY;
            item.m_tx_data = 8'h00;
            item.s_tx_data = echo_data;
            `uvm_info(get_type_name(),
                $sformatf("[Loopback Step2] RX  s_tx=0x%02X (echo)", echo_data), UVM_LOW)
            finish_item(item);
        end

        `uvm_info(get_type_name(), "=== Loopback Test Done ===", UVM_LOW)
    endtask
endclass

// only master -> slave data send
class spi_txonly_seq extends spi_base_seq;
    `uvm_object_utils(spi_txonly_seq)

    rand int num;
    constraint c_num { num inside {[10:30]}; }

    function new(string name = "spi_txonly_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== TX_ONLY seq start (%0d) ===", num), UVM_LOW)
        repeat (num) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                operation == TX_ONLY;           
                m_tx_data inside {[8'h00:8'hFF]};
            })
                `uvm_fatal("SEQ", "Randomize Fail")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== TX_ONLY seq done ===", UVM_LOW)
    endtask
endclass

// only slave -> master data send
class spi_rxonly_seq extends spi_base_seq;
    `uvm_object_utils(spi_rxonly_seq)

    rand int num;
    constraint c_num { num inside {[10:30]}; }

    function new(string name = "spi_rxonly_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== RX_ONLY seq start (%0d) ===", num), UVM_LOW)
        repeat (num) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                operation == RX_ONLY;         
                s_tx_data inside {[8'h00:8'hFF]};
            })
                `uvm_fatal("SEQ", "Randomize Fail")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== RX_ONLY seq done ===", UVM_LOW)
    endtask
endclass
