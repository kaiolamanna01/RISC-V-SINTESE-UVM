//! @brief Unidade de Controlo de Forwarding para registradores X e F
module fowarding_control (
   // Registradores inteiros no estágio IDEX
   input  [4:0] rs1_IDEX,
   input  [4:0] rs2_IDEX,

   // Registradores FLOAT no estágio IDEX
   input  [4:0] frs1_IDEX,
   input  [4:0] frs2_IDEX,

   // Registrador de destino no EX/MEM (tanto para X quanto para F)
   input  [4:0] rd_EXMEM,
   input        RegWrite_EXMEM,
   input        FPURegWrite_EXMEM,

   // Registrador de destino no MEM/WB (tanto para X quanto para F)
   input  [4:0] rd_MEMWB,
   input        RegWrite_MEMWB,
   input        FPURegWrite_MEMWB,

   // Saídas
   output reg [1:0] ForwardA,
   output reg [1:0] ForwardB,
   output reg [1:0] ForwardFA,
   output reg [1:0] ForwardFB
);

   always @(*) begin

       // ---------------------------------------------------
       // Forwarding para registradores inteiros (X)
       // ---------------------------------------------------
       
       // Risco EX/MEM -> ID/EX
       if (RegWrite_EXMEM && (rd_EXMEM != 0) && (rd_EXMEM == rs1_IDEX))
           ForwardA = 2'b10;
       // Risco MEM/WB -> ID/EX (evita encaminhar se já foi pego pelo EX/MEM)
       else if (RegWrite_MEMWB && (rd_MEMWB != 0) && (rd_MEMWB == rs1_IDEX))
           ForwardA = 2'b01;
       else
           ForwardA = 2'b00;

       // Risco EX/MEM -> ID/EX
       if (RegWrite_EXMEM && (rd_EXMEM != 0) && (rd_EXMEM == rs2_IDEX))
           ForwardB = 2'b10;
       // Risco MEM/WB -> ID/EX
       else if (RegWrite_MEMWB && (rd_MEMWB != 0) && (rd_MEMWB == rs2_IDEX))
           ForwardB = 2'b01;
       else
           ForwardB = 2'b00;

       // ---------------------------------------------------
       // Forwarding para registradores FLOAT (F)
       // ---------------------------------------------------
       
       // Risco EX/MEM -> ID/EX
       if (FPURegWrite_EXMEM && (rd_EXMEM != 0) && (rd_EXMEM == frs1_IDEX))
           ForwardFA = 2'b10;
       // Risco MEM/WB -> ID/EX
       else if (FPURegWrite_MEMWB && (rd_MEMWB != 0) && (rd_MEMWB == frs1_IDEX))
           ForwardFA = 2'b01;
       else
           ForwardFA = 2'b00;

       // Risco EX/MEM -> ID/EX
       if (FPURegWrite_EXMEM && (rd_EXMEM != 0) && (rd_EXMEM == frs2_IDEX))
           ForwardFB = 2'b10;
       // Risco MEM/WB -> ID/EX
       else if (FPURegWrite_MEMWB && (rd_MEMWB != 0) && (rd_MEMWB == frs2_IDEX))
           ForwardFB = 2'b01;
       else
           ForwardFB = 2'b00;

   end
endmodule