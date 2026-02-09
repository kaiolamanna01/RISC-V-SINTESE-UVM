module fp2int(A, B);

    input [31:0] A;
    output [31:0] B;

    wire [31:0] abs_int;
    wire [23:0] m;
    wire [7:0] e;

    assign m = {1'd1, A[22:0]};
    assign e = A[30:23];

    assign abs_int = (A[30:23] >= 127) ? ((m << 7) >> (157 - e)) : 32'd0;
    assign B = (A[31] ? (~abs_int) + 32'd1 : abs_int);
    
endmodule