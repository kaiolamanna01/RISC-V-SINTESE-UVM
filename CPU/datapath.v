//! @brief Datapath pipelined de 5 estÃ¡gios com FPU e Forwarding
module datapath #(
    parameter bits = 32,
    parameter address_bits = 5,
    parameter registers = 32
)(
    input CLK, rst,

    //  Portas para carregamento de instruÃ§Ãµes 
    input              clk_load,
    input              we,
    input  [bits-1:0]  ADDR_INST,
    input  [bits-1:0]  Instrucoes,
    
    //  Sinais de Controlo (do 'control.v') 
    input       RegWrite, ALUSrc, MemWrite,
    input [1:0] ResultSrc, // CORREÃ‡ÃƒO: Alargado para 2 bits
    input       Branch,
    input [1:0] ImmSrc,
    input [2:0] ALUControl,
    
    // Sinais da FPU (do 'control.v')
    input       FPURegWrite, FPUResultSrc, FPUOp,
    input [4:0] FPUSel,

    //  Sinais de Forwarding (do 'fowarding_control.v') 
    input [1:0] ForwardA,
    input [1:0] ForwardB,
    input [1:0] ForwardFA,
    input [1:0] ForwardFB,

    //  SaÃ­das de Pipeline para o 'fowarding_control.v' 
    // Registos X (Inteiros)
    output reg [4:0]  rs1_IDEX,
    output reg [4:0]  rs2_IDEX,
    output reg [4:0]  rd_EXMEM,
    output reg [4:0]  rd_MEMWB,
    output reg        RegWrite_EXMEM,
    output reg        RegWrite_MEMWB,
    
    // Registros F (Ponto Flutuante)
    output reg [4:0]  frs1_IDEX,
    output reg [4:0]  frs2_IDEX,
    output reg        FPURegWrite_EXMEM,
    output reg        FPURegWrite_MEMWB,
    
    //  SaÃ­das para o 'control.v' 
    output      Zero,
    output [6:0] op,
    output [2:0] funct3,
    output [6:0] funct7,

    //  SaÃ­das de observabilidade de memÃ³ria 
    output [bits-1:0] Dado,
    output            mem_we,
    output            mem_read,
    output [bits-1:0] mem_addr,
    output [bits-1:0] mem_rdata,
    output [bits-1:0] pc_dbg,
        output [bits-1:0] instr_dbg,
        output [bits-1:0] alu_result_dbg,
        output [bits-1:0] fpu_result_dbg,
        output [bits-1:0] wb_data_x_dbg,
        output [bits-1:0] wb_data_f_dbg,
        output            branch_ctrl_dbg,
        output            branch_taken_dbg
);

    //  Sinais do EstÃ¡gio IF 
    wire [bits-1:0] PC_next, PC_current, PC_plus_4;
    wire [bits-1:0] instruction;
    wire [bits-1:0] instruction_addr;

    //  Sinais entre IF/ID 
    reg  [bits-1:0] if_id_instruction;
    reg  [bits-1:0] if_id_pc_plus_4;

    //  Sinais do EstÃ¡gio ID 
    wire [bits-1:0] imm_ext;
    wire [bits-1:0] srcA, srcB_or_write_data; 
    wire [bits-1:0] f_data1, f_data2;        
    
    assign op     = if_id_instruction[6:0];
    assign funct3 = if_id_instruction[14:12];
    assign funct7 = if_id_instruction[31:25];

    //  Sinais entre ID/EX 
    reg  [bits-1:0] srcA_IDEX, srcB_IDEX, f_data1_IDEX, f_data2_IDEX, imm_ext_IDEX;
    reg  [bits-1:0] pc_plus_4_IDEX;
    reg  [4:0]      rd_IDEX; 
    reg  [6:0]      op_IDEX; // opcode pipelined para uso em EX
    reg             RegWrite_IDEX, ALUSrc_IDEX, MemWrite_IDEX, Branch_IDEX;
    reg  [1:0]      ResultSrc_IDEX; // CORREÃ‡ÃƒO: Alargado para 2 bits
    reg  [2:0]      ALUControl_IDEX;
    reg             FPURegWrite_IDEX, FPUResultSrc_IDEX, FPUOp_IDEX;
    reg  [4:0]      FPUSel_IDEX;

    //  Sinais do EstÃ¡gio EX 
    wire [bits-1:0] alu_in_A, alu_in_B, alu_result;
    wire [bits-1:0] fpu_in_A, fpu_in_B, fpu_result;
    wire [bits-1:0] fwd_A_data, fwd_B_data, fwd_fA_data, fwd_fB_data;
    wire            Zero_EX; 
    wire            fpu_srcA_sel; 

    //  Sinais entre EX/MEM 
    reg  [bits-1:0] alu_result_EXMEM;
    reg  [bits-1:0] fpu_result_EXMEM;
    reg  [bits-1:0] write_data_EXMEM; // srcB/f_data2 (agora usa valor 'forwarded')
    reg             MemWrite_EXMEM, Branch_EXMEM;
    reg  [1:0]      ResultSrc_EXMEM; // CORREÃ‡ÃƒO: Alargado para 2 bits
    reg             FPUResultSrc_EXMEM;
    reg             Zero_EXMEM; 
    wire PCSrc; 

    assign PCSrc = Branch_EXMEM & Zero_EXMEM;
    // Sinais 'output reg' (rd_EXMEM, RegWrite_EXMEM, FPURegWrite_EXMEM) jÃ¡ declarados

    //  Sinais do EstÃ¡gio MEM 
    wire [bits-1:0] read_data_MEM;

    //  Sinais entre MEM/WB 
    reg  [bits-1:0] alu_result_MEMWB;
    reg  [bits-1:0] fpu_result_MEMWB;
    reg  [bits-1:0] read_data_MEMWB;
    reg  [1:0]      ResultSrc_MEMWB; // CORREÃ‡ÃƒO: Alargado para 2 bits
    reg             FPUResultSrc_MEMWB;
    // Sinais 'output reg' (rd_MEMWB, RegWrite_MEMWB, FPURegWrite_MEMWB) jÃ¡ declarados
    
    //  Sinais do EstÃ¡gio WB 
    wire [bits-1:0] result_WB;      
    wire [bits-1:0] fpu_result_WB;  // CORREÃ‡ÃƒO: Esta Ã© a saÃ­da do novo MUX
    wire [bits-1:0] wb_mux_x_intermediate; 

    // =========================================================================
    //  ESTÃGIOS IF/ID 
    // =========================================================================
    
    //  IF 
    pc_reg #(bits) pc_reg (
        .CLK(CLK), .rst(rst), 
        .PCNext(PC_next), 
        .PC(PC_current)
    );
    
    assign instruction_addr = we ? ADDR_INST : PC_current;

    instruction_memory #(bits) imem (
        .clk_load(clk_load),
        .we      (we),
        .A       (instruction_addr), 
        .WD      (Instrucoes),
        .RD      (instruction)
    );
    
    assign PC_plus_4 = PC_current + 4;
    assign PC_next = PCSrc ? alu_result_EXMEM : PC_plus_4; // Mux do PC (branch)

    //  IF/ID Register 
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            if_id_instruction <= 0;
            if_id_pc_plus_4 <= 0;
        end else begin
            if_id_instruction <= instruction;
            if_id_pc_plus_4 <= PC_plus_4;
        end
    end

    //  ID 
    register_file #(bits, address_bits, registers) reg_file_x (
        .CLK(!CLK), .rst(rst), .WE3(RegWrite_MEMWB), 
        .A1(if_id_instruction[19:15]), .A2(if_id_instruction[24:20]), .A3(rd_MEMWB),
        .WD3(result_WB), .RD1(srcA), .RD2(srcB_or_write_data)
    );
    
    register_file_f #(bits, address_bits, registers) reg_file_f (
        .CLK(!CLK), .rst(rst), .WE3(FPURegWrite_MEMWB),
        .A1(if_id_instruction[19:15]), .A2(if_id_instruction[24:20]), .A3(rd_MEMWB),
        .WD3(fpu_result_WB), .RD1(f_data1), .RD2(f_data2)
    );
    
    sign_extender #(bits) extender (
        .Instr(if_id_instruction[31:7]), 
        .ImmSrc(ImmSrc), 
        .ImmExt(imm_ext)
    );

    // =========================================================================
    //  ESTÃGIOS ID/EX 
    // =========================================================================
    
    //  ID/EX Register 
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            srcA_IDEX <= 0;
            srcB_IDEX <= 0;
            f_data1_IDEX <= 0;
            f_data2_IDEX <= 0;
            imm_ext_IDEX <= 0;
            pc_plus_4_IDEX <= 0;
            rs1_IDEX <= 0;
            rs2_IDEX <= 0;
            frs1_IDEX <= 0; 
            frs2_IDEX <= 0; 
            rd_IDEX <= 0;
            RegWrite_IDEX <= 0;
            ALUSrc_IDEX <= 0;
            MemWrite_IDEX <= 0;
            ResultSrc_IDEX <= 0; // CORREÃ‡ÃƒO
            ALUControl_IDEX <= 0;
            FPURegWrite_IDEX <= 0;
            FPUResultSrc_IDEX <= 0;
            FPUOp_IDEX <= 0;
            FPUSel_IDEX <= 0;
            Branch_IDEX <= 0;
            op_IDEX <= 0;
        end else begin
            srcA_IDEX <= srcA;
            srcB_IDEX <= srcB_or_write_data;
            f_data1_IDEX <= f_data1;
            f_data2_IDEX <= f_data2;
            imm_ext_IDEX <= imm_ext;
            pc_plus_4_IDEX <= if_id_pc_plus_4;
            rs1_IDEX <= if_id_instruction[19:15];
            rs2_IDEX <= if_id_instruction[24:20];
            frs1_IDEX <= if_id_instruction[19:15];
            frs2_IDEX <= if_id_instruction[24:20];
            rd_IDEX <= if_id_instruction[11:7];
            RegWrite_IDEX <= RegWrite;
            ALUSrc_IDEX <= ALUSrc;
            MemWrite_IDEX <= MemWrite;
            ResultSrc_IDEX <= ResultSrc; // CORREÃ‡ÃƒO
            ALUControl_IDEX <= ALUControl;
            FPURegWrite_IDEX <= FPURegWrite;
            FPUResultSrc_IDEX <= FPUResultSrc;
            FPUOp_IDEX <= FPUOp;
            FPUSel_IDEX <= FPUSel;
            Branch_IDEX <= Branch;
            op_IDEX <= op;
        end
    end
    
    //  EX 
    
    // Muxes de Forwarding (ALU)
    assign fwd_A_data = (ForwardA == 2'b10) ? alu_result_EXMEM :
                        (ForwardA == 2'b01) ? result_WB :
                                              srcA_IDEX;
    assign fwd_B_data = (ForwardB == 2'b10) ? alu_result_EXMEM :
                        (ForwardB == 2'b01) ? result_WB :
                                              srcB_IDEX;
    
    mux #(bits) alu_src_mux (
        .A(fwd_B_data), .B(imm_ext_IDEX),
        .sel(ALUSrc_IDEX), .Y(alu_in_B)
    );
    assign alu_in_A = fwd_A_data;

    alu #(bits) alu (
        .SrcA(alu_in_A), .SrcB(alu_in_B), .ALUControl(ALUControl_IDEX), 
        .Zero(Zero_EX), .ALUResult(alu_result)
    );

    // Muxes de Forwarding (FPU)
    assign fwd_fA_data = (ForwardFA == 2'b10) ? fpu_result_EXMEM :
                         (ForwardFA == 2'b01) ? fpu_result_WB :
                                                f_data1_IDEX;
    assign fwd_fB_data = (ForwardFB == 2'b10) ? fpu_result_EXMEM :
                         (ForwardFB == 2'b01) ? fpu_result_WB :
                                                f_data2_IDEX;
    
    // Mux para selecionar entre fonte INT (srcA) ou FLOAT (f_data1) para FPU
        assign fpu_srcA_sel = (op_IDEX == 7'h53) &
                                                    ( (FPUSel_IDEX == 5'b01110) | // FCVT.S.W (sel=14)
                                                        (FPUSel_IDEX == 5'b00000) ); // FMV.W.X (sel=0)
                          
    mux #(bits) fpu_mux_A (
        .A(fwd_fA_data), .B(fwd_A_data), // Mux A da FPU: f_data1 (float) vs srcA (int)
        .sel(fpu_srcA_sel), .Y(fpu_in_A)
    );
    assign fpu_in_B = fwd_fB_data; // Mux B da FPU sempre usa f_data2

    FPU fpu (
        .A(fpu_in_A), .B(fpu_in_B),
        .sel(FPUSel_IDEX), .Result(fpu_result)
    );
    
    assign Zero = Zero_EX; 

    // =========================================================================
    //  ESTÃGIOS EX/MEM 
    // =========================================================================

    //  EX/MEM Register 
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            alu_result_EXMEM <= 0;
            fpu_result_EXMEM <= 0;
            write_data_EXMEM <= 0; 
            rd_EXMEM <= 0;
            RegWrite_EXMEM <= 0;
            MemWrite_EXMEM <= 0;
            ResultSrc_EXMEM <= 0; // CORREÃ‡ÃƒO
            FPURegWrite_EXMEM <= 0;
            FPUResultSrc_EXMEM <= 0;
            Branch_EXMEM <= 0;
            Zero_EXMEM <= 0;
        end else begin
            alu_result_EXMEM <= alu_result;
            fpu_result_EXMEM <= fpu_result;
            
            // CORREÃ‡ÃƒO: Usar o valor 'forwarded' de B (fwd_fB_data ou fwd_B_data)
            // para 'write_data', que Ã© usado pelo SW ou FSW
            write_data_EXMEM <= FPUOp_IDEX ? fwd_fB_data : fwd_B_data; 
                                        
            rd_EXMEM <= rd_IDEX;
            RegWrite_EXMEM <= RegWrite_IDEX;
            MemWrite_EXMEM <= MemWrite_IDEX;
            ResultSrc_EXMEM <= ResultSrc_IDEX; // CORREÃ‡ÃƒO
            FPURegWrite_EXMEM <= FPURegWrite_IDEX;
            FPUResultSrc_EXMEM <= FPUResultSrc_IDEX;
            Branch_EXMEM <= Branch_IDEX;
            Zero_EXMEM <= Zero_EX;
        end
    end
    
    //  MEM 
    data_memory #(bits) dmem (
        .CLK(CLK), .rst(rst), 
        .WE(MemWrite_EXMEM), 
        .A(alu_result_EXMEM),
        .WD(write_data_EXMEM),
        .RD(read_data_MEM)
    );

        // Saídas de observabilidade de memória
    assign Dado     = write_data_EXMEM;
    assign mem_we   = MemWrite_EXMEM;
    assign mem_read = (ResultSrc_EXMEM == 2'b01);
    assign mem_addr = alu_result_EXMEM;
    assign mem_rdata = read_data_MEM;

        // Saídas de observabilidade (execução)
        assign pc_dbg           = PC_current;
        assign instr_dbg        = if_id_instruction;
        assign alu_result_dbg   = alu_result;
        assign fpu_result_dbg   = fpu_result;
        assign wb_data_x_dbg    = result_WB;
        assign wb_data_f_dbg    = fpu_result_WB;
        assign branch_ctrl_dbg  = Branch_EXMEM;
        assign branch_taken_dbg = PCSrc;
    

    // =========================================================================
    //  ESTÁGIOS MEM/WB 
    // =========================================================================
    
    //  MEM/WB Register 
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            alu_result_MEMWB <= 0;
            fpu_result_MEMWB <= 0;
            read_data_MEMWB <= 0;
            rd_MEMWB <= 0;
            RegWrite_MEMWB <= 0;
            ResultSrc_MEMWB <= 0; // CORREÃ‡ÃƒO
            FPURegWrite_MEMWB <= 0;
            FPUResultSrc_MEMWB <= 0;
        end else begin
            alu_result_MEMWB <= alu_result_EXMEM;
            fpu_result_MEMWB <= fpu_result_EXMEM;
            read_data_MEMWB <= read_data_MEM;
            rd_MEMWB <= rd_EXMEM;
            RegWrite_MEMWB <= RegWrite_EXMEM;
            ResultSrc_MEMWB <= ResultSrc_EXMEM; // CORREÃ‡ÃƒO
            FPURegWrite_MEMWB <= FPURegWrite_EXMEM;
            FPUResultSrc_MEMWB <= FPUResultSrc_EXMEM;
        end
    end
    
    //  WB 
    
    // CORREÇÃO: MUX de 3 entradas para o Write-Back Inteiro (X)
    // Assumindo codificação para ResultSrc_MEMWB:
    //   2'b00 = ALU Result (Instruções R, I)
    //   2'b01 = Memory Data (lw)
    //   2'b10 = FPU Result (fcvt.w.s, fmv.x.w)
    
    // Mux 1: ALU (0) vs MEM (1)
    mux #(bits) wb_mux_x_alu_mem (
        .A(alu_result_MEMWB), 
        .B(read_data_MEMWB), 
        .sel(ResultSrc_MEMWB[0]), // sel[0] escolhe entre ALU (0) e MEM (1)
        .Y(wb_mux_x_intermediate)
    );
    
    // Mux 2: (ALU/MEM) (0) vs FPU (1)
    mux #(bits) wb_mux_x_final (
        .A(wb_mux_x_intermediate), 
        .B(fpu_result_MEMWB),     // Dados da FPU
        .sel(ResultSrc_MEMWB[1]), // sel[1] escolhe entre (ALU/MEM) (0) e FPU (1)
        .Y(result_WB)
    );
    
    // MUX para escrita no RegFile F (suporta 'flw')
    // FPUResultSrc_MEMWB: 0 = Resultado da FPU (padrão)
    //                     1 = Dado da Memória (para flw)
    mux #(bits) wb_mux_f (
        .A(fpu_result_MEMWB),   // 0: Resultado da FPU
        .B(read_data_MEMWB),    // 1: Dado da Memória
        .sel(FPUResultSrc_MEMWB),
        .Y(fpu_result_WB)       // Saída para o RegFile F
    );

endmodule