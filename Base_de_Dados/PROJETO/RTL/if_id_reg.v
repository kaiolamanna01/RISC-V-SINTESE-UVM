module if_id_reg #(parameter bits = 32)(
    input CLK, rst,
    input [bits-1:0] PC_plus_4_if, instruction_if,
    output reg [bits-1:0] PC_plus_4_id, instruction_id
);
    always @(posedge CLK or posedge rst) begin
        if (rst) begin
            PC_plus_4_id <= 0;
            instruction_id <= 0;
        end else begin
            PC_plus_4_id <= PC_plus_4_if;
            instruction_id <= instruction_if;
        end
    end
endmodule