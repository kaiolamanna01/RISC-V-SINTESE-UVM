module multiply(
    input [31:0] iA,    // First input
    input [31:0] iB,    // Second input
    output [31:0] oProd // Product
);

    // Extract fields of A and B
    wire A_s;
    wire [7:0] A_e;
    wire [22:0] A_f;
    wire B_s;
    wire [7:0] B_e;
    wire [22:0] B_f;
    
    assign A_s = iA[31];
    assign A_e = iA[30:23];
    assign A_f = {1'b1, iA[22:1]};
    
    assign B_s = iB[31];
    assign B_e = iB[30:23];
    assign B_f = {1'b1, iB[22:1]};

    // XOR sign bits to determine product sign
    wire oProd_s;
    assign oProd_s = A_s ^ B_s;

    // Multiply the fractions of A and B
    wire [45:0] pre_prod_frac;
    assign pre_prod_frac = A_f * B_f;

    // Add exponents of A and B
    wire [8:0] pre_prod_exp;
    assign pre_prod_exp = A_e + B_e;

    // If top bit of product frac is 0, shift left one
    wire [7:0] oProd_e;
    wire [22:0] oProd_f;
    
    assign oProd_e = pre_prod_frac[45] ? (pre_prod_exp - 9'd126) : (pre_prod_exp - 9'd127);
    assign oProd_f = pre_prod_frac[45] ? pre_prod_frac[44:22] : pre_prod_frac[43:21];

    // Detect underflow
    wire underflow;
    assign underflow = pre_prod_exp < 9'h80;

    // Detect zero conditions (either product frac doesn't start with 1, or underflow)
    assign oProd = underflow    ? 32'b0 :
                   (B_e == 8'd0) ? 32'b0 :
                   (A_e == 8'd0) ? 32'b0 :
                   {oProd_s, oProd_e, oProd_f};

endmodule