class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if s_if;
    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if))
            `uvm_fatal(get_type_name(), "No find virtual interface(vif) in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item tr;
        bit [7:0] mosi_cap, miso_cap;	// MISO, MOSI capture

        forever begin
            @(negedge s_if.ss_n);	// start detect
            mosi_cap = 8'h00;
            miso_cap = 8'h00;
            fork
                begin : bit_capture // sclk high -> bit data capture
                    for (int i = 7; i >= 0; i--) begin
                        @(posedge s_if.sclk);
						#1step;	// data stable
                        mosi_cap[i] = s_if.mosi;
                        miso_cap[i] = s_if.miso;
                    end
					@(posedge s_if.m_done);	// sending done
                end
            join

            @(s_if.mon_cb);
            tr = spi_seq_item::type_id::create("tr");
            tr.operation     = spi_op_e'(s_if.mon_cb.operation);
            tr.m_tx_data     = s_if.mon_cb.m_tx_data;
            tr.s_tx_data     = s_if.mon_cb.s_tx_data;
            tr.m_rx_data     = s_if.mon_cb.m_rx_data;
            tr.s_rx_data     = s_if.mon_cb.s_rx_data;
            tr.mosi_captured = mosi_cap;  
            tr.miso_captured = miso_cap;  

            `uvm_info("MON", $sformatf("[MON] %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

endclass
