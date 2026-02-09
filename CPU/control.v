module control(
    // Sinais gerais
    input [6:0] op,
 
    // Main Decoder
    // CORREÃ‡ÃƒO: ResultSrc, RegWrite, FPURegWrite precisam ser 'reg'
    // para serem controlados pelo 'always' block
    output reg [1:0] ResultSrc, 
    output MemWrite, Branch, ALUSrc,
    output reg RegWrite, 
    output [1:0] ImmSrc,
    input Zero,
    output PCSrc,
 
    // ALU Decoder
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [2:0] ALUControl,
    output reg [3:0] byteEnable, 
    
    // Novos sinais para FPU
    output reg FPURegWrite, // CORREÃ‡ÃƒO: Precisa ser 'reg'
    output FPUResultSrc, 
    output FPUOp,
    output [1:0] FPUControl,
    output reg [4:0] FPUSel
);

    wire [1:0] ALUOp; 
    
    // CORREÃ‡ÃƒO: DeclaraÃ§Ã£o dos Wires para os sinais do maindec
    wire [1:0] md_ResultSrc;
    wire       md_MemWrite, md_Branch, md_ALUSrc, md_RegWrite;
    wire [1:0] md_ImmSrc;
    wire       md_FPURegWrite, md_FPUResultSrc, md_FPUOp;
    wire [1:0] md_FPUControl;


    // InstÃ¢ncia do Main Decoder (saÃ­das conectadas aos wires 'md_')
    maindec maindec(
        .op(op),
        .Branch(md_Branch),
        .ResultSrc(md_ResultSrc),
        .MemWrite(md_MemWrite),
        .ALUSrc(md_ALUSrc),
        .ImmSrc(md_ImmSrc),
        .RegWrite(md_RegWrite),
        .ALUOp(ALUOp),
        .FPURegWrite(md_FPURegWrite),
        .FPUResultSrc(md_FPUResultSrc),
        .FPUOp(md_FPUOp),
        .FPUControl(md_FPUControl)
    );
    
    // ConexÃµes diretas (sinais que 'control' nÃ£o modifica)
    assign MemWrite = md_MemWrite;
    assign Branch = md_Branch;
    assign ALUSrc = md_ALUSrc;
    assign ImmSrc = md_ImmSrc;
    assign FPUResultSrc = md_FPUResultSrc;
    assign FPUOp = md_FPUOp;
    assign FPUControl = md_FPUControl;


    // ALU Decoder e LÃ³gica FPU
    always @(*) begin
        // --- InÃ­cio: LÃ³gica ORIGINAL (para ALUControl e FPUSel) ---
        ALUControl = 3'b000;
        byteEnable = 4'b1111;
        FPUSel = 5'b00000;
        
        case (ALUOp) 
            2'b00: begin 
                ALUControl = 3'b000; // add (para lw/sw)
                byteEnable = 4'b1111;
            end
            2'b01: begin
                ALUControl = 3'b001; // sub (para branch)
                byteEnable = 4'b1111;
            end
            2'b10: begin // R-type ou I-type
                case (funct3)
                    3'b000: begin
                        if(op[5] & funct7[0]) // ADDI vs SUB/ADD
                            ALUControl = 3'b001; // sub
                        else
                            ALUControl = 3'b000; // add
                    end
                    3'b010: ALUControl = 3'b101; // slt
                    3'b110: ALUControl = 3'b011; // or
                    3'b111: ALUControl = 3'b010; // and
                    default: ALUControl = 3'b000;
                endcase
            end
            default: begin
                ALUControl = 3'b000;
                byteEnable = 4'b1111;
            end
        endcase
        
        if (op == 7'h53) begin // Opcode FPU 1010011
            case ({funct7, funct3})
                {7'b0000000, 3'b000}: FPUSel = 5'b00100; // FADD.S (sel=4)
                {7'b0000100, 3'b000}: FPUSel = 5'b00101; // FSUB.S (sel=5)
                {7'b0001000, 3'b000}: FPUSel = 5'b00110; // FMUL.S (sel=6)
                {7'b0101000, 3'b000}: FPUSel = 5'b00000; // FDIV.S (nÃ£o implementado)
                {7'b1101000, 3'b000}: FPUSel = 5'b01110; // FCVT.S.W (sel=14)
                {7'b1100000, 3'b000}: FPUSel = 5'b01111; // FCVT.W.S (sel=15)
                {7'b1111000, 3'b000}: FPUSel = 5'b00000; // FMV.W.X (sel=0)
                {7'b1110000, 3'b000}: FPUSel = 5'b00000; // FMV.X.W (tratado no datapath)
                {7'b1010000, 3'b001}: FPUSel = 5'b01011; // FLE.S (sel=11)
                {7'b1010000, 3'b010}: FPUSel = 5'b01010; // FLT.S (sel=10)
                default: FPUSel = 5'b00000; // OperaÃ§Ã£o invÃ¡lida
            endcase
        end
        // --- Fim: LÃ³gica ORIGINAL ---

        
        // --- InÃ­cio: CORREÃ‡ÃƒO DO BUG 1 (LÃ³gica de escrita) ---
        // LÃ³gica de controle de escrita (depende de funct3/funct7)
        
        // 1. Pega os valores padrÃ£o do maindec
        RegWrite = md_RegWrite;
        FPURegWrite = md_FPURegWrite;
        ResultSrc = md_ResultSrc;

        // 2. Sobrescreve a lÃ³gica para FPU R-type (opcode 7'b1010011)
        if (op == 7'b1010011) begin
            // fcvt.w.s (fp-para-int)
            if (funct7 == 7'b1100000 && funct3 == 3'b000) begin
                RegWrite = 1'b1;        // Escreve no RegFile X
                FPURegWrite = 1'b0;   // NÃƒO escreve no RegFile F
                ResultSrc = 2'b10;    // Seleciona FPU_Result no MUX de WB do RegFile X
            end
            // fcvt.s.w (int-para-fp)
            else if (funct7 == 7'b1101000 && funct3 == 3'b000) begin
                RegWrite = 1'b0;
                FPURegWrite = 1'b1;   // Escreve no RegFile F
                ResultSrc = 2'b00;    // (NÃ£o importa)
            end
            // fmv.w.x (int-para-fp)
            else if (funct7 == 7'b1111000 && funct3 == 3'b000) begin
                 RegWrite = 1'b0;
                FPURegWrite = 1'b1;   // Escreve no RegFile F
                ResultSrc = 2'b00;    // (NÃ£o importa)
            end
             // fmv.x.w (fp-para-int)
            else if (funct7 == 7'b1110000 && funct3 == 3'b000) begin
                 RegWrite = 1'b1;        // Escreve no RegFile X
                FPURegWrite = 1'b0;   // NÃƒO escreve no RegFile F
                ResultSrc = 2'b10;    // Seleciona FPU_Result no MUX de WB do RegFile X
            end
            // Outras operaÃ§Ãµes FPU R-Type (fadd, fsub, fmul, fle, flt)
            else begin
                RegWrite = 1'b0;
                FPURegWrite = 1'b1;   // Escreve no RegFile F
                ResultSrc = 2'b00;    // (NÃ£o importa)
            end
        end
        // --- Fim: CORREÃ‡ÃƒO DO BUG 1 ---
    end

    assign PCSrc = (Branch & Zero);

endmodule