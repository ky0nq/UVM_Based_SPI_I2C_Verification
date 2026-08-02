class spi_driver extends uvm_driver#(spi_seq_item);
	`uvm_component_utils(spi_driver)

	virtual spi_if s_if;	

	function new(string name, uvm_component parent);
		super.new(name, parent);	
	endfunction	

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if))
			`uvm_fatal(get_type_name(), "No find virtual interface(vif) in config_db")
	endfunction

	task run_phase(uvm_phase phase);
		s_if.drv_cb.start 		<= 1'b0;
		s_if.drv_cb.operation   <= 2'b00;
		s_if.drv_cb.m_tx_data  	<= 0;
		s_if.drv_cb.s_tx_data  	<= 0;	
		@(negedge s_if.rst); // reset deassertion

		forever begin
			seq_item_port.get_next_item(req);
			drive_item(req);					// drive data
			seq_item_port.item_done();
		end
	endtask
	
	task drive_item(spi_seq_item item);
		@(s_if.drv_cb);	
		s_if.drv_cb.operation <= 2'(item.operation);
		s_if.drv_cb.m_tx_data <= item.m_tx_data;
		s_if.drv_cb.s_tx_data <= item.s_tx_data;
		s_if.drv_cb.start <= 1'b1;
		@(s_if.drv_cb);							// start low convert
		s_if.drv_cb.start <= 1'b0;
		`uvm_info("DRV", $sformatf("[DRV] op = %s   m_tx = %3d  s_tx = %3d", item.operation.name(), item.m_tx_data, item.s_tx_data), UVM_HIGH)

		@(posedge s_if.m_done);
		@(s_if.drv_cb);
	endtask
endclass

