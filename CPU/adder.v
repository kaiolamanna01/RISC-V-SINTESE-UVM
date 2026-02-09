module adder(
    input [31:0] a, b,
    input op,  // 0 = soma, 1 = subtração
    output reg [31:0] results,
    output reg [1:0] compare
);

    reg [7:0] a_exp, b_exp, r_exp;
    reg [24:0] a_m_ext, b_m_ext, r_m_ext; // 25 bits para capturar carry
    reg [23:0] r_m;
    reg a_sign, b_sign, r_sign;
    reg [7:0] exp_diff;
    reg [4:0] shift_amount; 
    reg operation_sub;
    integer i;
    reg found;

    always @(*) begin
        // --- 1. Inicialização e Extração ---
        results = 32'b0;
        compare = 2'b00;
        a_sign = a[31];
        a_exp = a[30:23];
        b_sign = b[31];
        b_exp = b[30:23];
        operation_sub = op;
        
        // --- 2. Casos Especiais (Zero e Infinito) ---
        if (a_exp == 8'hFF || b_exp == 8'hFF) begin
            results = a;
        end
        else if (a_exp == 0 && a[22:0] == 0) begin
            if (operation_sub) results = {~b_sign, b[30:0]};
            else results = b;
        end
        else if (b_exp == 0 && b[22:0] == 0) begin
            results = a;
        end
        else begin
            // --- 3. Preparação das Mantissas (25 bits) ---
            // Adicionamos um bit extra à esquerda para o carry da soma
            a_m_ext = (a_exp == 0) ? {2'b00, a[22:0]} : {2'b01, a[22:0]};
            b_m_ext = (b_exp == 0) ? {2'b00, b[22:0]} : {2'b01, b[22:0]};
            
            // Inverte o sinal de B se for subtração
            b_sign = operation_sub ? ~b_sign : b_sign;

            // --- 4. Alinhamento de Expoentes ---
            if (a_exp > b_exp) begin
                exp_diff = a_exp - b_exp;
                b_m_ext = b_m_ext >> (exp_diff > 24 ? 24 : exp_diff);
                r_exp = a_exp;
            end else begin
                exp_diff = b_exp - a_exp;
                a_m_ext = a_m_ext >> (exp_diff > 24 ? 24 : exp_diff);
                r_exp = b_exp;
            end

            // --- 5. Soma/Subtração Efetiva ---
            if (a_sign == b_sign) begin
                r_m_ext = a_m_ext + b_m_ext;
                r_sign = a_sign;
            end else begin
                if (a_m_ext >= b_m_ext) begin
                    r_m_ext = a_m_ext - b_m_ext;
                    r_sign = a_sign;
                end else begin
                    r_m_ext = b_m_ext - a_m_ext;
                    r_sign = b_sign;
                end
            end

            // --- 6. Normalização ---
            if (r_m_ext == 0) begin
                results = 32'b0;
                r_exp = 0;
            end else begin
                if (r_m_ext[24]) begin 
                    // Carry detectado (ex: 1.1 + 1.1 = 11.0)
                    r_m = r_m_ext[24:1];
                    r_exp = r_exp + 1;
                end else if (r_m_ext[23]) begin
                    // Já está normalizado
                    r_m = r_m_ext[23:0];
                end else begin
                    // Underflow (precisa de shift para a esquerda)
                    found = 0;
                    shift_amount = 0;
                    for (i = 22; i >= 0; i = i - 1) begin
                        if (!found && r_m_ext[i]) begin
                            shift_amount = 23 - i;
                            found = 1;
                        end
                    end
                    
                    if (r_exp > shift_amount) begin
                        r_m_ext = r_m_ext << shift_amount;
                        r_exp = r_exp - shift_amount;
                    end else begin
                        r_m_ext = 0;
                        r_exp = 0;
                    end
                    r_m = r_m_ext[23:0];
                end

                // --- 7. Montagem Final e Overflow ---
                if (r_exp >= 8'hFF) results = {r_sign, 8'hFF, 23'b0};
                else if (r_exp == 0) results = 32'b0;
                else results = {r_sign, r_exp[7:0], r_m[22:0]};
            end
        end
        
        // --- 8. Lógica de Comparação (Saída auxiliar) ---
        if (a_exp > b_exp) compare = 2'b00;
        else if (a_exp < b_exp) compare = 2'b01;
        else compare = (a[22:0] > b[22:0]) ? 2'b00 : (a[22:0] < b[22:0]) ? 2'b01 : 2'b10;
    end
endmodule