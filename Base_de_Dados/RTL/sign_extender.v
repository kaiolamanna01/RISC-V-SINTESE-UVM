module sign_extender #(parameter bits = 32)(
    input [31:7] Instr,
    input [1:0] ImmSrc,
    output reg [bits-1:0] ImmExt
);
    always @(*) begin
        case(ImmSrc)
            2'b00: ImmExt = {{20{Instr[31]}}, Instr[31:20]}; // I-type
            2'b01: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]}; // S-type
            2'b10: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0}; // B-type
            2'b11: ImmExt = {Instr[31:12], 12'b0}; // U-type (LUI / AUIPC)
            
            default: ImmExt = 0;
        endcase
    end
endmodule