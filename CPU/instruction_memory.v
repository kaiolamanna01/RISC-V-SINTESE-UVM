module instruction_memory #(parameter bits = 32)(
    input              clk_load,
    input              we,
    input  [bits-1:0]  A,
    input  [bits-1:0]  WD,
    output reg [bits-1:0] RD
);
    
    reg [bits-1:0] mem [0:63]; // 64 palavras de memÃ³ria

    // Escrita sÃ­ncrona na borda de subida do clock de carga
    always @(posedge clk_load) begin
        if (we) begin
            mem[A[bits-1:2]] <= WD; // EndereÃ§amento por palavra
        end
    end
    
    // Leitura assÃ­ncrona
    always @(*) begin
        RD = mem[A[bits-1:2]]; // EndereÃ§amento por palavra
    end

endmodule