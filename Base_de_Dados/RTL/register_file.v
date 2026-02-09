module register_file #(
    parameter data_bits = 32, // 32 bits de dados
    parameter address_bits = 5, // 5 bits de endereço
    parameter registers = 32 // 32 registros
)(
    input CLK,rst, // Sinais de clock e reset
    input WE3, // Enable de escrita
    input [(address_bits-1):0] A1,A2, // Portas de endereço de leitura 1 e 2
    input [(address_bits-1):0] A3, // Porta de endereço de escrita
    input [(data_bits-1):0] WD3,// Entrada da escrita de dados
    output reg [(data_bits-1):0] RD1,// Saída de leitura de dados 1
    output reg [(data_bits-1):0] RD2 // Saída de leitura de dados 2
);

integer i; // Variável auxiliar para inicializar cada endereço com valor nulo
// Notação matricial (32 endereços de 32 bits)
reg [(data_bits-1):0] registrador [0:(data_bits-1)]; // Registrador interno


always @(posedge CLK or posedge rst) begin
    if (rst) // Inicializa registrador com valores nulos
        for (i=0;i<32;i=i+1)
            registrador[i] <= 0;
    else if (WE3 == 1) begin // Escreve WD3 no endereço A3 se a escrita está habilitada
       registrador[A3] <= WD3;
    end
end

always @(*) begin
    
    RD1 <= registrador[A1]; // Leitura 1 assíncrona
    RD2 <= registrador[A2]; // Leitura 2 assíncrona
end

endmodule