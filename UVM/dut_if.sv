interface dut_if(input logic clk, input logic rst, input logic clk_load);
    // Carregamento de instruções
    logic        we;
    logic [31:0] ADDR_INST;
    logic [31:0] Instrucoes;

    // Observabilidade de memória de dados
    logic        mem_we;
    logic        mem_read;
    logic [31:0] mem_addr;
    logic [31:0] mem_rdata;
    logic [31:0] Dado;

    // Observabilidade do fluxo de execução
    logic [31:0] pc;
    logic [31:0] instr;
    logic        branch_ctrl;
    logic        branch_taken;
    logic        jump;
    logic [31:0] alu_result;
    logic [31:0] fpu_result;
    logic [31:0] wb_data_x;
    logic [31:0] wb_data_f;
    logic [4:0]  rd_wb;
    logic        regwrite_wb;
    logic        fpuregwrite_wb;
    logic [1:0]  forwardA;
    logic [1:0]  forwardB;
    logic [1:0]  forwardFA;
    logic [1:0]  forwardFB;
    logic        stall;

    // ---------------------------------------------------------
    // 1. Definição das Propriedades (SVA)
    // ---------------------------------------------------------
    
    // Propriedade: Se houver leitura ou escrita, o endereço não pode ser X ou Z
    property p_mem_addr_known;
        @(posedge clk) disable iff (rst)
        (mem_we || mem_read) |-> !$isunknown(mem_addr);
    endproperty

    // Propriedade: Os sinais de controle não podem ser X ou Z
    property p_mem_ctrl_known;
        @(posedge clk) disable iff (rst)
        !$isunknown(mem_we) && !$isunknown(mem_read);
    endproperty
    
    // ---------------------------------------------------------
    // 3. Contadores para o Resumo Final (Opcional)
    // ---------------------------------------------------------
    int unsigned mem_addr_xz_count = 0;
    int unsigned mem_ctrl_xz_count = 0;

    always @(posedge clk) begin
        if (!rst) begin
            // Checagem de endereço
            if ((mem_we === 1'b1 || mem_read === 1'b1) && $isunknown(mem_addr)) begin
                mem_addr_xz_count++;
            end
            // Checagem de controle
            if ($isunknown(mem_we) || $isunknown(mem_read)) begin
                mem_ctrl_xz_count++;
            end
        end
    end

    final begin
        $display("\n--- [ASSERT_SUMMARY] ---");
        $display("mem_addr X/Z count = %0d", mem_addr_xz_count);
        $display("mem_we/mem_read X/Z count = %0d", mem_ctrl_xz_count);
        $display("------------------------\n");
    end

endinterface