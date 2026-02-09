module aludec (
    // Sinais de definição seletor
    input [1:0] ALUOp, // Gerado pelo decodificador principal
    input [2:0] funct3, // Gerado com base na instrução (bit 2 a 0)
    input op, // Gerado com base na instrução (bit 5)
    input funct7, // Gerado com base na instrução (bit 30)
    output reg [2:0] ALUControl, // Seletor de operação
    output reg [3:0] byteEnable, // Controle da memória byte addressable
    
    // Novos sinais para FPU
    input [1:0] FPUControl, // Do maindec
    output reg [4:0] FPUSel // Seletor de operação da FPU (0-15)
);

always @(*) begin
    // Inicializar com valores default
    ALUControl = 3'b000;
    byteEnable = 4'b1111;
    FPUSel = 5'b00000;
    
    case (ALUOp) 
        2'b00: begin 
            ALUControl = 3'b000; // Operação "add" (lw/sw)
            byteEnable = 4'b1111;
        end
        2'b01: begin
            ALUControl = 3'b001; // Operação "sub" (beq)
            byteEnable = 4'b1111;
        end
        2'b10: begin // R-type ou I-type
            case (funct3)
                3'b000: begin
                    if(op & funct7) begin
                        ALUControl = 3'b001; // Operação "sub"
                    end
                    else begin
                        ALUControl = 3'b000; // Operação "add"
                    end
                    byteEnable = 4'b1111;
                end
                3'b010: begin
                    ALUControl = 3'b101; // Operação "slt"
                    byteEnable = 4'b1111;
                end
                3'b110: ALUControl = 3'b011; // Operação "or"
                3'b111: ALUControl = 3'b010; // Operação "and"
                default: begin
                    ALUControl = 3'b000;
                    byteEnable = 4'b1111;
                end
            endcase
        end
        
        // Caso para operações FPU (ALUOp = 2'b11 ou via FPUControl)
        default: begin
            if (FPUControl != 2'b00) begin  // CORRIGIDO
                // Decodificação de instruções FPU baseada em funct7 e rs2
                case ({funct7, funct3})
                    // FADD.S
                    10'b0000000_000: FPUSel = 5'b00100; // A+B
                    // FSUB.S  
                    10'b0000100_000: FPUSel = 5'b00101; // A-B
                    // FMUL.S
                    10'b0001000_000: FPUSel = 5'b00110; // A*B
                    // FDIV.S (não implementado, mas decodificado)
                    10'b0001100_000: FPUSel = 5'b00000; // Default
                    
                    // Conversões
                    // FCVT.S.W (int to float)
                    10'b1101000_000: FPUSel = 5'b01111; // cvt w-s
                    // FCVT.W.S (float to int)  
                    10'b1100000_000: FPUSel = 5'b01110; // cvt s-w
                    
                    // Movimentações
                    // FMV.W.X (int reg to float reg)
                    10'b1111000_000: FPUSel = 5'b00001; // B (pass-through)
                    // FMV.X.W (float reg to int reg)
                    10'b1110000_000: FPUSel = 5'b00000; // A (pass-through)
                    
                    // Comparações
                    // FEQ.S
                    10'b1010000_010: FPUSel = 5'b01001; // eq
                    // FLT.S
                    10'b1010000_001: FPUSel = 5'b01010; // lt
                    // FLE.S
                    10'b1010000_000: FPUSel = 5'b01011; // le
                    
                    default: FPUSel = 5'b00000; // Default
                endcase
                ALUControl = 3'b000; // ALU não usada em operações FPU
                byteEnable = 4'b1111;
            end
        end
    endcase
end

endmodule