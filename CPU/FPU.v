//! @brief FPU simples de 32-bits para RISC-V
//! @details Implementa: Soma, Subtracao,
//! Multiplicacao e conversao
//! int2fp e fp2int.
module FPU(A,B,sel,Result);

    input [31:0] A;        //! Operando A
    input [31:0] B;        //! Operando B
    input [4:0] sel;       //! Selecao entre operacoes
    output reg [31:0] Result; //! Resultado

    wire [31:0] res1, res2;
    wire [1:0] res3;
    wire [31:0] res4,res5;
    reg add_sub;

    adder adder_inst
    (
        .a(A),           // input [31:0] a_sig
        .b(B),           // input [31:0] b_sig
        .op(add_sub),    // input op_sig
        .results(res1),  // output [31:0] results_sig
        .compare(res3)   // output compare
    );

    multiply multiply_inst
    (
        .iA(A),         // input [31:0] iA_sig
        .iB(B),         // input [31:0] iB_sig
        .oProd(res2)    // output [31:0] oProd_sig
    );

    fp2int fp2int_inst
    (
        .A(A),          // input [31:0] A_sig
        .B(res5)        // output [31:0] B_sig
    );

    int2fp int2fp_inst
    (
        .A(A),          // input [31:0] A_sig
        .B(res4)        // output [31:0] B_sig
    );

    always@(*)
    begin
        case(sel)
            0: begin add_sub = 1'b0; Result = A; end                         // A
            1: begin add_sub = 1'b0; Result = B; end                         // B
            2: begin add_sub = 1'b0; Result = {~A[31], A[30:0]}; end         // ~A
            3: begin add_sub = 1'b0; Result = {~B[31], B[30:0]}; end         // ~B
            4: begin add_sub = 1'b0; Result = res1; end                      // A+B
            5: begin add_sub = 1'b1; Result = res1; end                      // A-B
            6: begin add_sub = 1'b0; Result = res2; end                      // A*B
            7: begin add_sub = 1'b0; Result = (res3==1)?A:B; end             // min
            8: begin add_sub = 1'b0; Result = (res3==0)?A:B; end             // max
            9: begin add_sub = 1'b0; Result = (res3==2)?1:0; end             // eq
            10: begin add_sub = 1'b0; Result = (res3==1)?1:0; end            // lt
            11: begin add_sub = 1'b0; Result = (res3==1 || res3==2)?1:0; end // le
            12: begin add_sub = 1'b0; Result = A; end                        // mv s-r
            13: begin add_sub = 1'b0; Result = A; end                        // mv r-s
            14: begin add_sub = 1'b0; Result = res4; end                     // cvt s-w
            //15: begin add_sub = 1'b0; Result = A; end                      // cvt s-wu
            15: begin add_sub = 1'b0; Result = res5; end                     // cvt w-s
            //17: begin add_sub = 1'b0; Result = A; end                      // cvt wu-s
            default: begin add_sub = 1'b0; Result = 0; end                   // 0
        endcase
    end
endmodule