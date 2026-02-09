// Módulo simples para detecção de hazards (para bolhas manuais)
module hazard_detection (
    input [4:0] rs1_id, rs2_id,
    input [4:0] rd_ex, rd_mem,
    input RegWrite_ex, RegWrite_mem,
    input FPURegWrite_ex, FPURegWrite_mem,
    output stall
);
    
    // Detecção básica de hazards RAW
    assign stall = ((rs1_id == rd_ex) & RegWrite_ex) |
                   ((rs2_id == rd_ex) & RegWrite_ex) |
                   ((rs1_id == rd_mem) & RegWrite_mem) |
                   ((rs2_id == rd_mem) & RegWrite_mem) |
                   // Hazards FPU
                   ((rs1_id == rd_ex) & FPURegWrite_ex) |
                   ((rs2_id == rd_ex) & FPURegWrite_ex) |
                   ((rs1_id == rd_mem) & FPURegWrite_mem) |
                   ((rs2_id == rd_mem) & FPURegWrite_mem);
    
endmodule