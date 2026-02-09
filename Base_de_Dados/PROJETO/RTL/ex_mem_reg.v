module ex_mem_reg #(parameter bits = 32)(
    input CLK, rst,
    // Sinais do estágio EX
    input [bits-1:0] alu_result_ex, write_data_ex, PC_plus_4_ex,
    input [bits-1:0] instruction_ex,
    // Sinais de controle EX
    input RegWrite_ex, MemWrite_ex, ResultSrc_ex,
    input FPURegWrite_ex, FPUResultSrc_ex, FPUOp_ex,
    
    // Saídas para estágio MEM
    output reg [bits-1:0] alu_result_mem, write_data_mem, PC_plus_4_mem,
    output reg [bits-1:0] instruction_mem,
    output reg RegWrite_mem, MemWrite_mem, ResultSrc_mem,
    output reg FPURegWrite_mem, FPUResultSrc_mem, FPUOp_mem
);
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            alu_result_mem <= 0;
            write_data_mem <= 0;
            PC_plus_4_mem <= 0;
            instruction_mem <= 0;
            RegWrite_mem <= 0;
            MemWrite_mem <= 0;
            ResultSrc_mem <= 0;
            FPURegWrite_mem <= 0;
            FPUResultSrc_mem <= 0;
            FPUOp_mem <= 0;
        end else begin
            alu_result_mem <= alu_result_ex;
            write_data_mem <= write_data_ex;
            PC_plus_4_mem <= PC_plus_4_ex;
            instruction_mem <= instruction_ex;
            RegWrite_mem <= RegWrite_ex;
            MemWrite_mem <= MemWrite_ex;
            ResultSrc_mem <= ResultSrc_ex;
            FPURegWrite_mem <= FPURegWrite_ex;
            FPUResultSrc_mem <= FPUResultSrc_ex;
            FPUOp_mem <= FPUOp_ex;
        end
    end
endmodule