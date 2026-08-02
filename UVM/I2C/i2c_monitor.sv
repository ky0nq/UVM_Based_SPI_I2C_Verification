class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual i2c_if i_if;
    uvm_analysis_port #(i2c_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual i2c_if)::get(this, "", "i_if", i_if))
            `uvm_fatal(get_type_name(), "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        i2c_seq_item tr;
        logic [7:0]  addr_cap, data_cap;
        logic        addr_ack_cap, data_ack_cap;

        forever begin
            // start condition
            @(negedge i_if.sda);
            if (i_if.scl !== 1'b1) continue;   // SCL = 0 -> detect x

            addr_cap = 8'h00;
            data_cap = 8'h00;

            // Address Capture
            for (int i = 7; i >= 0; i--) begin
                @(posedge i_if.scl);
                #1;
                addr_cap[i] = i_if.sda;
            end

            // Address ACK : Slave -> Master
            @(posedge i_if.scl);
            #1;
            addr_ack_cap = i_if.sda;    // 0 = ACK, 1 = NACK

            // Data Capture
            for (int i = 7; i >= 0; i--) begin
                @(posedge i_if.scl);
                #1;
                data_cap[i] = i_if.sda;
            end

            // Data ACK 
            // WRITE : Slave 0(ACK) Drive
            // READ  : Master 1(NACK) Drive
            @(posedge i_if.scl);
            #1;
            data_ack_cap = i_if.sda;

            // STOP Waiting
            @(negedge i_if.m_busy);
            @(i_if.mon_cb);

            // seq_item build & send
            tr = i2c_seq_item::type_id::create("tr");
            tr.operation = i2c_op_e'(addr_cap[0]);    // bit[0] = Read / Write information
            tr.slave_addr    = addr_cap[7:1];

            tr.tx_data       = (addr_cap[0] == 1'b0) ? i_if.mon_cb.m_tx_data : 8'h00;
            tr.s_tx_data     = i_if.mon_cb.s_tx_data;
            tr.m_rx_data     = i_if.mon_cb.m_rx_data;
            tr.s_rx_data     = i_if.mon_cb.s_rx_data;
            tr.addr_byte_cap = addr_cap;
            tr.data_byte_cap = data_cap;
            tr.addr_ack      = addr_ack_cap;
            tr.data_ack      = data_ack_cap;

            `uvm_info("MON", $sformatf("[MON] %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

endclass
