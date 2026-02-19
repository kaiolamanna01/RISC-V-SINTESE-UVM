# Microarquitetura RISC-V Pipelined com Forwarding e RV32F

Este repositório contém o projeto, a implementação RTL, o ambiente de verificação e a análise de síntese de uma microarquitetura RISC-V em pipeline de 5 estágios, desenvolvida como Projeto Avaliativo Final para o Instituto de Engenharia de Sistemas e Tecnologia da Informação da Universidade Federal de Itajubá (UNIFEI).

## 💻 Sobre o Projeto

O objetivo principal deste projeto é construir uma microarquitetura coerente e validada funcionalmente que equilibra simplicidade e desafios reais de hardware. O design estende o pipeline clássico com dois recursos avançados:

* 
**Forwarding (Encaminhamento de Dados):** Implementado para reduzir penalidades de dependências RAW, evitando *stalls* desnecessários quando um dado já foi produzido em um estágio à frente.


* 
**Extensão RV32F (Parcial):** Adiciona suporte a instruções de ponto flutuante via uma Unidade de Ponto Flutuante (FPU) dedicada e um banco de registradores `F`.



O processador opera com palavras de 32 bits e suporta um subconjunto de instruções RV32I (operações aritméticas/lógicas, acesso à memória, desvios) e RV32F (operações e conversões de ponto flutuante, exceto divisão).

## ⚙️ Arquitetura

O processador implementa os 5 estágios clássicos de pipeline:

* 
**IF (Instruction Fetch):** Responsável pela seleção do PC, leitura da instrução e cálculo de .


* 
**ID (Instruction Decode):** Realiza a decodificação, leitura dos bancos de registradores (inteiros e float) e extensão de imediatos.


* 
**EX (Execute):** Executa as operações aritméticas/lógicas (ALU) ou float (FPU) e calcula os destinos de *branches*.


* 
**MEM (Memory):** Acessa a memória de dados para operações de *load* e *store*.


* 
**WB (Write Back):** Seleciona o resultado (entre ALU, Memória ou FPU) e escreve no banco de registradores correspondente.



### Destaques do Design

* 
**Bancos de Registradores (Sincronismo Oposto):** As escritas nos bancos `X` e `F` ocorrem na borda de descida do clock, enquanto a captura no pipeline ocorre na borda de subida, mitigando problemas de condição de corrida (*race conditions*).


* 
**FPU:** Atua como uma "ALU especializada" para operandos IEEE-754 de 32 bits, com suporte a soma, subtração, multiplicação e conversões.


* 
**Forwarding Unit:** Compara registradores fonte em `ID/EX` com destinos em `EX/MEM` e `MEM/WB`, selecionando a fonte de dados mais recente para os operandos.



## 🧪 Simulação e Verificação

A validação do projeto utilizou duas metodologias complementares:

1. **Testbench Tradicional (`cpu_tb.v`):**
* Realiza testes incrementais validando blocos isolados, *datapath* e fluxo completo.


* O fluxo de teste separa a carga do programa na memória de instruções () da execução determinística ().


* Valida a execução ao final do programa imprimindo o estado final dos registradores (`x` e `f`).




2. **Verificação UVM (Universal Verification Methodology):**
* Implementada para cobrir a crescente complexidade dos múltiplos domínios (inteiro/float) e *hazards* de pipeline.


* Utiliza *sequences* geradas automaticamente e guiadas (como `dut_data_pattern_seq` e `dut_addr_sweep_seq`) para injetar estímulos.


* O *Scoreboard* automatizado monitora transações de memória, checando o comportamento esperado sem registrar *mismatches* em 68.000 transações.


* Atingiu uma cobertura funcional de arquitetura consolidada de 73.58%.





## 📊 Síntese e Resultados (PPA)

O design foi sintetizado no **Cadence Genus** para avaliar Power, Performance e Area (PPA) utilizando constraints restritivas (incertezas, tempos de transição e latências).

Os testes avaliaram três cenários de operação (30ns, 20ns e 10ns):

* 
**33.33 MHz (30ns):** Ampla margem de *slack* (~9945.9 ps), com os caminhos críticos dominados por datapath e banco de registradores inteiros.


* 
**100 MHz (10ns):** O circuito operou no seu limite térmico/temporal de simulação, com o *slack* crítico caindo para próximo de zero (0.3 ps). Neste cenário máximo:


* 
**Potência Estimada:** ~1.329 mW.


* 
**Área Total:** 70.629 cell area.


* O caminho crítico migrou para blocos associados à FPU e à lógica complexa de seleção do Forwarding.
