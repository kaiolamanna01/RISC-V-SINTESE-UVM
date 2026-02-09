module alu #(parameter bits = 32)(
    input [(bits-1):0] SrcA, SrcB, // Operandos
    input [2:0] ALUControl, // Sinal de seleção
    output reg Zero, // Flag: Indica se o ALUResultado é nulo
    output reg [(bits-1):0] ALUResult // Saída da operação
);

always @(*) begin
    case (ALUControl) // Define operação com base no seletor
        3'b000: ALUResult = SrcA + SrcB; // Operação "add"
        3'b001: ALUResult = SrcA - SrcB; // Operação "sub"
        3'b010: ALUResult = SrcA & SrcB; // Operação "and"
        3'b011: ALUResult = SrcA | SrcB; // Operação "or"
        3'b101: ALUResult = SrcA < SrcB; // Operação "slt"
        default: ALUResult = {bits{1'b0}}; // Se seletor não for descrito acima
    endcase

    if (ALUResult == 0) // Flag: Se o seletor não foi identificado (resultado nulo)
        Zero = 1'b1;
    else
        Zero = 1'b0;
end

endmodule
