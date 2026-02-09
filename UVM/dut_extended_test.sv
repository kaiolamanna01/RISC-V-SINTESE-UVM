//teste com cobertura estendida
`ifndef DUT_EXTENDED_TEST_SV
`define DUT_EXTENDED_TEST_SV

class dut_extended_test extends uvm_test;
  `uvm_component_utils(dut_extended_test)

  dut_env              env;
  dut_extended_sequence seq;
  dut_cfg              cfg;

  int unsigned num_transactions = 2000;
  bit run_basic_test = 1;
  bit run_crv_test = 1;
  bit run_stress_test = 1;
  bit parallel_sequences = 0;
  bit run_cov_boost = 1;
  int unsigned coverage_goal = 90;
  int unsigned coverage_max_iters = 1;
  bit coverage_loop = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual dut_if vif;
    bit enable_cov = 1;
    super.build_phase(phase);

    env = dut_env::type_id::create("env", this);

    if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface nao configurada")

    cfg = dut_cfg::type_id::create("cfg");
    cfg.vif = vif;
    cfg.enable_cov = enable_cov;
    cfg.fast_load = $test$plusargs("FAST_LOAD");
    cfg.verbose_scoreboard = $test$plusargs("SCOREBOARD_VERBOSE");
    uvm_config_db#(dut_cfg)::set(this, "env", "cfg", cfg);
    uvm_config_db#(dut_cfg)::set(this, "env.*", "cfg", cfg);

    // Configuracao por linha de comando
    void'($value$plusargs("NUM_TRANS=%d", num_transactions));
    if ($test$plusargs("NO_BASIC")) run_basic_test = 0;
    if ($test$plusargs("NO_CRV")) run_crv_test = 0;
    if ($test$plusargs("STRESS_ONLY")) begin
      run_basic_test = 0;
      run_crv_test = 0;
      run_stress_test = 1;
    end
    if ($test$plusargs("PARALLEL_SEQ")) parallel_sequences = 1;
    if ($test$plusargs("NO_COV_BOOST")) run_cov_boost = 0;
    void'($value$plusargs("COV_GOAL=%d", coverage_goal));
    void'($value$plusargs("COV_MAX_ITERS=%d", coverage_max_iters));
    if ($test$plusargs("COV_LOOP")) coverage_loop = 1;

    uvm_config_db#(virtual dut_if)::set(this, "env.agent", "vif", vif);
    uvm_config_db#(bit)::set(this, "env", "enable_cov", enable_cov);
    uvm_config_db#(bit)::set(this, "env.sb", "verbose_scoreboard", $test$plusargs("SCOREBOARD_VERBOSE"));

    // Flags de execucao para a sequencia estendida
    uvm_config_db#(bit)::set(this, "env.agent.sqr", "run_basic_test", run_basic_test);
    uvm_config_db#(bit)::set(this, "env.agent.sqr", "run_crv_test", run_crv_test);
    uvm_config_db#(bit)::set(this, "env.agent.sqr", "run_stress_test", run_stress_test);
    uvm_config_db#(bit)::set(this, "env.agent.sqr", "parallel_sequences", parallel_sequences);
    uvm_config_db#(bit)::set(this, "env.agent.sqr", "run_cov_boost", run_cov_boost);

    // Parametros para a sequencia CRV inteligente
    uvm_config_db#(int unsigned)::set(this, "env.agent.sqr", "smart_program_len",
      (num_transactions > 64) ? 64 : num_transactions);
    uvm_config_db#(int unsigned)::set(this, "env.agent.sqr", "smart_run_cycles",
      (num_transactions / 2) + 200);
  endfunction

  task run_phase(uvm_phase phase);
    real coverage;
    phase.raise_objection(this);

    `uvm_info("EXT_TEST", "Iniciando teste com cobertura estendida", UVM_MEDIUM)

    if (coverage_loop && env.cov != null && coverage_max_iters > 0) begin
      for (int i = 0; i < coverage_max_iters; i++) begin
        seq = dut_extended_sequence::type_id::create($sformatf("seq_%0d", i));
        if (seq == null)
          `uvm_fatal("NOSEQ", "Sequencia estendida nao foi criada")

        seq.start(env.agent.sqr);

        coverage = env.cov.get_total_coverage();
        `uvm_info("COVERAGE", $sformatf("Cobertura iter %0d: %0.2f%% (meta %0d%%)", i, coverage, coverage_goal), UVM_LOW)
        if (coverage >= coverage_goal) begin
          `uvm_info("COVERAGE", "Meta de cobertura atingida", UVM_LOW)
          break;
        end
      end
    end
    else begin
      seq = dut_extended_sequence::type_id::create("seq");
      if (seq == null)
        `uvm_fatal("NOSEQ", "Sequencia estendida nao foi criada")

      seq.start(env.agent.sqr);

      if (env.cov != null) begin
        coverage = env.cov.get_total_coverage();
        `uvm_info("COVERAGE", $sformatf("Cobertura final: %0.2f%%", coverage), UVM_LOW)
        if (coverage < coverage_goal) begin
          `uvm_warning("COVERAGE", $sformatf("Cobertura abaixo da meta (%0d%%)", coverage_goal))
          env.cov.report_uncovered_bins();
        end
      end
    end

    phase.drop_objection(this);
  endtask

endclass

`endif // DUT_EXTENDED_TEST_SV
