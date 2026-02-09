//classe dut_test
`ifndef DUT_TEST_SV
`define DUT_TEST_SV

class dut_test extends uvm_test;
  `uvm_component_utils(dut_test)

  dut_env       env;
  dut_sequence  seq;
  dut_cfg       cfg;

  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // --------------------------------------------------
  // Build phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    virtual dut_if vif;
    bit enable_cov = 1;
    super.build_phase(phase);

    // Instancia o ambiente
    env = dut_env::type_id::create("env", this);

    // Obtem a virtual interface configurada externamente
    if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface nao configurada. Use uvm_config_db::set antes de run_test().")

    // Cria cfg e publica para o ambiente
    cfg = dut_cfg::type_id::create("cfg");
    cfg.vif = vif;
    cfg.enable_cov = enable_cov;
    cfg.fast_load = $test$plusargs("FAST_LOAD");
    cfg.verbose_scoreboard = $test$plusargs("SCOREBOARD_VERBOSE");
    void'(uvm_config_db#(int unsigned)::get(this, "", "status_interval", cfg.status_interval));

    uvm_config_db#(dut_cfg)::set(this, "env", "cfg", cfg);
    uvm_config_db#(dut_cfg)::set(this, "env.*", "cfg", cfg);

    // Injeta a interface no agent
    uvm_config_db#(virtual dut_if)::set(this, "env.agent", "vif", vif);

    // Habilita ou desabilita o coletor de cobertura
    uvm_config_db#(bit)::set(this, "env", "enable_cov", enable_cov);

    // Mantem compatibilidade com configs antigas
    uvm_config_db#(bit)::set(this, "env.sb", "verbose_scoreboard", cfg.verbose_scoreboard);
  endfunction

  // --------------------------------------------------
  // Run phase
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // Cria e inicia a sequÃªncia principal
    seq = dut_sequence::type_id::create("seq");
    if (seq == null)
      `uvm_fatal("NOSEQ", "Sequencia principal nao foi criada.")

    `uvm_info("TEST", "Iniciando sequencia principal", UVM_MEDIUM)
    seq.start(env.agent.sqr);

    phase.drop_objection(this);
  endtask

endclass

`endif // DUT_TEST_SV

