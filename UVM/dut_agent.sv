//classe dut_agent
`ifndef DUT_AGENT_SV
`define DUT_AGENT_SV

class dut_agent extends uvm_agent;
  `uvm_component_utils(dut_agent)

  // Subcomponentes
  dut_sequencer sqr;
  dut_driver    driver;
  dut_monitor   monitor;
  dut_predictor predictor;

  // Interface compartilhada
  virtual dut_if vif;

  // Config
  dut_cfg cfg;

  // Ports para o scoreboard
  uvm_analysis_port#(dut_txn) expected_port;
  uvm_analysis_port#(dut_txn) observed_port;
  // Port para eventos de execucao
  uvm_analysis_port#(dut_exec_txn) exec_observed_port;

  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_port = new("expected_port", this);
    observed_port = new("observed_port", this);
    exec_observed_port = new("exec_observed_port", this);
  endfunction

  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sqr       = dut_sequencer ::type_id::create("sqr", this);
    driver    = dut_driver    ::type_id::create("driver", this);
    monitor   = dut_monitor   ::type_id::create("monitor", this);
    predictor = dut_predictor ::type_id::create("predictor", this);

    // Preferencia: pega um objeto de configuracao unico
    if (uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg) && (cfg != null)) begin
      vif = cfg.vif;
      uvm_config_db#(bit)::set(this, "driver", "fast_load", cfg.fast_load);
    end

    // Interface compartilhada
    if (vif == null) begin
      if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Virtual interface nao encontrada")
    end

    // Injeta a mesma interface nos subcomponentes
    uvm_config_db#(virtual dut_if)::set(this, "driver",  "vif", vif);
    uvm_config_db#(virtual dut_if)::set(this, "monitor", "vif", vif);

    // Passa cfg para os subcomponentes (se existir)
    if (cfg != null) begin
      uvm_config_db#(dut_cfg)::set(this, "driver", "cfg", cfg);
      uvm_config_db#(dut_cfg)::set(this, "monitor", "cfg", cfg);
      uvm_config_db#(dut_cfg)::set(this, "predictor", "cfg", cfg);
    end
  endfunction

  // --------------------------------------------------
  // connect_phase
  // --------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Sequencer -->  Driver
    driver.seq_item_port.connect(sqr.seq_item_export);

    // Monitor -->  Predictor
    monitor.analysis_port.connect(predictor.stim_imp);

    // Predictor -->  Scoreboard (esperado)
    predictor.analysis_port.connect(expected_port);

    // Monitor -->  Scoreboard (observado)
    monitor.analysis_port.connect(observed_port);

    // Monitor -->  Execucao (observado)
    monitor.exec_analysis_port.connect(exec_observed_port);
  endfunction

endclass

`endif // DUT_AGENT_SV

