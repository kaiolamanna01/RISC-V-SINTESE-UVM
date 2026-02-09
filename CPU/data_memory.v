module data_memory #(parameter bits = 32)(
    input CLK, rst,
    input WE,
    input [bits-1:0] A, WD,
    output reg [bits-1:0] RD
);
    
    reg [bits-1:0] mem [0:63];
    integer i; // Declarar fora do initial
    
    initial begin
        mem[0] = 32'h0001199A;  // val1
        mem[1] = 32'h00028000;  // val2
        mem[2] = 32'hFFFC4000;  // val3
        mem[3] = 32'h00042000;  // val4
        mem[4] = 32'h00000000;  // result_fp
        mem[5] = 32'h00000000;  // result_int
        
        // Loop Verilog compatível
        for (i = 4; i < 64; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
    end
    
    always @(*) begin
        RD = mem[A[31:2]];
    end
    
    always @(posedge CLK) begin
        if (WE) begin
            mem[A[31:2]] <= WD;
        end
    end

endmodule