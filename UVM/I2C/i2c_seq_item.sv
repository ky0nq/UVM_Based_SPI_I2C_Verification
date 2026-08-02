typedef enum logic {
    I2C_WRITE = 1'b0,
    I2C_READ  = 1'b1
} i2c_op_e;

class i2c_seq_item extends uvm_sequence_item;

    rand i2c_op_e    operation;
    rand logic [6:0] slave_addr;   // Verification Address Only 7'h10 or 7'h20
    rand logic [7:0] tx_data;      // WRITE Data - Master -> Slave
    rand logic [7:0] s_tx_data;    // READ  Data - Slave  -> Master

    logic [7:0] m_rx_data;         
    logic [7:0] s_rx_data;         

    // Capture in inner signal (etc. SDA)
    logic [7:0] addr_byte_cap;     // Address + R/W in SDA {slave_addr[6:0], R/W}
    logic [7:0] data_byte_cap;     // Data in SDA
    logic       addr_ack;          
    logic       data_ack;          

    constraint c_addr  { slave_addr inside {7'h10, 7'h20}; }
    constraint c_unused {
        if (operation == I2C_READ)  tx_data   == 8'h00;
        if (operation == I2C_WRITE) s_tx_data == 8'h00;
    }

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_enum(i2c_op_e, operation,    UVM_ALL_ON)
        `uvm_field_int (slave_addr,             UVM_ALL_ON)
        `uvm_field_int (tx_data,                UVM_ALL_ON)
        `uvm_field_int (s_tx_data,              UVM_ALL_ON)
        `uvm_field_int (m_rx_data,              UVM_ALL_ON)
        `uvm_field_int (s_rx_data,              UVM_ALL_ON)
        `uvm_field_int (addr_byte_cap,          UVM_ALL_ON)
        `uvm_field_int (data_byte_cap,          UVM_ALL_ON)
        `uvm_field_int (addr_ack,               UVM_ALL_ON)
        `uvm_field_int (data_ack,               UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        case (operation)
            I2C_WRITE:
                return $sformatf("[WRITE] addr=0x%02X tx=0x%02X s_rx=0x%02X ack=%b",
                    slave_addr, tx_data, s_rx_data, addr_ack);
            I2C_READ:
                return $sformatf("[READ ] addr=0x%02X s_tx=0x%02X m_rx=0x%02X ack=%b",
                    slave_addr, s_tx_data, m_rx_data, addr_ack);
            default: return "UNDEFINED";
        endcase
    endfunction
endclass
