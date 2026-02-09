module cpu_tb;
    reg CLK, rst;
    reg clk_load, we;
    reg [31:0] ADDR_INST, Instrucoes;
    wire [31:0] Dado;
    wire mem_we, mem_read;
    wire [31:0] mem_addr, mem_rdata;

    // Instanciar a CPU
    cpu #(32, 5, 32) cpu_inst (
        .CLK(CLK),
        .rst(rst),
        .clk_load(clk_load),
        .we(we),
        .ADDR_INST(ADDR_INST),
        .Instrucoes(Instrucoes),
        .Dado(Dado),
        .mem_we(mem_we),
        .mem_read(mem_read),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata)
    );
    
    // Gerar clocks
    always #5 clk_load = ~clk_load;  // Clock de carga sempre ativo
    
    always begin
        if (we)
            CLK = 1'b0;  // Durante carregamento, CLK fica parado
        else
            #5 CLK = ~CLK;  // Durante execução, CLK funciona normalmente
    end
    
    // Pretty-print da instrução
    task get_instruction_name;
        input  [31:0] instr;
        output [15:0] name;
        begin
            case (instr[6:0])
                7'b0000011: name = "LW";
                7'b0100011: name = "SW";
                7'b0010011: name = "ADDI";
                7'b0110011: name = "R-TYPE";
                7'b1100011: name = "BRANCH";
                7'b0000111: name = "FLW";
                7'b0100111: name = "FSW";
                7'b1010011: name = "FPU-OP";
                7'b0110111: name = "LUI";
                default: name = "UNK";
            endcase
        end
    endtask
    reg [15:0] instr_name;
    
    // Caminho do programa
    reg [1023:0] program_file;
    
    initial begin
        $display("=== Iniciando Teste da CPU com FPU + Forwarding ===");
        
            // Carregar programa do arquivo (caminho absoluto)
            program_file = "/home/aluno/Imagens/PROJETOFINAL/CPU/program_cpu_tb.txt";
        $readmemh(program_file, cpu_inst.datapath_inst.imem.mem);
        $display("Programa carregado de: %s", program_file);
        
        // Inicializar sinais
        CLK = 0;
        clk_load = 0;
        we = 0;  // Memória já carregada via $readmemh
        ADDR_INST = 0;
        Instrucoes = 0;
        rst = 1;
        
        #20 rst = 0;
        
        $display("=== Programa carregado. Iniciando execução ===");
        
        // Tempo de simulação (ajuste se necessário)
        #2000;
        $display("\n=== Estado Final dos Registradores ===");
        $display("x5  = %h", cpu_inst.datapath_inst.reg_file_x.registrador[5]);
        $display("x6  = %h", cpu_inst.datapath_inst.reg_file_x.registrador[6]);
        $display("x7  = %h", cpu_inst.datapath_inst.reg_file_x.registrador[7]);
        $display("x8  = %h", cpu_inst.datapath_inst.reg_file_x.registrador[8]);
        $display("x9  (resultado int) = %h", cpu_inst.datapath_inst.reg_file_x.registrador[9]);

        $display("f1  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[1]);
        $display("f2  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[2]);
        $display("f3  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[3]);
        $display("f4  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[4]);
		  $display("f5  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[5]);
        $display("f6  = %h", cpu_inst.datapath_inst.reg_file_f.registrador[6]);
        $display("f7  (resultado fp) = %h", cpu_inst.datapath_inst.reg_file_f.registrador[7]);

        $display("=== Fim da Simulação ===");
        $finish;
    end
    // Monitor de fluxo do pipeline
    always @(posedge CLK) begin
        if (!rst && !we) begin  // Só monitora durante execução (we=0)
            get_instruction_name(cpu_inst.datapath_inst.if_id_instruction, instr_name);

            $display("%4t | PC=%h | instr=%h | %s | ForwardA=%b ForwardFA=%b",
                    $time,
                    cpu_inst.datapath_inst.PC_current,
                    cpu_inst.datapath_inst.if_id_instruction,
                    instr_name,
                    cpu_inst.ForwardA,
                    cpu_inst.ForwardFA);
        end
    end
endmodule
