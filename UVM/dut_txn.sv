class dut_txn extends uvm_sequence_item;
  `uvm_object_utils(dut_txn)

  typedef enum {TXN_LOAD, TXN_RUN, TXN_MEM_EVT} dut_txn_kind_e;

  rand dut_txn_kind_e kind;

  // Estímulos para carregamento de instruções
  rand bit [31:0] addr_inst;
  rand bit [31:0] instr;

  // Controle de execução
  rand int unsigned run_cycles;

  // --------------------------------------------------
  // CRV - Constraints
  // --------------------------------------------------
  // Endereço alinhado em palavra
  constraint c_addr_align { addr_inst[1:0] == 2'b00; }

  // Faixa de ciclos de execução (pode ser sobrescrita com inline constraints)
  constraint c_run_cycles { soft run_cycles inside {[10:2000]}; }

  // Instrução sempre definida
  constraint c_instr_range { instr inside {[32'h0000_0000:32'hFFFF_FFFF]}; }

  // Campos observados de memória
  bit        mem_we;
  bit        mem_read;
  bit [31:0] mem_addr;
  bit [31:0] mem_wdata;
  bit [31:0] mem_rdata;

  function new(string name="dut_txn");
    super.new(name);
  endfunction

  // Metodo copy obrigatorio para propagacao correta
  function void copy(uvm_object rhs);
    dut_txn tx;
    if (!$cast(tx, rhs)) begin
      `uvm_warning("COPY_FAIL", "Falha ao fazer cast em dut_txn::copy")
      return;
    end
    this.kind       = tx.kind;
    this.addr_inst  = tx.addr_inst;
    this.instr      = tx.instr;
    this.run_cycles = tx.run_cycles;
    this.mem_we     = tx.mem_we;
    this.mem_read   = tx.mem_read;
    this.mem_addr   = tx.mem_addr;
    this.mem_wdata  = tx.mem_wdata;
    this.mem_rdata  = tx.mem_rdata;
  endfunction

  function string convert2string();
    return $sformatf("kind=%0d addr_inst=%0h instr=%0h run_cycles=%0d | mem_we=%0b mem_read=%0b mem_addr=%0h mem_wdata=%0h mem_rdata=%0h",
                     kind, addr_inst, instr, run_cycles, mem_we, mem_read, mem_addr, mem_wdata, mem_rdata);
  endfunction
endclass

class dut_exec_txn extends uvm_sequence_item;
  `uvm_object_utils(dut_exec_txn)

  bit [31:0] pc;
  bit [31:0] instr;
  bit        branch_ctrl;
  bit        branch_taken;
  bit        jump;
  bit [31:0] alu_result;
  bit [31:0] fpu_result;
  bit [31:0] wb_data_x;
  bit [31:0] wb_data_f;
  bit [4:0]  rd_wb;
  bit        regwrite_wb;
  bit        fpuregwrite_wb;
  bit [1:0]  forwardA;
  bit [1:0]  forwardB;
  bit [1:0]  forwardFA;
  bit [1:0]  forwardFB;
  bit        stall;

  function new(string name="dut_exec_txn");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("pc=%0h instr=%0h branch=%0b taken=%0b jump=%0b alu=%0h fpu=%0h rd=%0d wb_x=%0h wb_f=%0h regw=%0b fpw=%0b fwdA=%0b fwdB=%0b fwdFA=%0b fwdFB=%0b stall=%0b",
                     pc, instr, branch_ctrl, branch_taken, jump, alu_result, fpu_result, rd_wb, wb_data_x, wb_data_f,
                     regwrite_wb, fpuregwrite_wb, forwardA, forwardB, forwardFA, forwardFB, stall);
  endfunction
endclass
