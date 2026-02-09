module mem_wb_reg #(parameter bits = 32)(
    input CLK, rst,
    // Sinais do estÃ¡gio MEM
    input [bits-1:0] read_data_mem, alu_result_mem, PC_plus_4_mem,
    input [bits-1:0] instruction_mem,
    // Sinais de controle MEM
    input RegWrite_mem, ResultSrc_mem,
    input FPURegWrite_mem, FPUResultSrc_mem, FPUOp_mem,
    
    // SaÃ­das para estÃ¡gio WB
    output reg [bits-1:0] read_data_wb, alu_result_wb, PC_plus_4_wb,
    output reg [bits-1:0] instruction_wb,
    output reg RegWrite_wb, ResultSrc_wb,
    output reg FPURegWrite_wb, FPUResultSrc_wb, FPUOp_wb
);
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            read_data_wb <= 0;
            alu_result_wb <= 0;
            PC_plus_4_wb <= 0;
            instruction_wb <= 0;
            RegWrite_wb <= 0;
            ResultSrc_wb <= 0;
            FPURegWrite_wb <= 0;
            FPUResultSrc_wb <= 0;
            FPUOp_wb <= 0;
        end else begin
            read_data_wb <= read_data_mem;
            alu_result_wb <= alu_result_mem;
            PC_plus_4_wb <= PC_plus_4_mem;
            instruction_wb <= instruction_mem;
            RegWrite_wb <= RegWrite_mem;
            ResultSrc_wb <= ResultSrc_mem;
            FPURegWrite_wb <= FPURegWrite_mem;
            FPUResultSrc_wb <= FPUResultSrc_mem;
            FPUOp_wb <= FPUOp_mem;
        end
    end
endmodule