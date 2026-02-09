module maindec(
    input [6:0] op, // Sinal de definição dos sinais de controle

    // Sinais de controle originais
    output [1:0] ResultSrc, // CORREÇÃO: Alargado para 2 bits
    output MemWrite,
    output Branch, 
    output ALUSrc,
    output RegWrite, 
    output [1:0] ImmSrc,
    output [1:0] ALUOp,
    
    // Novos sinais para FPU
    output FPURegWrite,     // Write enable para Register File F
    output FPUResultSrc,    // Seletor de resultado da FPU  
    output FPUOp,           // Indica operação da FPU (0=INT, 1=FP)
    output [1:0] FPUControl // Controle da FPU
);

    // CORREÇÃO: Alargado para 15 bits para acomodar ResultSrc[1:0]
    reg [14:0] controls; 
    
    // Formato: {FPUControl, FPUOp, FPUResultSrc, FPURegWrite, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc[1:0], Branch, ALUOp}
    // Bits:      [14:13]    [12]      [11]         [10]         [9]       [8:7]    [6]       [5]        [4:3]       [2]     [1:0]
    assign {FPUControl, FPUOp, FPUResultSrc, FPURegWrite, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp} = controls;

    always @(*) begin
        case(op)
            // Instruções Inteiras Existentes
            // lw (ResultSrc = 01 -> MemData)
            7'b0000011: controls = 15'bxx_0_x_0_1_00_1_0_01_0_00; 
            // sw (ResultSrc = xx)
            7'b0100011: controls = 15'bxx_0_x_0_0_01_1_1_xx_0_00; 
            // R-type (ResultSrc = 00 -> ALUResult)
            7'b0110011: controls = 15'bxx_0_x_0_1_xx_0_0_00_0_10; 
            // beq (ResultSrc = xx)
            7'b1100011: controls = 15'bxx_0_x_0_0_10_0_0_xx_1_01; 
            // addi (ResultSrc = 00 -> ALUResult)
            7'b0010011: controls = 15'bxx_0_x_0_1_00_1_0_00_0_10; 
            // LUI (ResultSrc = 00 -> ALUResult, ALU faz 0+Imm)
            7'b0110111: controls = 15'bxx_0_x_0_1_11_1_0_00_0_00; 

            // Instruções FPU
            // FPU R-type (ATENÇÃO: LÓGICA INCOMPLETA - Ver nota abaixo)
            // (ResultSrc = 00, RegWrite=0, FPURegWrite=1)
            7'b1010011: controls = 15'b00_1_0_1_0_xx_0_0_00_0_00; 
            
            // flw (ResultSrc = xx, FPUResultSrc = 1 -> MemData)
            7'b0000111: controls = 15'b01_1_1_1_0_00_1_0_xx_0_00; 
            
            // fsw (ResultSrc = xx, FPUResultSrc = x)
            7'b0100111: controls = 15'b01_1_x_0_0_01_1_1_xx_0_00; 
            
            // Default (seguro)
            default: controls = 15'b00_0_0_0_0_00_0_0_xx_0_00; 
        endcase
    end

endmodule