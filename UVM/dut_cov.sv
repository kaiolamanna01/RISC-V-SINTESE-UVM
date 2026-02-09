//classe dut_cov
// Cobertura funcional do DUT.
// Recebe transacoes do monitor via analysis_export.
/*
| Categoria                 | Descricao                                 |
| ------------------------- | ----------------------------------------- |
| `mem_we`                  | Escritas em memoria de dados             |
| `mem_read`                | Leituras em memoria de dados             |
| `mem_addr[31:2]`          | Faixas de endereco acessadas             |
| `mem_rdata`               | Dados lidos (zero vs nao-zero)           |
| `cross mem_we, mem_addr`  | Escritas por faixa de endereco           |
| `cross mem_read, mem_addr`| Leituras por faixa de endereco           |
*/
class dut_cov extends uvm_subscriber#(dut_txn);
  `uvm_component_utils(dut_cov)

  // Mirror fields from the transaction
  bit        mem_we;
  bit        mem_read;
  bit [31:0] mem_addr;
  bit [31:0] mem_wdata;
  bit [31:0] mem_rdata;

  // --- Covergroup ---
  covergroup dut_cg;
    option.per_instance = 1;
    coverpoint mem_we { bins we_set = {1}; bins we_clr = {0}; }
    coverpoint mem_read { bins rd_set = {1}; bins rd_clr = {0}; }

    // Tipo de operacao (memoria)
    mem_op: coverpoint {mem_we, mem_read} {
      bins write = {2'b10};
      bins read  = {2'b01};
      bins both  = {2'b11};
      bins none  = {2'b00};
    }

    // Endereco em palavras (memoria de 64 words -> 0..63)
    coverpoint mem_addr[31:2] {
      bins zero_page  = {[0:3]};
      bins mid_area   = {[4:31]};
      bins stack_area = {[32:47]};
      bins heap_area  = {[48:63]};
      bins boundaries = {0, 3, 32, 63};
      ignore_bins out_of_range = {[64:$]};
    }

    // Alinhamento do endereco
    mem_addr_align: coverpoint mem_addr[1:0] {
      bins aligned    = {2'b00};
      bins misaligned = {[2'b01:2'b11]};
    }

    // Tipos de dados relevantes
    coverpoint mem_wdata {
      bins zero        = {32'h00000000};
      bins all_ones    = {32'hFFFFFFFF};
      bins max_pos     = {32'h7FFFFFFF};
      bins max_neg     = {32'h80000000};
      bins alt1        = {32'hAAAAAAAA};
      bins alt2        = {32'h55555555};
      bins small_pos   = {[32'h00000001:32'h000003E8]}; // 1..1000
      bins small_neg   = {[32'hFFFFFF38:32'hFFFFFFFF]}; // -200..-1
      bins float_specials = {
        32'h00000000, // +0.0
        32'h80000000, // -0.0
        32'h7F800000, // +inf
        32'hFF800000, // -inf
        32'h7FC00000  // NaN
      };
      bins other       = default;
    }

    coverpoint mem_rdata {
      bins zero = {32'h00000000};
      bins nonzero = default;
    }

    mem_we_x_addr    : cross mem_we, mem_addr;
    mem_read_x_addr  : cross mem_read, mem_addr;
    mem_op_x_addr    : cross mem_op, mem_addr_align {
      bins read_aligned    = binsof(mem_op.read)  && binsof(mem_addr_align.aligned);
      bins write_unaligned = binsof(mem_op.write) && binsof(mem_addr_align.misaligned);
    }
    mem_we_x_wdata   : cross mem_we, mem_wdata;
    mem_read_x_rdata : cross mem_read, mem_rdata;
  endgroup

  // --- Construtor ---
  function new(string name, uvm_component parent);
    super.new(name, parent);
    dut_cg = new();
  endfunction

  // --- write() chamado automaticamente quando monitor publica ---
  function void write(dut_txn t);
    if (t.kind != dut_txn::TXN_MEM_EVT)
      return;

    mem_we    = t.mem_we;
    mem_read  = t.mem_read;
    mem_addr  = t.mem_addr;
    mem_wdata = t.mem_wdata;
    mem_rdata = t.mem_rdata;
    dut_cg.sample();
  endfunction

  // Utilitarios para o ambiente consultar cobertura
  function real get_total_coverage();
    return dut_cg.get_coverage();
  endfunction

  function void report_uncovered_bins();
    `uvm_info("COV", "Detalhamento de bins indisponivel nesta versao (covergroup sem print).", UVM_LOW)
  endfunction

  function void get_mem_cov(output real total_cov,
                            output real mem_we_cov,
                            output real mem_read_cov,
                            output real mem_addr_cov,
                            output real mem_addr_align_cov,
                            output real mem_op_cov,
                            output real mem_wdata_cov,
                            output real mem_rdata_cov,
                            output real mem_we_x_addr_cov,
                            output real mem_read_x_addr_cov,
                            output real mem_op_x_addr_cov,
                            output real mem_we_x_wdata_cov,
                            output real mem_read_x_rdata_cov);
    total_cov           = dut_cg.get_coverage();
    mem_we_cov          = dut_cg.mem_we.get_coverage();
    mem_read_cov        = dut_cg.mem_read.get_coverage();
    mem_addr_cov        = dut_cg.mem_addr.get_coverage();
    mem_addr_align_cov  = dut_cg.mem_addr_align.get_coverage();
    mem_op_cov          = dut_cg.mem_op.get_coverage();
    mem_wdata_cov       = dut_cg.mem_wdata.get_coverage();
    mem_rdata_cov       = dut_cg.mem_rdata.get_coverage();
    mem_we_x_addr_cov   = dut_cg.mem_we_x_addr.get_coverage();
    mem_read_x_addr_cov = dut_cg.mem_read_x_addr.get_coverage();
    mem_op_x_addr_cov   = dut_cg.mem_op_x_addr.get_coverage();
    mem_we_x_wdata_cov  = dut_cg.mem_we_x_wdata.get_coverage();
    mem_read_x_rdata_cov= dut_cg.mem_read_x_rdata.get_coverage();
  endfunction

endclass

// --------------------------------------------------
// Cobertura funcional de execucao (PC/instr/controle)
// --------------------------------------------------
class dut_exec_cov extends uvm_subscriber#(dut_exec_txn);
  `uvm_component_utils(dut_exec_cov)

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

  covergroup exec_cg;
    option.per_instance = 1;

    // PC em palavras (faixas locais para referencia rapida)
  pc_cp: coverpoint pc[11:2] {
      bins low_region  = {[0:63]};
      bins mid_region  = {[64:255]};
      bins high_region = {[256:1023]};
    }

    // Opcode basico RISC-V
  opcode_cp: coverpoint instr[6:0] {
      bins r_type  = {7'b0110011};
      bins i_type  = {7'b0010011};
      bins load    = {7'b0000011};
      bins store   = {7'b0100011};
      bins branch  = {7'b1100011};
      bins jal     = {7'b1101111};
      bins jalr    = {7'b1100111};
      bins lui     = {7'b0110111};
      bins auipc   = {7'b0010111};
      bins other   = default;
    }

  branch_ctrl_cp: coverpoint branch_ctrl { bins off = {0}; bins on = {1}; }
  branch_taken_cp: coverpoint branch_taken { bins not_taken = {0}; bins taken = {1}; }
  jump_cp: coverpoint jump { bins no = {0}; bins yes = {1}; }

  regwrite_cp: coverpoint regwrite_wb { bins off = {0}; bins on = {1}; }
  fpuregwrite_cp: coverpoint fpuregwrite_wb { bins off = {0}; bins on = {1}; }
  stall_cp: coverpoint stall { bins off = {0}; bins on = {1}; }

  rd_cp: coverpoint rd_wb {
      bins x0 = {5'd0};
      bins x1_x7 = {[1:7]};
      bins x8_x15 = {[8:15]};
      bins x16_x31 = {[16:31]};
    }

  forwardA_cp: coverpoint forwardA { bins f00 = {2'b00}; bins f01 = {2'b01}; bins f10 = {2'b10}; bins f11 = {2'b11}; }
  forwardB_cp: coverpoint forwardB { bins f00 = {2'b00}; bins f01 = {2'b01}; bins f10 = {2'b10}; bins f11 = {2'b11}; }
  forwardFA_cp: coverpoint forwardFA { bins f00 = {2'b00}; bins f01 = {2'b01}; bins f10 = {2'b10}; bins f11 = {2'b11}; }
  forwardFB_cp: coverpoint forwardFB { bins f00 = {2'b00}; bins f01 = {2'b01}; bins f10 = {2'b10}; bins f11 = {2'b11}; }

    // Dados observados (zero vs nao-zero)
  wb_data_x_cp: coverpoint wb_data_x { bins zero = {32'h00000000}; bins nonzero = default; }
  wb_data_f_cp: coverpoint wb_data_f { bins zero = {32'h00000000}; bins nonzero = default; }
  alu_result_cp: coverpoint alu_result { bins zero = {32'h00000000}; bins nonzero = default; }
  fpu_result_cp: coverpoint fpu_result { bins zero = {32'h00000000}; bins nonzero = default; }

  branch_x_taken : cross branch_ctrl_cp, branch_taken_cp;
  branch_or_jump : cross branch_ctrl_cp, jump_cp;
  regwrite_x_rd  : cross regwrite_cp, rd_cp;
  stall_x_fwdA   : cross stall_cp, forwardA_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    exec_cg = new();
  endfunction

  function void write(dut_exec_txn t);
    pc             = t.pc;
    instr          = t.instr;
    branch_ctrl    = t.branch_ctrl;
    branch_taken   = t.branch_taken;
    jump           = t.jump;
    alu_result     = t.alu_result;
    fpu_result     = t.fpu_result;
    wb_data_x      = t.wb_data_x;
    wb_data_f      = t.wb_data_f;
    rd_wb          = t.rd_wb;
    regwrite_wb    = t.regwrite_wb;
    fpuregwrite_wb = t.fpuregwrite_wb;
    forwardA       = t.forwardA;
    forwardB       = t.forwardB;
    forwardFA      = t.forwardFA;
    forwardFB      = t.forwardFB;
    stall          = t.stall;
    exec_cg.sample();
  endfunction

  function void get_exec_cov(output real exec_total_cov,
                             output real pc_cov,
                             output real opcode_cov,
                             output real branch_ctrl_cov,
                             output real branch_taken_cov,
                             output real jump_cov,
                             output real regwrite_cov,
                             output real fpuregwrite_cov,
                             output real stall_cov,
                             output real rd_cov,
                             output real forwardA_cov,
                             output real forwardB_cov,
                             output real forwardFA_cov,
                             output real forwardFB_cov,
                             output real wb_data_x_cov,
                             output real wb_data_f_cov,
                             output real alu_result_cov,
                             output real fpu_result_cov,
                             output real branch_x_taken_cov,
                             output real branch_or_jump_cov,
                             output real regwrite_x_rd_cov,
                             output real stall_x_fwdA_cov);
    exec_total_cov     = exec_cg.get_coverage();
    pc_cov             = exec_cg.pc_cp.get_coverage();
    opcode_cov         = exec_cg.opcode_cp.get_coverage();
    branch_ctrl_cov    = exec_cg.branch_ctrl_cp.get_coverage();
    branch_taken_cov   = exec_cg.branch_taken_cp.get_coverage();
    jump_cov           = exec_cg.jump_cp.get_coverage();
    regwrite_cov       = exec_cg.regwrite_cp.get_coverage();
    fpuregwrite_cov    = exec_cg.fpuregwrite_cp.get_coverage();
    stall_cov          = exec_cg.stall_cp.get_coverage();
    rd_cov             = exec_cg.rd_cp.get_coverage();
    forwardA_cov       = exec_cg.forwardA_cp.get_coverage();
    forwardB_cov       = exec_cg.forwardB_cp.get_coverage();
    forwardFA_cov      = exec_cg.forwardFA_cp.get_coverage();
    forwardFB_cov      = exec_cg.forwardFB_cp.get_coverage();
    wb_data_x_cov      = exec_cg.wb_data_x_cp.get_coverage();
    wb_data_f_cov      = exec_cg.wb_data_f_cp.get_coverage();
    alu_result_cov     = exec_cg.alu_result_cp.get_coverage();
    fpu_result_cov     = exec_cg.fpu_result_cp.get_coverage();
    branch_x_taken_cov = exec_cg.branch_x_taken.get_coverage();
    branch_or_jump_cov = exec_cg.branch_or_jump.get_coverage();
    regwrite_x_rd_cov  = exec_cg.regwrite_x_rd.get_coverage();
    stall_x_fwdA_cov   = exec_cg.stall_x_fwdA.get_coverage();
  endfunction
endclass