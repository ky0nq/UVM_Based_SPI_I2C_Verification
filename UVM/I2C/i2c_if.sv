interface i2c_if (
    input logic clk,
    input logic rst
);
    // Master Command
    logic        cmd_start;
    logic        cmd_write;
    logic        cmd_read;
    logic        cmd_stop;
    logic [7:0]  m_tx_data;
    logic        ack_in;        

    // Master Output
    logic [7:0]  m_rx_data;
    logic        ack_out;
    logic        m_busy;
    logic        m_done;
    logic        m_tx_done;
    logic        m_rx_done;

    // Slave Interface
    logic [7:0]  s_tx_data;
    logic [7:0]  s_rx_data;     
    logic        s_rx_valid;    

    // open drain + pull-up
    wire         scl;          
    wire         sda;          

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output cmd_start;
        output cmd_write;
        output cmd_read;
        output cmd_stop;
        output m_tx_data;
        output ack_in;
        output s_tx_data;
        input  m_rx_data;
        input  m_done;
        input  m_tx_done;
        input  m_rx_done;
        input  m_busy;
        input  s_rx_data;
        input  s_rx_valid;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input cmd_start;
        input cmd_write;
        input cmd_read;
        input cmd_stop;
        input m_tx_data;
        input m_rx_data;
        input m_done;
        input m_tx_done;
        input m_rx_done;
        input m_busy;
        input ack_in;
        input ack_out;
        input s_tx_data;
        input s_rx_data;
        input s_rx_valid;
        input scl;
        input sda;
    endclocking

    modport DRV(clocking drv_cb, input clk, input rst);
    modport MON(clocking mon_cb, input clk, input rst);
endinterface
