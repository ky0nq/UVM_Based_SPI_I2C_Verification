interface spi_if (
	input logic clk,
	input logic rst
);
  
	// Master 
    logic        start;
	logic [7:0]  m_tx_data;
    logic [7:0]  m_rx_data;
    logic        m_busy;
    logic        m_done;

	// Slave 
   	logic [7:0]  s_tx_data;
	logic [7:0]  s_rx_data;
    logic        s_done;

	// signal
	logic [1:0]  operation;
    logic        sclk;
    logic        mosi;
    logic        miso;
    logic        ss_n;

	// clocking block
	clocking drv_cb @(posedge clk);
		default input #1step output #0;
		output start;
		output operation;
		output m_tx_data;
		output s_tx_data;
		input  m_rx_data;
		input  m_done;
		input  s_rx_data;
		input  s_done;
	endclocking

	clocking mon_cb @(posedge clk);
		default input #1step;
		input start;
		input operation;
		input m_tx_data;
		input m_rx_data;
		input m_done;
		input s_tx_data;
		input s_rx_data;
		input s_done;
		
		// inner signal Capture
		input mosi;  
		input miso;  
		input sclk;  
		input ss_n;  
	endclocking

	modport DRV(clocking drv_cb, input clk, input rst);
	modport MON(clocking mon_cb, input clk, input rst);
endinterface
