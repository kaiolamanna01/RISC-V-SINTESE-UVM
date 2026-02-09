//biblioteca de sequencias para aumentar cobertura
`ifndef DUT_SEQ_LIB_SV
`define DUT_SEQ_LIB_SV

// Sequencia para testar diferentes padroes de dados
class dut_data_pattern_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_data_pattern_seq)

  function new(string name="dut_data_pattern_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    bit [31:0] patterns[] = {
      32'h00000000,  // zero
      32'hFFFFFFFF,  // ones
      32'hAAAAAAAA,  // alt1
      32'h55555555,  // alt2
      32'h00000001,  // small_val min
      32'h000000FF,  // small_val max
      32'hFFFFFF00,  // high_val min
      32'hFFFFFFFE,  // high_val max
      32'h12345678,  // outros padroes
      32'h87654321,
      32'hDEADBEEF,
      32'hCAFEBABE,
      32'h0F0F0F0F,
      32'hF0F0F0F0
    };

    int inst_idx = 0;
    logic [11:0] imm12;
    logic [11:0] addr_imm;

    `uvm_info("DATA_PAT_SEQ", $sformatf("Testando %0d padroes de dados", patterns.size()), UVM_MEDIUM)

    // Inicializa base x1 = 0
    tx = dut_txn::type_id::create("init_x1");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h000, 5'b00000, 3'b000, 5'b00001, 7'b0010011}; // ADDI x1,x0,0
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    // Carrega instrucoes para escrever diferentes padroes
    for (int i = 0; i < patterns.size(); i++) begin
      addr_imm = (i * 4) & 12'h0FF;

      // LUI x2, upper
      tx = dut_txn::type_id::create($sformatf("pattern_lui_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {patterns[i][31:12], 5'b00010, 7'b0110111};
      start_item(tx);
      finish_item(tx);
      inst_idx++;

      // ADDI x2, x2, lower
      imm12 = patterns[i][11:0];
      tx = dut_txn::type_id::create($sformatf("pattern_addi_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {imm12, 5'b00010, 3'b000, 5'b00010, 7'b0010011};
      start_item(tx);
      finish_item(tx);
      inst_idx++;

      // SW x2, addr_imm(x1)
      tx = dut_txn::type_id::create($sformatf("pattern_sw_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {addr_imm[11:5], 5'b00010, 5'b00001, 3'b010, addr_imm[4:0], 7'b0100011};
      start_item(tx);
      finish_item(tx);
      inst_idx++;
    end

    // Executa para processar as instrucoes
    tx = dut_txn::type_id::create("run_patterns");
    tx.kind = dut_txn::TXN_RUN;
    tx.run_cycles = 200 + patterns.size() * 20;
    start_item(tx);
    finish_item(tx);
    end
  endtask
endclass

// Sequencia para varrer diferentes enderecos
class dut_addr_sweep_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_addr_sweep_seq)

  function new(string name="dut_addr_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    int addr_ranges[] = {
      0, 4, 8, 12,           // low range (0-3)
      16, 20, 24, 28,        // mid range start
      32, 36, 40, 44,
      48, 52, 56, 60,        // mid range end (4-15)
      64, 68, 72, 76,        // high range start (16-63)
      128, 132, 136, 140,
      200, 204, 208, 212,
      240, 244, 248, 252     // high range end
    };

    int inst_idx = 0;
    logic [11:0] addr_imm;

    `uvm_info("ADDR_SWEEP_SEQ", $sformatf("Varrendo %0d enderecos", addr_ranges.size()), UVM_MEDIUM)

    // Inicializa base x1 = 0
    tx = dut_txn::type_id::create("addr_init_x1");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h000, 5'b00000, 3'b000, 5'b00001, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    // Inicializa x2 = 0x5A (dados para store) via ADDI
    tx = dut_txn::type_id::create("addr_init_x2");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h05A, 5'b00000, 3'b000, 5'b00010, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    // Carrega instrucoes para diferentes enderecos
    for (int i = 0; i < addr_ranges.size(); i++) begin
      addr_imm = addr_ranges[i][11:0];
      tx = dut_txn::type_id::create($sformatf("addr_load_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      // Gera instrucoes LW (load word) e SW (store word) alternadas
      if (i % 2 == 0) begin
        // LW x3, offset(x1)
        tx.instr = {addr_imm, 5'b00001, 3'b010, 5'b00011, 7'b0000011};
      end else begin
        // SW x2, offset(x1)
        tx.instr = {addr_imm[11:5], 5'b00010, 5'b00001, 3'b010, addr_imm[4:0], 7'b0100011};
      end
      start_item(tx);
      finish_item(tx);
      inst_idx++;
    end

    // Executa
    tx = dut_txn::type_id::create("run_addrs");
    tx.kind = dut_txn::TXN_RUN;
    tx.run_cycles = 300 + addr_ranges.size() * 15;
    start_item(tx);
    finish_item(tx);
    end
  endtask
endclass

// Sequencia para testar operacoes mistas (read/write)
class dut_mixed_ops_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_mixed_ops_seq)

  function new(string name="dut_mixed_ops_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    int num_ops = 40;

    int inst_idx = 0;
    // Inicializa base x1 = 0
    tx = dut_txn::type_id::create("mixed_init_x1");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h000, 5'b00000, 3'b000, 5'b00001, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    // Inicializa x2 = 0x3C (dados base)
    tx = dut_txn::type_id::create("mixed_init_x2");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h03C, 5'b00000, 3'b000, 5'b00010, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    `uvm_info("MIXED_OPS_SEQ", $sformatf("Gerando %0d operacoes mistas (opcodes suportados)", num_ops), UVM_MEDIUM)

    for (int i = 0; i < num_ops; i++) begin
      tx = dut_txn::type_id::create($sformatf("mixed_load_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      
      // Alterna entre instrucoes suportadas pelo decoder/ALU/branch
      case (i % 6)
        0: begin // Load word (lw)
          logic [11:0] imm = $urandom_range(0, 252);
          tx.instr = {imm, 5'b00001, 3'b010, (($urandom_range(1,31)) & 5'h1f), 7'b0000011};
        end
        1: begin // Store word (sw)
          logic [11:0] imm = $urandom_range(0, 252);
          tx.instr = {imm[11:5], 5'b00010, 5'b00001, 3'b010, imm[4:0], 7'b0100011};
        end
        2: begin // ADD or SUB (R-type)
          bit do_sub = ($urandom_range(0,1) == 1);
          tx.instr = {do_sub ? 7'b0100000 : 7'b0000000, (($urandom_range(1,31)) & 5'h1f), (($urandom_range(1,31)) & 5'h1f), 3'b000, (($urandom_range(1,31)) & 5'h1f), 7'b0110011};
        end
        3: begin // AND / OR / SLT (R-type)
          case ($urandom_range(0,2))
            0: tx.instr = {7'b0000000, (($urandom_range(1,31)) & 5'h1f), (($urandom_range(1,31)) & 5'h1f), 3'b111, (($urandom_range(1,31)) & 5'h1f), 7'b0110011}; // AND
            1: tx.instr = {7'b0000000, (($urandom_range(1,31)) & 5'h1f), (($urandom_range(1,31)) & 5'h1f), 3'b110, (($urandom_range(1,31)) & 5'h1f), 7'b0110011}; // OR
            default: tx.instr = {7'b0000000, (($urandom_range(1,31)) & 5'h1f), (($urandom_range(1,31)) & 5'h1f), 3'b010, (($urandom_range(1,31)) & 5'h1f), 7'b0110011}; // SLT
          endcase
        end
        4: begin // ADDI (I-type, 12-bit signed)
          logic signed [11:0] imm = $urandom_range(-2048, 2047);
          tx.instr = {imm, (($urandom_range(1,31)) & 5'h1f), 3'b000, (($urandom_range(1,31)) & 5'h1f), 7'b0010011};
        end
        5: begin // BEQ (B-type) com offset pequeno, alinhado
          logic signed [12:0] imm_b;
          imm_b = $urandom_range(-32, 32);
          // monta imm[12|10:5|4:1|11]
          tx.instr = {imm_b[12], imm_b[10:5], (($urandom_range(1,31)) & 5'h1f), (($urandom_range(1,31)) & 5'h1f), 3'b000, imm_b[4:1], imm_b[11], 7'b1100011};
        end
      endcase
      
      start_item(tx);
      finish_item(tx);
      inst_idx++;
    end

    // Executa
    tx = dut_txn::type_id::create("run_mixed");
    tx.kind = dut_txn::TXN_RUN;
    tx.run_cycles = 350 + num_ops * 15;
    start_item(tx);
    finish_item(tx);
    end
  endtask
endclass

// Sequencia para teste de stress com operacoes intensivas
class dut_stress_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_stress_seq)

  function new(string name="dut_stress_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    int num_stress = 50;

    `uvm_info("STRESS_SEQ", "Iniciando teste de stress", UVM_MEDIUM)

    for (int i = 0; i < num_stress; i++) begin
      tx = dut_txn::type_id::create($sformatf("stress_%0d", i));
      
      if (!tx.randomize() with {
        kind == dut_txn::TXN_RUN;
        run_cycles inside {[30:100]};
      }) begin
        `uvm_error("STRESS_SEQ", "Falha ao randomizar")
      end
      
      start_item(tx);
      finish_item(tx);
    end

    end
  endtask
endclass

// Sequencia direcionada para cobrir bins de endereco/dado com opcodes suportados
class dut_coverage_boost_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_coverage_boost_seq)

  function new(string name="dut_coverage_boost_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    int inst_idx = 0;

    // Lista de enderecos (bytes) alinhados: cobre zero_page, mid, stack, heap, boundaries
    int unsigned addr_list[] = '{0, 12, 128, 252, 64, 200};

    // Dados para cobrir bins de mem_wdata
    bit [31:0] data_list[] = '{
      32'h00000000, // zero
      32'hFFFFFFFF, // all ones
      32'h7FFFFFFF, // max_pos
      32'h80000000, // max_neg
      32'hAAAAAAAA, // alt1
      32'h55555555, // alt2
      32'h000003E8, // small_pos (1000)
      32'hFFFFFF38, // small_neg (-200)
      32'h7F800000, // +inf
      32'hFF800000, // -inf
      32'h7FC00000  // NaN
    };

    `uvm_info("COV_BOOST", "Gerando escrita/leitura dirigida para cobertura", UVM_MEDIUM)

    // Inicializa base x1 = 0
    tx = dut_txn::type_id::create("cov_init_x1");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_idx * 4;
    tx.instr = {12'h000, 5'b00000, 3'b000, 5'b00001, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_idx++;

    // Para cada par endereco/dado, gera LUI+ADDI para carregar e SW para escrever; depois LW para ler
    for (int i = 0; i < addr_list.size() && i < data_list.size(); i++) begin
      logic [31:0] val;
      logic [11:0] imm12;
      int unsigned addr = addr_list[i];
      val = data_list[i];
      imm12 = val[11:0];

      // LUI x2, upper
      tx = dut_txn::type_id::create($sformatf("cov_lui_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {val[31:12], 5'b00010, 7'b0110111};
      start_item(tx);
      finish_item(tx);
      inst_idx++;

      // ADDI x2, x2, low
      tx = dut_txn::type_id::create($sformatf("cov_addi_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {imm12, 5'b00010, 3'b000, 5'b00010, 7'b0010011};
      start_item(tx);
      finish_item(tx);
      inst_idx++;

      // SW x2, addr(x1)
      tx = dut_txn::type_id::create($sformatf("cov_sw_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {addr[11:5], 5'b00010, 5'b00001, 3'b010, addr[4:0], 7'b0100011};
      start_item(tx);
      finish_item(tx);
      inst_idx++;

      // LW x3, addr(x1) (gera mem_read)
      tx = dut_txn::type_id::create($sformatf("cov_lw_%0d", i));
      tx.kind = dut_txn::TXN_LOAD;
      tx.addr_inst = inst_idx * 4;
      tx.instr = {addr[11:0], 5'b00001, 3'b010, 5'b00011, 7'b0000011};
      start_item(tx);
      finish_item(tx);
      inst_idx++;
    end

    // Executa o programa gerado
    tx = dut_txn::type_id::create("run_cov_boost");
    tx.kind = dut_txn::TXN_RUN;
    tx.run_cycles = 400 + inst_idx * 5;
    start_item(tx);
    finish_item(tx);
    end
  endtask
endclass

// Sequencia CRV com distribuicao inteligente de enderecos/dados
class dut_smart_random_seq extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_smart_random_seq)

  // Configuracoes (podem vir do config_db)
  int unsigned program_len = 64;
  int unsigned run_cycles  = 400;

  function new(string name="dut_smart_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    begin
    dut_txn tx;
    int unsigned inst_addr = 0;
    int unsigned addr_imm;
    bit do_store;
    bit aligned;
    int signed data_imm;
    logic [11:0] imm12;

    // Permite sobrescrever via config_db
    void'(uvm_config_db#(int unsigned)::get(m_sequencer, "", "smart_program_len", program_len));
    void'(uvm_config_db#(int unsigned)::get(m_sequencer, "", "smart_run_cycles", run_cycles));

    if (program_len > 64)
      program_len = 64;

    `uvm_info("SMART_SEQ", $sformatf("Gerando programa CRV com %0d instrucoes", program_len), UVM_MEDIUM)

    // Inicializa base x1 = 0
    tx = dut_txn::type_id::create("smart_init_x1");
    tx.kind = dut_txn::TXN_LOAD;
    tx.addr_inst = inst_addr * 4;
    tx.instr = {12'h000, 5'b00000, 3'b000, 5'b00001, 7'b0010011};
    start_item(tx);
    finish_item(tx);
    inst_addr++;

    // Gera um programa pequeno com LW/SW/ADDI (opcodes suportados) e enderecos alinhados
    while (inst_addr < program_len) begin
      // Endereco imediato com distribuicao por regioes
      if (!std::randomize(addr_imm, aligned, do_store) with {
        addr_imm inside {[0:252]};
        aligned == 1;
        addr_imm[1:0] == 2'b00;
        do_store dist {1:/50, 0:/50};
        addr_imm dist {
          [0:15]   :/ 20,
          [16:127] :/ 20,
          [128:191]:/ 20,
          [192:255]:/ 20,
          0        :/ 5,
          255      :/ 5,
          128      :/ 5,
          [64:67]  :/ 5
        };
      }) begin
        `uvm_error("SMART_SEQ", "Falha ao randomizar endereco")
        break;
      end

      // Para stores, insere ADDI para carregar dado simples (12b, opcodes suportados)
      if (do_store && (inst_addr + 1 < program_len)) begin
        logic [11:0] imm_sw;
        if (!std::randomize(data_imm) with {
          data_imm inside {[-2048:-1], [0:2047]};
          data_imm dist {
            0        :/ 12,
            1        :/ 10,
            5        :/ 10,
            10       :/ 10,
            100      :/ 8,
            200      :/ 8,
            255      :/ 6,
            -1       :/ 10,
            -10      :/ 8,
            -100     :/ 8,
            [-200:-2] :/ 10,
            [256:1024] :/ 6,
            [1025:2047]:/ 6
          };
        }) begin
          `uvm_error("SMART_SEQ", "Falha ao randomizar dado")
        end

        imm12 = data_imm[11:0];

        // ADDI x2, x0, imm
        tx = dut_txn::type_id::create($sformatf("smart_addi_%0d", inst_addr));
        tx.kind = dut_txn::TXN_LOAD;
        tx.addr_inst = inst_addr * 4;
        tx.instr = {imm12, 5'b00000, 3'b000, 5'b00010, 7'b0010011};
        start_item(tx);
        finish_item(tx);
        inst_addr++;

        // SW x2, addr_imm(x1)
        tx = dut_txn::type_id::create($sformatf("smart_sw_%0d", inst_addr));
        tx.kind = dut_txn::TXN_LOAD;
        tx.addr_inst = inst_addr * 4;
        imm_sw = addr_imm[11:0];
        tx.instr = {imm_sw[11:5], 5'b00010, 5'b00001, 3'b010, imm_sw[4:0], 7'b0100011};
        start_item(tx);
        finish_item(tx);
        inst_addr++;
      end
      else begin
        // LW rd, addr_imm(x1)
        tx = dut_txn::type_id::create($sformatf("smart_lw_%0d", inst_addr));
        tx.kind = dut_txn::TXN_LOAD;
        tx.addr_inst = inst_addr * 4;
        tx.instr = {addr_imm[11:0], 5'b00001, 3'b010, (($urandom_range(1,31)) & 5'h1f), 7'b0000011};
        start_item(tx);
        finish_item(tx);
        inst_addr++;
      end
    end

    // Executa para processar as instrucoes
    tx = dut_txn::type_id::create("run_smart");
    tx.kind = dut_txn::TXN_RUN;
    tx.run_cycles = run_cycles;
    start_item(tx);
    finish_item(tx);
    end
  endtask
endclass

// Sequencia principal estendida que combina todas
class dut_extended_sequence extends uvm_sequence #(dut_txn);
  `uvm_object_utils(dut_extended_sequence)

  dut_sequence           base_seq;
  dut_data_pattern_seq   data_seq;
  dut_addr_sweep_seq     addr_seq;
  dut_mixed_ops_seq      mixed_seq;
  dut_stress_seq         stress_seq;
  dut_smart_random_seq   smart_seq;
  dut_coverage_boost_seq cov_boost_seq;

  function new(string name="dut_extended_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit run_basic_test = 1;
    bit run_crv_test   = 1;
    bit run_stress_test = 1;
    bit parallel_sequences = 0;
    bit run_cov_boost = 1;

    void'(uvm_config_db#(bit)::get(m_sequencer, "", "run_basic_test", run_basic_test));
    void'(uvm_config_db#(bit)::get(m_sequencer, "", "run_crv_test", run_crv_test));
    void'(uvm_config_db#(bit)::get(m_sequencer, "", "run_stress_test", run_stress_test));
    void'(uvm_config_db#(bit)::get(m_sequencer, "", "parallel_sequences", parallel_sequences));
    void'(uvm_config_db#(bit)::get(m_sequencer, "", "run_cov_boost", run_cov_boost));

    `uvm_info("EXT_SEQ", "========== INICIANDO TESTE ESTENDIDO ==========", UVM_LOW)

    // Sequencia base (programa original)
    if (run_basic_test) begin
      base_seq = dut_sequence::type_id::create("base_seq");
      base_seq.start(m_sequencer);
    end

    if (parallel_sequences) begin
      // Executa CRV/Stress em paralelo (sequencer arbitra)
      fork
        begin
          if (run_crv_test) begin
            data_seq = dut_data_pattern_seq::type_id::create("data_seq");
            data_seq.start(m_sequencer);
          end
        end
        begin
          if (run_crv_test) begin
            addr_seq = dut_addr_sweep_seq::type_id::create("addr_seq");
            addr_seq.start(m_sequencer);
          end
        end
        begin
          if (run_crv_test) begin
            mixed_seq = dut_mixed_ops_seq::type_id::create("mixed_seq");
            mixed_seq.start(m_sequencer);
          end
        end
        begin
          if (run_crv_test) begin
            smart_seq = dut_smart_random_seq::type_id::create("smart_seq");
            smart_seq.start(m_sequencer);
          end
        end
        begin
          if (run_stress_test) begin
            stress_seq = dut_stress_seq::type_id::create("stress_seq");
            stress_seq.start(m_sequencer);
          end
        end
        begin
          if (run_cov_boost) begin
            cov_boost_seq = dut_coverage_boost_seq::type_id::create("cov_boost_seq");
            cov_boost_seq.start(m_sequencer);
          end
        end
      join
    end
    else begin
      // Sequencia de padroes de dados
      if (run_crv_test) begin
        data_seq = dut_data_pattern_seq::type_id::create("data_seq");
        data_seq.start(m_sequencer);
      end

      // Sequencia de varredura de enderecos
      if (run_crv_test) begin
        addr_seq = dut_addr_sweep_seq::type_id::create("addr_seq");
        addr_seq.start(m_sequencer);
      end

      // Sequencia de operacoes mistas
      if (run_crv_test) begin
        mixed_seq = dut_mixed_ops_seq::type_id::create("mixed_seq");
        mixed_seq.start(m_sequencer);
      end

      // Sequencia CRV inteligente
      if (run_crv_test) begin
        smart_seq = dut_smart_random_seq::type_id::create("smart_seq");
        smart_seq.start(m_sequencer);
      end

      // Sequencia de stress
      if (run_stress_test) begin
        stress_seq = dut_stress_seq::type_id::create("stress_seq");
        stress_seq.start(m_sequencer);
      end

      if (run_cov_boost) begin
        cov_boost_seq = dut_coverage_boost_seq::type_id::create("cov_boost_seq");
        cov_boost_seq.start(m_sequencer);
      end
    end

    `uvm_info("EXT_SEQ", "========== TESTE ESTENDIDO CONCLUIDO ==========", UVM_LOW)
  endtask
endclass

`endif // DUT_SEQ_LIB_SV
