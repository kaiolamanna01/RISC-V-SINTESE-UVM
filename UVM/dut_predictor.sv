//classe dut_predictor
class dut_predictor extends uvm_component;
  `uvm_component_utils(dut_predictor)

  uvm_analysis_imp#(dut_txn, dut_predictor) stim_imp;
  uvm_analysis_port#(dut_txn) analysis_port;

  dut_cfg cfg;

  // Memória de referência (shadow) - 64 palavras
  logic [31:0] mem_shadow [0:63];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    void'(uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg));

    stim_imp = new("stim_imp", this);
    analysis_port = new("analysis_port", this);

    // Deve espelhar a inicialização do DUT em CPU/data_memory.v
    mem_shadow[0] = 32'h0001199A;
    mem_shadow[1] = 32'h00028000;
    mem_shadow[2] = 32'hFFFC4000;
    mem_shadow[3] = 32'h00042000;
    mem_shadow[4] = 32'h00000000;
    mem_shadow[5] = 32'h00000000;
    for (int i = 6; i < 64; i++) begin
      mem_shadow[i] = 32'h00000000;
    end
    `uvm_info("PREDICTOR", "mem_shadow inicializada", UVM_LOW)
  endfunction

  function void write(dut_txn tx);
    dut_txn expected_txn;
    int unsigned index;

    if (tx.kind != dut_txn::TXN_MEM_EVT)
      return;

    expected_txn = dut_txn::type_id::create("expected_txn");
    expected_txn.kind      = dut_txn::TXN_MEM_EVT;
    expected_txn.mem_we    = tx.mem_we;
    expected_txn.mem_read  = tx.mem_read;
    expected_txn.mem_addr  = tx.mem_addr;
    expected_txn.mem_wdata = tx.mem_wdata;

    index = tx.mem_addr[31:2];

    if (tx.mem_we) begin
      if (index < 64)
        mem_shadow[index] = tx.mem_wdata;
      else
        `uvm_warning("PREDICTOR", $sformatf("Endereco fora do range: %0h", tx.mem_addr))
    end

    if (tx.mem_read) begin
      if (index < 64)
        expected_txn.mem_rdata = mem_shadow[index];
      else
        expected_txn.mem_rdata = 32'h00000000;
    end else begin
      expected_txn.mem_rdata = tx.mem_rdata;
    end

    analysis_port.write(expected_txn);
  endfunction
endclass


