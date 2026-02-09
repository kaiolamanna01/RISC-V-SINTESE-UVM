module pc_reg #(parameter bits = 32)(
    input CLK, rst,
    input [bits-1:0] PCNext,
    output reg [bits-1:0] PC
);
    always @(posedge CLK or posedge rst) begin
        if (rst)
            PC <= 0;
        else
            PC <= PCNext;
    end
endmodule