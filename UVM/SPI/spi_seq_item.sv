typedef enum logic [1:0] {
	TX_ONLY     = 2'b00,	// Master to Slave
	RX_ONLY     = 2'b01,	// Slave to Master
	FULL_DUPLEX = 2'b10		// Full Duplex
} spi_op_e;

class spi_seq_item extends uvm_sequence_item;

	rand spi_op_e operation;	// operation
	rand bit  [7:0] m_tx_data; 
	rand bit  [7:0] s_tx_data; 

	bit  [7:0] m_rx_data;      
	bit  [7:0] s_rx_data;      
	
	// inner signal capture
	bit  [7:0] mosi_captured; 
	bit  [7:0] miso_captured; 

	constraint c_op {
        if (operation == TX_ONLY)    s_tx_data == 8'h00;
        if (operation == RX_ONLY)    m_tx_data == 8'h00;
    }
	
	`uvm_object_utils_begin(spi_seq_item)
		`uvm_field_enum(spi_op_e, operation,   UVM_ALL_ON)
		`uvm_field_int(m_tx_data,              UVM_ALL_ON)
		`uvm_field_int(s_tx_data,              UVM_ALL_ON)
		`uvm_field_int(m_rx_data,              UVM_ALL_ON)
		`uvm_field_int(s_rx_data,              UVM_ALL_ON)
		`uvm_field_int(mosi_captured,          UVM_ALL_ON)
		`uvm_field_int(miso_captured,          UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "spi_seq_item");
		super.new(name);
	endfunction

	function string convert2string();
		case (operation)
			TX_ONLY :
				return $sformatf(
					"[TX_ONLY ] m_tx=%3d(0x%02X) | s_rx=%3d(0x%02X) | mosi_cap=%3d(0x%02X)",
					m_tx_data, m_tx_data, s_rx_data, s_rx_data, mosi_captured, mosi_captured);
			RX_ONLY :
				return $sformatf(
					"[RX_ONLY ] s_tx=%3d(0x%02X) | m_rx=%3d(0x%02X) | miso_cap=%3d(0x%02X)",
					s_tx_data, s_tx_data, m_rx_data, m_rx_data, miso_captured, miso_captured);
			FULL_DUPLEX :
				return $sformatf(
					"[FULL_DPX] m_tx=%3d(0x%02X) s_tx=%3d(0x%02X) | m_rx=%3d(0x%02X) s_rx=%3d(0x%02X) | mosi_cap=%3d(0x%02X) miso_cap=%3d(0x%02X)",
					m_tx_data, m_tx_data, s_tx_data, s_tx_data,
					m_rx_data, m_rx_data, s_rx_data, s_rx_data,
					mosi_captured, mosi_captured, miso_captured, miso_captured);
			default :
				return "UNDEFINED";
		endcase
	endfunction 
endclass
