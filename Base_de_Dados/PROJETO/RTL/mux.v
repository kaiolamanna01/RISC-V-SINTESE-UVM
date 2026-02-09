module mux #(parameter WIDTH = 32) (
    input [WIDTH-1:0] A, B,
    input sel,
    output reg [WIDTH-1:0] Y
);
    always @(*) begin
        case(sel)
            1'b0: Y = A;
            1'b1: Y = B;
            default: Y = A;
        endcase
    end
endmodule