class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    virtual i2c_if i_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual i2c_if)::get(this, "", "i_if", i_if))
            `uvm_fatal(get_type_name(), "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // initialization
        i_if.drv_cb.cmd_start <= 1'b0;
        i_if.drv_cb.cmd_write <= 1'b0;
        i_if.drv_cb.cmd_read  <= 1'b0;
        i_if.drv_cb.cmd_stop  <= 1'b0;
        i_if.drv_cb.m_tx_data <= 8'h00;
        i_if.drv_cb.ack_in    <= 1'b1;   
        i_if.drv_cb.s_tx_data <= 8'h00;
        @(negedge i_if.rst); // reset assertion waiting         

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(i2c_seq_item item);
        @(i_if.drv_cb);
        i_if.drv_cb.s_tx_data <= item.s_tx_data;
        i_if.drv_cb.ack_in    <= 1'b1;    

        // start condition
        i_if.drv_cb.cmd_start <= 1'b1;
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_start <= 1'b0;
        @(posedge i_if.m_done);            // start done signal

        // Address + Write/Read
        @(i_if.drv_cb);
        i_if.drv_cb.m_tx_data <= {item.slave_addr, 1'(item.operation)};
        i_if.drv_cb.cmd_write <= 1'b1;
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_write <= 1'b0;
        @(posedge i_if.m_done);            // Address + ACK

        // Data
        if (item.operation == I2C_WRITE) begin  // Write
            @(i_if.drv_cb);
            i_if.drv_cb.m_tx_data <= item.tx_data;
            i_if.drv_cb.cmd_write <= 1'b1;
            @(i_if.drv_cb);
            i_if.drv_cb.cmd_write <= 1'b0;
            @(posedge i_if.m_done);        // Data + ACK + Done signal
        end else begin                     // Read
            @(i_if.drv_cb);
            i_if.drv_cb.cmd_read <= 1'b1;
            @(i_if.drv_cb);
            i_if.drv_cb.cmd_read <= 1'b0;
            @(posedge i_if.m_done);        // DATA + NACK + Done signal
        end

        // stop condition
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_stop <= 1'b1;
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_stop <= 1'b0;
        @(negedge i_if.m_busy);            // STOP Done -> busy = 0
        @(i_if.drv_cb);

        `uvm_info("DRV",
            $sformatf("[DRV] %-5s  addr=0x%02X  tx=0x%02X  s_tx=0x%02X",
                      item.operation.name(), item.slave_addr,
                      item.tx_data, item.s_tx_data),
            UVM_HIGH)
    endtask

endclass
