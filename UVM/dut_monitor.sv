//classe dut_monitor
class dut_monitor extends uvm_component;
  `uvm_component_utils(dut_monitor)

  // Interface virtual
  virtual dut_if vif;

  dut_cfg cfg;

  // Porta de analise para o predictor
  uvm_analysis_port#(dut_txn) analysis_port;
  // Porta de analise para eventos de execucao
  uvm_analysis_port#(dut_exec_txn) exec_analysis_port;

  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
    exec_analysis_port = new("exec_analysis_port", this);
  endfunction

  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    void'(uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg));

    // Interface virtual
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Monitor nao recebeu a interface virtual")

  endfunction

  // --------------------------------------------------
  // run_phase
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
    dut_txn observed;
    dut_exec_txn exec_observed;

    forever begin
      @(posedge vif.clk);

      if (vif.rst)
        continue;

      if (vif.mem_we || vif.mem_read) begin
        observed = dut_txn::type_id::create("observed");
        observed.kind      = dut_txn::TXN_MEM_EVT;
        observed.mem_we    = vif.mem_we;
        observed.mem_read  = vif.mem_read;
        observed.mem_addr  = vif.mem_addr;
        observed.mem_wdata = vif.Dado;
        observed.mem_rdata = vif.mem_rdata;
        analysis_port.write(observed);
      end

      // Publica um evento de execucao a cada ciclo
      exec_observed = dut_exec_txn::type_id::create("exec_observed");
      exec_observed.pc            = vif.pc;
      exec_observed.instr         = vif.instr;
      exec_observed.branch_ctrl   = vif.branch_ctrl;
      exec_observed.branch_taken  = vif.branch_taken;
      exec_observed.jump          = vif.jump;
      exec_observed.alu_result    = vif.alu_result;
      exec_observed.fpu_result    = vif.fpu_result;
      exec_observed.wb_data_x     = vif.wb_data_x;
      exec_observed.wb_data_f     = vif.wb_data_f;
      exec_observed.rd_wb         = vif.rd_wb;
      exec_observed.regwrite_wb   = vif.regwrite_wb;
      exec_observed.fpuregwrite_wb= vif.fpuregwrite_wb;
      exec_observed.forwardA      = vif.forwardA;
      exec_observed.forwardB      = vif.forwardB;
      exec_observed.forwardFA     = vif.forwardFA;
      exec_observed.forwardFB     = vif.forwardFB;
      exec_observed.stall         = vif.stall;
      exec_analysis_port.write(exec_observed);
    end
  endtask
endclass















