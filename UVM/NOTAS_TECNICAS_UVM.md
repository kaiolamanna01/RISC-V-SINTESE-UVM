# Notas Técnicas — Ambiente UVM (CPU Pipeline MIPS + FPU)

## Objetivo
Aprimorar cobertura funcional, visibilidade do scoreboard e controle de execução com sequências CRV direcionadas.

## Principais Melhorias
- Covergroups com bins significativos para `mem_addr`, `mem_wdata` e alinhamento.
- Sequência CRV inteligente para atingir bins críticos.
- Scoreboard com verbosidade configurável e status periódico.
- Execução paralela opcional das sequências.
- Loop de cobertura por meta (coverage-driven).
- Assertions básicas de sanidade na interface.
- Relatório HTML simples de cobertura.

## Arquivos Alterados
- dut_cov.sv
- dut_seq_lib.sv
- dut_scoreboard.sv
- dut_extended_test.sv
- dut_if.sv

## Flags de Execução
- `+SCOREBOARD_VERBOSE` — logs detalhados de match
- `+NUM_TRANS=<N>` — tamanho de execução (afeta CRV inteligente)
- `+NO_BASIC` — desativa sequência base
- `+NO_CRV` — desativa sequências CRV
- `+STRESS_ONLY` — executa apenas stress
- `+PARALLEL_SEQ` — executa CRV/stress em paralelo
- `+COV_LOOP` — habilita loop de cobertura
- `+COV_GOAL=<N>` — meta de cobertura (default 90)
- `+COV_MAX_ITERS=<N>` — iterações máximas
- `+COV_HTML` — gera `cov_report.html`

## Observações
- A memória observada usa índice `mem_addr[31:2]` (64 words). Os bins foram ajustados para refletir esse espaço.
- As sequências CRV priorizam endereços e dados críticos para cobertura.
- O loop de cobertura não reinicia o DUT; apenas repete a sequência estendida.
