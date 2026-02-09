module register_file_f #(
    parameter data_bits = 32,     // 32 bits de dados (IEEE 754)
    parameter address_bits = 5,   // 5 bits de endereço
    parameter registers = 32      // 32 registros (f0-f31)
)(
    input CLK, rst,               // Sinais de clock e reset
    input WE3,                    // Enable de escrita
    input [(address_bits-1):0] A1, A2, // Portas de endereço de leitura 1 e 2
    input [(address_bits-1):0] A3,     // Porta de endereço de escrita
    input [(data_bits-1):0] WD3,       // Entrada da escrita de dados
    output reg [(data_bits-1):0] RD1,  // Saída de leitura de dados 1
    output reg [(data_bits-1):0] RD2   // Saída de leitura de dados 2
);

    integer i; // Variável auxiliar para inicialização
    // Notação matricial (32 endereços de 32 bits)
    reg [(data_bits-1):0] registrador [0:(registers-1)];

    // Inicialização com reset
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            // Inicializa todos os registradores com zero (0x00000000)
            for (i = 0; i < registers; i = i + 1)
                registrador[i] <= 0;
        end
        else if (WE3 == 1) begin
            // Escreve WD3 no endereço A3 se a escrita está habilitada
            // Registrador f0 é read-only (sempre zero) - conforme especificação RISC-V
            if (A3 != 0) begin
                registrador[A3] <= WD3;
            end
        end
    end

    // Leitura assíncrona
    always @(*) begin
        // Registrador f0 é sempre zero (read-only)
        if (A1 == 0)
            RD1 = 0;
        else
            RD1 = registrador[A1];
        
        if (A2 == 0)
            RD2 = 0;
        else
            RD2 = registrador[A2];
    end

endmodule