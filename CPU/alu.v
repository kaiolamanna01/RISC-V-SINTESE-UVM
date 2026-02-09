module alu #(parameter bits = 32)(
    input [(bits-1):0] SrcA, SrcB, // Operandos
    input [2:0] ALUControl, // Sinal de seleÃ§Ã£o
    output reg Zero, // Flag: Indica se o ALUResultado Ã© nulo
    output reg [(bits-1):0] ALUResult // SaÃ­da da operaÃ§Ã£o
);

always @(*) begin
    case (ALUControl) // Define operaÃ§Ã£o com base no seletor
        3'b000: ALUResult = SrcA + SrcB; // OperaÃ§Ã£o "add"
        3'b001: ALUResult = SrcA - SrcB; // OperaÃ§Ã£o "sub"
        3'b010: ALUResult = SrcA & SrcB; // OperaÃ§Ã£o "and"
        3'b011: ALUResult = SrcA | SrcB; // OperaÃ§Ã£o "or"
        3'b101: ALUResult = SrcA < SrcB; // OperaÃ§Ã£o "slt"
        default: ALUResult = {bits{1'b0}}; // Se seletor nÃ£o for descrito acima
    endcase

    if (ALUResult == 0) // Flag: Se o seletor nÃ£o foi identificado (resultado nulo)
        Zero = 1'b1;
    else
        Zero = 1'b0;
end

endmodule
