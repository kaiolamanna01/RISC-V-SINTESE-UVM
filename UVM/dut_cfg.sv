`ifndef DUT_CFG_SV
`define DUT_CFG_SV

class dut_cfg extends uvm_object;
  `uvm_object_utils(dut_cfg)

  // Virtual interface do DUT
  virtual dut_if vif;

  // Features
  bit enable_cov = 1;

  // Driver behavior
  bit fast_load = 0;

  // Scoreboard behavior
  bit verbose_scoreboard = 0;
  int unsigned status_interval = 100;

  function new(string name = "dut_cfg");
    super.new(name);
  endfunction
endclass

`endif // DUT_CFG_SV
