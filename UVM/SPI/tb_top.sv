import uvm_pkg::*;
import spi_pkg::*;

module tb_top();
	logic clk, rst;
	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst = 1;
		repeat (2) @(posedge clk);
		rst = 0;
	end	
	
	spi_if s_if(
		.clk(clk),
		.rst(rst)
		);

	spi_master U_MASTER (
		.clk	(s_if.clk),
		.rst	(s_if.rst),
		.start	(s_if.start),
		.cpol	(1'b0),
		.cpha	(1'b0),
		.clk_div(8'd4),
		.tx_data(s_if.m_tx_data),
		.rx_data(s_if.m_rx_data),
		.busy	(s_if.m_busy),
		.done	(s_if.m_done),
		.sclk	(s_if.sclk),
		.mosi	(s_if.mosi),
		.miso 	(s_if.miso),
		.ss_n	(s_if.ss_n)
	);
	spi_slave U_SLAVE (
		.clk	(s_if.clk),
		.rst	(s_if.rst),
		.tx_data(s_if.s_tx_data),
		.rx_data(s_if.s_rx_data),
		.done	(s_if.s_done),
		.busy	(),
		.sclk	(s_if.sclk),
		.mosi	(s_if.mosi),
		.miso 	(s_if.miso),
		.ss_n	(s_if.ss_n)
	);
	
	initial begin
		uvm_config_db#(virtual spi_if)::set(null, "*", "s_if", s_if);
		run_test();
	end
	
	initial begin
		$fsdbDumpfile("tb_top.fsdb");
		$fsdbDumpvars(0);
		$fsdbDumpMDA(); // memory array(mem) Dump
	end
endmodule
