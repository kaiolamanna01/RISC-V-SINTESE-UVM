//classe tb_package
package tb_package;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Config
  `include "dut_cfg.sv"

  // Transaction
  `include "dut_txn.sv"

  // Sequencer / Sequence
  `include "dut_sequencer.sv"
  `include "dut_seq.sv"
  `include "dut_seq_lib.sv"

  // Driver / Monitor
  `include "dut_driver.sv"
  `include "dut_monitor.sv"

  // Analysis components
  `include "dut_predictor.sv"
  `include "dut_scoreboard.sv"
  `include "dut_cov.sv"

  // Agent / Env / Test
  `include "dut_agent.sv"
  `include "dut_env.sv"
  `include "dut_test.sv"
  `include "dut_extended_test.sv"
endpackage


