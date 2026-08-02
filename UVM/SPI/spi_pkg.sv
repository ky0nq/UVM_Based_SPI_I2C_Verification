`include "uvm_macros.svh"
package spi_pkg;
	import uvm_pkg::*;
	// include file write : dependency priority (inner -> outer)
	`include "spi_seq_item.sv"
	`include "spi_sequence.sv"
	`include "spi_driver.sv"
	`include "spi_monitor.sv"
	`include "spi_scoreboard.sv"
	`include "spi_coverage.sv"
	`include "spi_agent.sv"
	`include "spi_env.sv"
	`include "spi_test.sv"

endpackage
