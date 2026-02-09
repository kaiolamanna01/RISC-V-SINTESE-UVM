//classe tb_top
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_package::*;

module tb_top;

  logic clk, rst, clk_load;
  dut_if dut_if_inst(clk, rst, clk_load);

  // DUT real
  cpu u_dut(
    .CLK        (clk),
    .rst        (rst),
    .clk_load   (clk_load),
    .we         (dut_if_inst.we),
    .ADDR_INST  (dut_if_inst.ADDR_INST),
    .Instrucoes (dut_if_inst.Instrucoes),
    .Dado       (dut_if_inst.Dado),
    .mem_we     (dut_if_inst.mem_we),
    .mem_read   (dut_if_inst.mem_read),
    .mem_addr   (dut_if_inst.mem_addr),
    .mem_rdata  (dut_if_inst.mem_rdata),
    .pc         (dut_if_inst.pc),
    .instr      (dut_if_inst.instr),
    .branch_ctrl(dut_if_inst.branch_ctrl),
    .branch_taken(dut_if_inst.branch_taken),
    .jump       (dut_if_inst.jump),
    .alu_result (dut_if_inst.alu_result),
    .fpu_result (dut_if_inst.fpu_result),
    .wb_data_x  (dut_if_inst.wb_data_x),
    .wb_data_f  (dut_if_inst.wb_data_f),
    .rd_wb      (dut_if_inst.rd_wb),
    .regwrite_wb(dut_if_inst.regwrite_wb),
    .fpuregwrite_wb(dut_if_inst.fpuregwrite_wb),
    .forwardA   (dut_if_inst.forwardA),
    .forwardB   (dut_if_inst.forwardB),
    .forwardFA  (dut_if_inst.forwardFA),
    .forwardFB  (dut_if_inst.forwardFB),
    .stall      (dut_if_inst.stall)
  );

  // Clock/reset generation
  initial begin
    clk = 0;
    forever #5 begin
      if (!dut_if_inst.we)
        clk = ~clk;
      else
        clk = 1'b0;
    end
  end

  initial begin
    clk_load = 0;
    forever #5 clk_load = ~clk_load;
  end

  initial begin
    rst = 1;
    #10 rst = 0;
  end

  // Conecta o vif ao UVM
  initial begin
    uvm_config_db#(virtual dut_if)::set(null, "*", "vif", dut_if_inst);
    run_test("dut_test");

  end

endmodule

