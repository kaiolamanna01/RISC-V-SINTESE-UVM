//classe dut_scoreboard
`ifndef DUT_SCOREBOARD_SV
`define DUT_SCOREBOARD_SV

`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class dut_scoreboard extends uvm_component;
  `uvm_component_utils(dut_scoreboard)

  // Analysis ports para expected e actual (callbacks distintos)
  uvm_analysis_imp_expected#(dut_txn, dut_scoreboard) expected_export;
  uvm_analysis_imp_actual#(dut_txn, dut_scoreboard)   actual_export;

  // Filas
  dut_txn expected_q[$];
  dut_txn actual_q[$];

  // Controle de verbosidade e estatisticas
  bit verbose_scoreboard = 0;
  int unsigned transaction_count = 0;
  int unsigned match_count = 0;
  int unsigned mismatch_count = 0;
  int unsigned status_interval = 100;

  dut_cfg cfg;

  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);

    void'(uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg));
    if (cfg != null) begin
      verbose_scoreboard = cfg.verbose_scoreboard;
      status_interval    = cfg.status_interval;
    end

    // Configuracao via config_db ou plusargs
    void'(uvm_config_db#(bit)::get(this, "", "verbose_scoreboard", verbose_scoreboard));
    if ($test$plusargs("SCOREBOARD_VERBOSE"))
      verbose_scoreboard = 1;

    void'(uvm_config_db#(int unsigned)::get(this, "", "status_interval", status_interval));
  endfunction

  // --------------------------------------------------
  // Recebimento dos pacotes
  // --------------------------------------------------
  function void write_expected(dut_txn t);
    dut_txn copy = dut_txn::type_id::create("exp_copy");
    copy.copy(t);
    expected_q.push_back(copy);
  endfunction

  function void write_actual(dut_txn t);
    dut_txn copy = dut_txn::type_id::create("act_copy");
    copy.copy(t);
    actual_q.push_back(copy);
  endfunction

  // --------------------------------------------------
  // Comparacao
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
  dut_txn exp, act;
  forever begin
    wait(expected_q.size() > 0 && actual_q.size() > 0);

    if (expected_q.size() > 100 || actual_q.size() > 100)
      `uvm_warning("QUEUE_OVERFLOW", "Scoreboard queues estao crescendo deamis - possivel desalinhamento");

    exp = expected_q.pop_front();
    act = actual_q.pop_front();

    compare_transactions(exp, act);
  end
  endtask

  task compare_transactions(dut_txn exp, dut_txn act);
    if (exp.kind != dut_txn::TXN_MEM_EVT || act.kind != dut_txn::TXN_MEM_EVT)
      return;

    transaction_count++;

    if (exp.mem_we !== act.mem_we || exp.mem_read !== act.mem_read || exp.mem_addr !== act.mem_addr) begin
      mismatch_count++;
      `uvm_error("MISMATCH", $sformatf(
        "\nExpected -> mem_we=%0b mem_read=%0b mem_addr=%0h mem_wdata=%0h mem_rdata=%0h \
         \nActual   -> mem_we=%0b mem_read=%0b mem_addr=%0h mem_wdata=%0h mem_rdata=%0h",
        exp.mem_we, exp.mem_read, exp.mem_addr, exp.mem_wdata, exp.mem_rdata,
        act.mem_we, act.mem_read, act.mem_addr, act.mem_wdata, act.mem_rdata))
      return;
    end

    if (exp.mem_we && exp.mem_wdata !== act.mem_wdata) begin
      mismatch_count++;
      `uvm_error("MISMATCH", $sformatf(
        "\nWRITE Expected -> addr=%0h data=%0h \nWRITE Actual   -> addr=%0h data=%0h",
        exp.mem_addr, exp.mem_wdata, act.mem_addr, act.mem_wdata))
    end
    else if (exp.mem_read && exp.mem_rdata !== act.mem_rdata) begin
      mismatch_count++;
      `uvm_error("MISMATCH", $sformatf(
        "\nREAD Expected -> addr=%0h data=%0h \nREAD Actual   -> addr=%0h data=%0h",
        exp.mem_addr, exp.mem_rdata, act.mem_addr, act.mem_rdata))
    end
    else begin
      match_count++;
      if (verbose_scoreboard) begin
        `uvm_info("MATCH_DETAIL", $sformatf(
          "\nMEM EVT -> we=%0b read=%0b addr=%0h wdata=%0h rdata=%0h",
          act.mem_we, act.mem_read, act.mem_addr, act.mem_wdata, act.mem_rdata), UVM_MEDIUM)
      end
    end

    if ((transaction_count % status_interval) == 0) begin
      `uvm_info("SCOREBOARD_STATUS", $sformatf(
        "Processadas %0d transacoes | matches=%0d mismatches=%0d",
        transaction_count, match_count, mismatch_count), UVM_LOW)
    end
  endtask
endclass
`endif // DUT_SCOREBOARD_SV

