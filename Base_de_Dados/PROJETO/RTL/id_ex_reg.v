module id_ex_reg #(parameter bits = 32)(
    input CLK, rst,
    // Sinais do estágio ID
    input [bits-1:0] PC_plus_4_id, read_data1_id, read_data2_id, imm_ext_id,
    input [bits-1:0] instruction_id,
    // Sinais de controle ID
    input RegWrite_id, ALUSrc_id, MemWrite_id, ResultSrc_id,
    input [1:0] ImmSrc_id,
    input [2:0] ALUControl_id,
    input FPURegWrite_id, FPUResultSrc_id, FPUOp_id,
    input [1:0] FPUControl_id,
    input [4:0] FPUSel_id,
    
    // Saídas para estágio EX
    output reg [bits-1:0] PC_plus_4_ex, read_data1_ex, read_data2_ex, imm_ext_ex,
    output reg [bits-1:0] instruction_ex,
    output reg RegWrite_ex, ALUSrc_ex, MemWrite_ex, ResultSrc_ex,
    output reg [1:0] ImmSrc_ex,
    output reg [2:0] ALUControl_ex,
    output reg FPURegWrite_ex, FPUResultSrc_ex, FPUOp_ex,
    output reg [1:0] FPUControl_ex,
    output reg [4:0] FPUSel_ex
);
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            // Reset todos os sinais
            PC_plus_4_ex <= 0; 
            read_data1_ex <= 0; 
            read_data2_ex <= 0; 
            imm_ext_ex <= 0;
            instruction_ex <= 0;
            RegWrite_ex <= 0; 
            ALUSrc_ex <= 0; 
            MemWrite_ex <= 0; 
            ResultSrc_ex <= 0;
            ImmSrc_ex <= 0; 
            ALUControl_ex <= 0;
            FPURegWrite_ex <= 0; 
            FPUResultSrc_ex <= 0; 
            FPUOp_ex <= 0;
            FPUControl_ex <= 0; 
            FPUSel_ex <= 0;
        end else begin
            // CORREÇÃO: Usar sinais de entrada (_id) em vez de (_if)
            PC_plus_4_ex <= PC_plus_4_id;
            read_data1_ex <= read_data1_id;
            read_data2_ex <= read_data2_id;
            imm_ext_ex <= imm_ext_id;
            instruction_ex <= instruction_id;
            
            // Pipeline dos sinais de controle
            RegWrite_ex <= RegWrite_id; 
            ALUSrc_ex <= ALUSrc_id; 
            MemWrite_ex <= MemWrite_id; 
            ResultSrc_ex <= ResultSrc_id;
            ImmSrc_ex <= ImmSrc_id; 
            ALUControl_ex <= ALUControl_id;
            FPURegWrite_ex <= FPURegWrite_id; 
            FPUResultSrc_ex <= FPUResultSrc_id;
            FPUOp_ex <= FPUOp_id; 
            FPUControl_ex <= FPUControl_id; 
            FPUSel_ex <= FPUSel_id;
        end
    end
endmodule