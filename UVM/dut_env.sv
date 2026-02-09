//classe dut_env
//=====================================================
// dut_env.sv
// Ambiente UVM generico com agent, scoreboard e (opcional) coverage
//=====================================================

class dut_env extends uvm_env;
  `uvm_component_utils(dut_env)

  // --------------------------------------------------
  // Subcomponentes
  // --------------------------------------------------
  dut_agent       agent;
  dut_scoreboard  sb;
  dut_cov         cov;   // opcional
  dut_exec_cov    exec_cov; // opcional

  dut_cfg         cfg;

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
    bit enable_cov = 1;
    super.build_phase(phase);

    void'(uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg));
    if (cfg != null)
      enable_cov = cfg.enable_cov;

    agent = dut_agent::type_id::create("agent", this);
    sb    = dut_scoreboard::type_id::create("sb", this);

    // Permite habilitar ou desabilitar coverage via config_db
    void'(uvm_config_db#(bit)::get(this, "", "enable_cov", enable_cov));

    if (enable_cov) begin
      cov = dut_cov::type_id::create("cov", this);
      exec_cov = dut_exec_cov::type_id::create("exec_cov", this);
      `uvm_info("ENV", "Coverage collector habilitado", UVM_LOW)
    end
    else begin
      `uvm_info("ENV", "Coverage collector desabilitado", UVM_LOW)
    end
  endfunction

  // --------------------------------------------------
  // Connect phase
  // --------------------------------------------------
  function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  // Conecta o trafego de referÃªncia (expected) do predictor -->  scoreboard
  agent.expected_port.connect(sb.expected_export);

  // Conecta o trafego observado (monitor) -->  scoreboard
  agent.observed_port.connect(sb.actual_export);

  // (Opcional) conecta o trafego observado ao coverage collector
  if (cov != null)
    agent.observed_port.connect(cov.analysis_export);

  if (exec_cov != null)
    agent.exec_observed_port.connect(exec_cov.analysis_export);
endfunction

  // Propaga cfg para subcomponentes (se existir)
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (cfg != null) begin
      uvm_config_db#(dut_cfg)::set(this, "agent", "cfg", cfg);
      uvm_config_db#(dut_cfg)::set(this, "sb", "cfg", cfg);
      if (cov != null)
        uvm_config_db#(dut_cfg)::set(this, "cov", "cfg", cfg);
      if (exec_cov != null)
        uvm_config_db#(dut_cfg)::set(this, "exec_cov", "cfg", cfg);
    end
  endfunction

  // Consolidated coverage report
  function void report_phase(uvm_phase phase);
    real mem_total;
    real mem_we;
    real mem_read;
    real mem_addr;
    real mem_addr_align;
    real mem_op;
    real mem_wdata;
    real mem_rdata;
    real mem_we_x_addr;
    real mem_read_x_addr;
    real mem_op_x_addr;
    real mem_we_x_wdata;
    real mem_read_x_rdata;
  real arch_total;

    real exec_total;
    real pc_cov;
    real opcode_cov;
    real branch_ctrl_cov;
    real branch_taken_cov;
    real jump_cov;
    real regwrite_cov;
    real fpuregwrite_cov;
    real stall_cov;
    real rd_cov;
    real forwardA_cov;
    real forwardB_cov;
    real forwardFA_cov;
    real forwardFB_cov;
    real wb_data_x_cov;
    real wb_data_f_cov;
    real alu_result_cov;
    real fpu_result_cov;
    real branch_x_taken_cov;
    real branch_or_jump_cov;
    real regwrite_x_rd_cov;
    real stall_x_fwdA_cov;

    if (cov != null)
      cov.get_mem_cov(mem_total, mem_we, mem_read, mem_addr, mem_addr_align, mem_op,
                      mem_wdata, mem_rdata, mem_we_x_addr, mem_read_x_addr,
                      mem_op_x_addr, mem_we_x_wdata, mem_read_x_rdata);

    if (exec_cov != null)
      exec_cov.get_exec_cov(exec_total, pc_cov, opcode_cov, branch_ctrl_cov,
                            branch_taken_cov, jump_cov, regwrite_cov,
                            fpuregwrite_cov, stall_cov, rd_cov, forwardA_cov,
                            forwardB_cov, forwardFA_cov, forwardFB_cov,
                            wb_data_x_cov, wb_data_f_cov, alu_result_cov,
                            fpu_result_cov, branch_x_taken_cov, branch_or_jump_cov,
                            regwrite_x_rd_cov, stall_x_fwdA_cov);

  arch_total = (mem_total + exec_total) / 2.0;

    `uvm_info("COV_SUM", $sformatf("Relatorio consolidado de cobertura\n  TOTAL ARQUITETURA  : %0.2f%%\n  MEM TOTAL          : %0.2f%%\n  mem_addr           : %0.2f%%\n  mem_wdata/mem_rdata : %0.2f%%/%0.2f%%\n  EXEC TOTAL          : %0.2f%%\n  opcode             : %0.2f%%\n  branch_taken       : %0.2f%%\n  stall              : %0.2f%%\n  forwardA/forwardB  : %0.2f%%/%0.2f%%", arch_total, mem_total, mem_addr, mem_wdata, mem_rdata, exec_total, opcode_cov, branch_taken_cov, stall_cov, forwardA_cov, forwardB_cov), UVM_NONE)
  endfunction

endclass

