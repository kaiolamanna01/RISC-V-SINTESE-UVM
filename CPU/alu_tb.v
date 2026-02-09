module alu_tb;

parameter bits = 32;

reg [(bits-1):0] SrcA, SrcB;
reg [2:0] ALUControl;
wire Zero;
wire [(bits-1):0] ALUResult;
integer errors = 0;

alu #bits alu (
    .SrcA(SrcA),
    .SrcB(SrcB), 
    .ALUControl(ALUControl),
    .Zero(Zero),
    .ALUResult(ALUResult)
);
initial begin
    $display("\n\nTempo | SrcA      | SrcB      | ALUControl | ALUResult | Esperado  | Zero | ZeroEsp");
    $display("------|-----------|-----------|------------|-----------|-----------|------|--------");
    
    SrcA = 32'h12345678; SrcB = 32'h87654321; ALUControl = 3'b000; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA+SrcB, Zero, (SrcA+SrcB)==0);
    if (ALUResult != (SrcA+SrcB) || Zero != ((SrcA+SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h00000000; SrcB = 32'h00000000; ALUControl = 3'b000; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA+SrcB, Zero, (SrcA+SrcB)==0);
    if (ALUResult != (SrcA+SrcB) || Zero != ((SrcA+SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'hFFFFFFFF; SrcB = 32'h12345678; ALUControl = 3'b001; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA-SrcB, Zero, (SrcA-SrcB)==0);
    if (ALUResult != (SrcA-SrcB) || Zero != ((SrcA-SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h12345678; SrcB = 32'h12345678; ALUControl = 3'b001; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA-SrcB, Zero, (SrcA-SrcB)==0);
    if (ALUResult != (SrcA-SrcB) || Zero != ((SrcA-SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'hAAAAAAAA; SrcB = 32'h55555555; ALUControl = 3'b010; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA&SrcB, Zero, (SrcA&SrcB)==0);
    if (ALUResult != (SrcA&SrcB) || Zero != ((SrcA&SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'hF0F0F0F0; SrcB = 32'h0F0F0F0F; ALUControl = 3'b010; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA&SrcB, Zero, (SrcA&SrcB)==0);
    if (ALUResult != (SrcA&SrcB) || Zero != ((SrcA&SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h12345678; SrcB = 32'h87654321; ALUControl = 3'b011; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA|SrcB, Zero, (SrcA|SrcB)==0);
    if (ALUResult != (SrcA|SrcB) || Zero != ((SrcA|SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h00000000; SrcB = 32'h00000000; ALUControl = 3'b011; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA|SrcB, Zero, (SrcA|SrcB)==0);
    if (ALUResult != (SrcA|SrcB) || Zero != ((SrcA|SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h00000005; SrcB = 32'h0000000A; ALUControl = 3'b101; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA<SrcB, Zero, (SrcA<SrcB)==0);
    if (ALUResult != (SrcA<SrcB) || Zero != ((SrcA<SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h0000000A; SrcB = 32'h00000005; ALUControl = 3'b101; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA<SrcB, Zero, (SrcA<SrcB)==0);
    if (ALUResult != (SrcA<SrcB) || Zero != ((SrcA<SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h12345678; SrcB = 32'h12345678; ALUControl = 3'b101; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, SrcA<SrcB, Zero, (SrcA<SrcB)==0);
    if (ALUResult != (SrcA<SrcB) || Zero != ((SrcA<SrcB)==0)) errors = errors + 1;
    
    SrcA = 32'h12345678; SrcB = 32'h87654321; ALUControl = 3'b100; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, 32'h00000000, Zero, 1'b1);
    if (ALUResult != 32'h00000000 || Zero != 1'b1) errors = errors + 1;
    
    SrcA = 32'hFFFFFFFF; SrcB = 32'hFFFFFFFF; ALUControl = 3'b110; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, 32'h00000000, Zero, 1'b1);
    if (ALUResult != 32'h00000000 || Zero != 1'b1) errors = errors + 1;
    
    SrcA = 32'h12345678; SrcB = 32'h87654321; ALUControl = 3'b111; #10;
    $display("%4dns | %08h  | %08h  | %3b        | %08h  | %08h  | %b    | %b", $time, SrcA, SrcB, ALUControl, ALUResult, 32'h00000000, Zero, 1'b1);
    if (ALUResult != 32'h00000000 || Zero != 1'b1) errors = errors + 1;
    
    if (errors != 0)
        $display("\n\n%d testes falharam\n", errors);
    else
        $display("\n\nTodos os testes passaram\n");

    $finish;
end

endmodule