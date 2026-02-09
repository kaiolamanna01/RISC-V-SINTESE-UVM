//classe dut_seq
class dut_sequence extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_sequence)

  function new(string name="dut_sequence");
    super.new(name);
  endfunction

  virtual task body();
    localparam int MAX_PROG = 64;
    dut_txn tx;
    bit [31:0] program_mem [0:MAX_PROG-1];
    string program_file;
    int program_len = MAX_PROG;
    int run_cycles = 200;
    int num_txns = 2000;
    int run_cycles_min = 50;
    int run_cycles_max = 500;
    bit rand_loads = 0;
    int load_prob_pct = 5;

    for (int i = 0; i < MAX_PROG; i++)
      program_mem[i] = 32'hXXXXXXXX;

    if (!$value$plusargs("PROGRAM=%s", program_file))
      program_file = "CPU/program_cpu_tb.txt";

    if ($value$plusargs("PROGRAM_LEN=%d", program_len)) begin
      if (program_len > MAX_PROG)
        program_len = MAX_PROG;
    end

    void'($value$plusargs("RUN_CYCLES=%d", run_cycles));
    void'($value$plusargs("NUM_TXNS=%d", num_txns));
    void'($value$plusargs("RUN_CYCLES_MIN=%d", run_cycles_min));
    void'($value$plusargs("RUN_CYCLES_MAX=%d", run_cycles_max));
    void'($value$plusargs("RAND_LOADS=%d", rand_loads));
    void'($value$plusargs("LOAD_PROB_PCT=%d", load_prob_pct));

    if (num_txns < 1)
      num_txns = 1;

    if (run_cycles_min > run_cycles_max) begin
      int tmp;
      tmp = run_cycles_min;
      run_cycles_min = run_cycles_max;
      run_cycles_max = tmp;
    end

    begin
      int fd;
      fd = $fopen(program_file, "r");
      if (fd == 0) begin
        `uvm_fatal("SEQ", $sformatf("Nao foi possivel abrir o arquivo de programa: %s", program_file))
      end
      else begin
        $fclose(fd);
        $readmemh(program_file, program_mem);
        `uvm_info("SEQ", $sformatf("Programa carregado de %s", program_file), UVM_LOW)
      end
    end

    // -------------------------------
    // Fase 1 â€” Carregamento do programa
    // -------------------------------
    for (int i = 0; i < program_len; i++) begin
      if (^program_mem[i] === 1'bX)
        break;
      tx = dut_txn::type_id::create($sformatf("load_%0d", i));
      tx.kind      = dut_txn::TXN_LOAD;
      tx.addr_inst = i * 4;
      tx.instr     = program_mem[i];
      start_item(tx);
      finish_item(tx);
    end

    `uvm_info("SEQ", "Carregamento de instrucoes concluido", UVM_LOW)

    // -------------------------------
    // Fase 2 â€” ExecuÃ§Ã£o do programa
    // -------------------------------
    tx = dut_txn::type_id::create("run");
    tx.kind       = dut_txn::TXN_RUN;
    tx.run_cycles = run_cycles;
    start_item(tx);
    finish_item(tx);

    // -------------------------------
    // Fase 3 â€” EstÃ­mulo aleatÃ³rio (CRV)
    // -------------------------------
    `uvm_info("SEQ", $sformatf("Iniciando CRV com %0d transacoes", num_txns), UVM_LOW)
    for (int k = 0; k < num_txns; k++) begin
      tx = dut_txn::type_id::create($sformatf("run_rand_%0d", k));
      if (!tx.randomize() with {
            kind == dut_txn::TXN_RUN;
            run_cycles inside {[run_cycles_min:run_cycles_max]};
          }) begin
        `uvm_error("SEQ", "Falha ao randomizar TXN_RUN")
      end
      start_item(tx);
      finish_item(tx);

      // Opcionalmente injeta cargas aleatorias de instrucoes
      if (rand_loads && ($urandom_range(0,99) < load_prob_pct)) begin
        tx = dut_txn::type_id::create($sformatf("load_rand_%0d", k));
        if (!tx.randomize() with {
              kind == dut_txn::TXN_LOAD;
              addr_inst inside {[0:(program_len-1)*4]};
              addr_inst[1:0] == 2'b00;
            }) begin
          `uvm_error("SEQ", "Falha ao randomizar TXN_LOAD")
        end
        start_item(tx);
        finish_item(tx);
      end
    end

  endtask
endclass

