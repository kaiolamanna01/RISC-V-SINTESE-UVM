//! @brief CPU Top-Level - Conecta o Datapath e os Controlos
module cpu #(
    parameter bits = 32,
    parameter address_bits = 5,
    parameter registers = 32
)(
    input CLK,
    input rst,

    // Portas para carregamento de instruções
    input              clk_load,
    input              we,
    input  [bits-1:0]  ADDR_INST,
    input  [bits-1:0]  Instrucoes,

    // Saídas de observabilidade
    output [bits-1:0]  Dado,
    output             mem_we,
    output             mem_read,
    output [bits-1:0]  mem_addr,
    output [bits-1:0]  mem_rdata,

    // Saídas de observabilidade adicionais
    output [bits-1:0]  pc,
    output [bits-1:0]  instr,
    output             branch_ctrl,
    output             branch_taken,
    output             jump,
    output [bits-1:0]  alu_result,
    output [bits-1:0]  fpu_result,
    output [bits-1:0]  wb_data_x,
    output [bits-1:0]  wb_data_f,
    output [4:0]       rd_wb,
    output             regwrite_wb,
    output             fpuregwrite_wb,
    output [1:0]       forwardA,
    output [1:0]       forwardB,
    output [1:0]       forwardFA,
    output [1:0]       forwardFB,
    output             stall
);

    // Sinais de Controlo (do 'control.v')
    wire        RegWrite, ALUSrc, MemWrite, PCSrc;
    wire [1:0]  ResultSrc;
    wire [1:0]  ImmSrc;
    wire [2:0]  ALUControl;
    wire        Zero;
    wire        Branch;

    // Sinais da FPU (do 'control.v')
    wire        FPURegWrite, FPUResultSrc, FPUOp;
    wire [1:0]  FPUControl;
    wire [4:0]  FPUSel;

    // Sinais do Datapath (para 'control.v')
    wire [6:0]  op;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    
    // SINAIS DE PIPELINE E FORWARDING
    wire [4:0]  rs1_IDEX, rs2_IDEX;      
    wire [4:0]  frs1_IDEX, frs2_IDEX;    
    wire [4:0]  rd_EXMEM, rd_MEMWB;      
    wire        RegWrite_EXMEM, RegWrite_MEMWB; 
    wire        FPURegWrite_EXMEM, FPURegWrite_MEMWB; 
    
    wire [1:0]  ForwardA, ForwardB, ForwardFA, ForwardFB;

    // Observabilidade interna
    wire [bits-1:0] pc_dbg, instr_dbg;
    wire [bits-1:0] alu_result_dbg, fpu_result_dbg;
    wire [bits-1:0] wb_data_x_dbg, wb_data_f_dbg;
    wire            branch_ctrl_dbg, branch_taken_dbg;
    wire [4:0]      rs1_id, rs2_id;

    // Instância do Datapath (Pipelined)
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
        .ResultSrc  (ResultSrc),
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

        // SaÃ­das para os Controlos
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

    // Saídas de observabilidade (execução)
    .pc_dbg         (pc_dbg),
    .instr_dbg      (instr_dbg),
    .alu_result_dbg (alu_result_dbg),
    .fpu_result_dbg (fpu_result_dbg),
    .wb_data_x_dbg  (wb_data_x_dbg),
    .wb_data_f_dbg  (wb_data_f_dbg),
    .branch_ctrl_dbg(branch_ctrl_dbg),
    .branch_taken_dbg(branch_taken_dbg),
        
        // Saídas para o Forwarding Control (Controle e Registros X)
        .rs1_IDEX   (rs1_IDEX),
        .rs2_IDEX   (rs2_IDEX),
        .rd_EXMEM   (rd_EXMEM),
        .rd_MEMWB   (rd_MEMWB),
        .RegWrite_EXMEM (RegWrite_EXMEM),
        .RegWrite_MEMWB (RegWrite_MEMWB),
        
        // Saídas para o Forwarding Control (Controle e Registros F)
        .FPURegWrite_EXMEM (FPURegWrite_EXMEM), 
        .FPURegWrite_MEMWB (FPURegWrite_MEMWB),
        .frs1_IDEX  (frs1_IDEX),
        .frs2_IDEX  (frs2_IDEX)
    );

    // Detecção de hazard para observabilidade
    assign rs1_id = instr_dbg[19:15];
    assign rs2_id = instr_dbg[24:20];

    hazard_detection hazard_observe (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_EXMEM),
        .rd_mem(rd_MEMWB),
        .RegWrite_ex(RegWrite_EXMEM),
        .RegWrite_mem(RegWrite_MEMWB),
        .FPURegWrite_ex(FPURegWrite_EXMEM),
        .FPURegWrite_mem(FPURegWrite_MEMWB),
        .stall(stall)
    );

    // Instância da Unidade de Controle Principal
    control control_inst (
        .op         (op),
        .Zero       (Zero),
        .Branch     (Branch),
        .ResultSrc  (ResultSrc),
        .MemWrite   (MemWrite),
        .ALUSrc     (ALUSrc),
        .ImmSrc     (ImmSrc),
        .RegWrite   (RegWrite),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl),
        .PCSrc      (PCSrc),
        .FPURegWrite(FPURegWrite),
        .FPUResultSrc(FPUResultSrc),
        .FPUOp      (FPUOp),
        .FPUControl (FPUControl),
        .FPUSel     (FPUSel)
    );
    
    // Instância da Unidade de Controle de Forwarding
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

        // Sinais de SaÃ­da
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardFA(ForwardFA),
        .ForwardFB(ForwardFB)
    );

    // Ligações de observabilidade para o testbench
    assign pc            = pc_dbg;
    assign instr         = instr_dbg;
    assign branch_ctrl   = branch_ctrl_dbg;
    assign branch_taken  = branch_taken_dbg;
    assign jump          = 1'b0;
    assign alu_result    = alu_result_dbg;
    assign fpu_result    = fpu_result_dbg;
    assign wb_data_x     = wb_data_x_dbg;
    assign wb_data_f     = wb_data_f_dbg;
    assign rd_wb         = rd_MEMWB;
    assign regwrite_wb   = RegWrite_MEMWB;
    assign fpuregwrite_wb= FPURegWrite_MEMWB;
    assign forwardA      = ForwardA;
    assign forwardB      = ForwardB;
    assign forwardFA     = ForwardFA;
    assign forwardFB     = ForwardFB;

endmodule