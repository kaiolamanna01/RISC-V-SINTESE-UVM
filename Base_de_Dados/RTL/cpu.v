//! @brief CPU Top-Level - Conecta o Datapath e os Controlos
module cpu #(
    parameter bits = 32,
    parameter address_bits = 5,
    parameter registers = 32
)(
    input CLK,
    input rst,

    // --- Portas para carregamento de instruções ---
    input              clk_load,
    input              we,
    input  [bits-1:0]  ADDR_INST,
    input  [bits-1:0]  Instrucoes,

    // --- Saídas de observabilidade ---
    output [bits-1:0]  Dado,
    output             mem_we,
    output             mem_read,
    output [bits-1:0]  mem_addr,
    output [bits-1:0]  mem_rdata
);

    // --- Sinais de Controlo (do 'control.v') ---
    wire        RegWrite, ALUSrc, MemWrite, PCSrc;
    wire [1:0]  ResultSrc; // CORREÇÃO: Alargado para 2 bits
    wire [1:0]  ImmSrc;
    wire [2:0]  ALUControl;
    wire        Zero;
    wire        Branch;

    // Sinais da FPU (do 'control.v')
    wire        FPURegWrite, FPUResultSrc, FPUOp;
    wire [1:0]  FPUControl;
    wire [4:0]  FPUSel;

    // --- Sinais do Datapath (para 'control.v') ---
    wire [6:0]  op;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    
    // --- SINAIS DE PIPELINE E FORWARDING ---
    wire [4:0]  rs1_IDEX, rs2_IDEX;      
    wire [4:0]  frs1_IDEX, frs2_IDEX;    
    wire [4:0]  rd_EXMEM, rd_MEMWB;      
    wire        RegWrite_EXMEM, RegWrite_MEMWB; 
    wire        FPURegWrite_EXMEM, FPURegWrite_MEMWB; 
    
    wire [1:0]  ForwardA, ForwardB, ForwardFA, ForwardFB;

    // --- Instância do Datapath (Pipelined) ---
    datapath #(
        .bits(bits),
        .address_bits(address_bits),
        .registers(registers)
    ) datapath_inst (
        .CLK        (CLK),
        .rst        (rst),

        // Portas de carregamento de instruções
        .clk_load   (clk_load),
        .we         (we),
        .ADDR_INST  (ADDR_INST),
        .Instrucoes (Instrucoes),
        
        // Entradas de Controlo
        .RegWrite   (RegWrite),
        .ALUSrc     (ALUSrc),
        .MemWrite   (MemWrite),
        .ResultSrc  (ResultSrc), // CORREÇÃO
        .PCSrc      (PCSrc),
        .Branch     (Branch),
        .ImmSrc     (ImmSrc),
        .ALUControl (ALUControl),
        .FPURegWrite(FPURegWrite),
        .FPUResultSrc(FPUResultSrc),
        .FPUOp      (FPUOp),
        .FPUSel     (FPUSel),
        
        // Entradas de Forwarding (do Fowarding Control)
        .ForwardA   (ForwardA),
        .ForwardB   (ForwardB),
        .ForwardFA  (ForwardFA),
        .ForwardFB  (ForwardFB),

        // Saídas para os Controlos
        .Zero       (Zero),
        .op         (op),
        .funct3     (funct3),
        .funct7     (funct7),

        // Saídas de observabilidade de memória
        .Dado       (Dado),
        .mem_we     (mem_we),
        .mem_read   (mem_read),
        .mem_addr   (mem_addr),
        .mem_rdata  (mem_rdata),
        
        // Saídas para o Fowarding Control (Controlo e Registos X)
        .rs1_IDEX   (rs1_IDEX),
        .rs2_IDEX   (rs2_IDEX),
        .rd_EXMEM   (rd_EXMEM),
        .rd_MEMWB   (rd_MEMWB),
        .RegWrite_EXMEM (RegWrite_EXMEM),
        .RegWrite_MEMWB (RegWrite_MEMWB),
        
        // Saídas para o Fowarding Control (Controlo e Registos F)
        .FPURegWrite_EXMEM (FPURegWrite_EXMEM), 
        .FPURegWrite_MEMWB (FPURegWrite_MEMWB),
        .frs1_IDEX  (frs1_IDEX),
        .frs2_IDEX  (frs2_IDEX)
    );

    // --- Instância da Unidade de Controle Principal ---
    control control_inst (
        .op         (op),
        .Zero       (Zero),
        .Branch     (Branch),
        .ResultSrc  (ResultSrc), // CORREÇÃO
        .MemWrite   (MemWrite),
        .ALUSrc     (ALUSrc),
        .ImmSrc     (ImmSrc),
        .RegWrite   (RegWrite),
        // CORREÇÃO: Conexão .ALUOp(2'b00) removida
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl),
        .PCSrc      (PCSrc),
        // .byteEnable (byteEnable), // 'byteEnable' não está sendo usado no top-level
        .FPURegWrite(FPURegWrite),
        .FPUResultSrc(FPUResultSrc),
        .FPUOp      (FPUOp),
        .FPUControl (FPUControl),
        .FPUSel     (FPUSel)
    );
    
    // --- Instância da Unidade de Controle de Forwarding ---
    fowarding_control fowarding_control_inst (
        // Endereços de Leitura (ID/EX)
        .rs1_IDEX(rs1_IDEX),
        .rs2_IDEX(rs2_IDEX),
        .frs1_IDEX(frs1_IDEX),
        .frs2_IDEX(frs2_IDEX),

        // Pipeline EX/MEM
        .rd_EXMEM(rd_EXMEM),
        .RegWrite_EXMEM(RegWrite_EXMEM),
        .FPURegWrite_EXMEM(FPURegWrite_EXMEM),

        // Pipeline MEM/WB
        .rd_MEMWB(rd_MEMWB),
        .RegWrite_MEMWB(RegWrite_MEMWB),
        .FPURegWrite_MEMWB(FPURegWrite_MEMWB),

        // Sinais de Saída
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardFA(ForwardFA),
        .ForwardFB(ForwardFB)
    );

endmodule