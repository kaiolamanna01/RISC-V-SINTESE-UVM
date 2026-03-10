# Microarquitetura RISC-V Pipelined com Forwarding e RV32F

**Autor:** Kaio Pasqual Nunes Lamanna

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Conjunto de Instruções](#-conjunto-de-instruções)
- [Arquitetura](#-arquitetura)
  - [Pipeline de 5 Estágios](#pipeline-de-5-estágios)
  - [Forwarding Unit](#forwarding-unit)
  - [FPU e Extensão RV32F](#fpu-e-extensão-rv32f)
  - [Bancos de Registradores](#bancos-de-registradores-x-e-f)
  - [Memória de Instrução](#memória-de-instrução)
- [Simulação e Verificação](#-simulação-e-verificação)
  - [Testbench Tradicional](#testbench-tradicional-cpu_tbv)
  - [Verificação UVM](#verificação-uvm)
- [Trabalhos Futuros](#-trabalhos-futuros)

---

## 💡 Sobre o Projeto

Este repositório implementa uma **microarquitetura RISC-V em pipeline de 5 estágios** (IF, ID, EX, MEM, WB), estendida com dois recursos avançados:

- **Forwarding (Encaminhamento de Dados):** resolve dependências RAW sem stalls desnecessários, encaminhando resultados diretamente dos registradores de pipeline quando o dado já foi produzido em um estágio à frente.
- **Extensão RV32F (parcial):** adiciona suporte a instruções de ponto flutuante com banco de registradores dedicado `F` e FPU integrada ao pipeline e ao write-back.

O projeto cobre três dimensões complementares:

| Dimensão | Objetivo |
|---|---|
| **Correção funcional** | Resultados corretos para programas de teste (inteiro e ponto flutuante) |
| **Sintetizabilidade** | RTL sem construções não-sintetizáveis; portas externas evitam otimizações indevidas |
| **Mensurabilidade** | Relatórios confiáveis de área, potência e timing para três cenários de frequência |

---

## 📐 Conjunto de Instruções

O processador opera com palavras de **32 bits**, endereçamento alinhado a múltiplos de 4 bytes.

### RV32I (subconjunto)
- Operações aritméticas e lógicas (tipos R e I): `ADD`, `ADDI`, `SUB`, `AND`, `OR`, `SLT`, `LUI`
- Acesso à memória: `LW`, `SW`
- Desvios condicionais: `BEQ`

### RV32F (parcial)
| Instrução | Descrição |
|---|---|
| `FADD.S`, `FSUB.S`, `FMUL.S` | Operações aritméticas de ponto flutuante |
| `FLE.S`, `FLT.S` | Comparações float |
| `FCVT.S.W`, `FCVT.W.S` | Conversões inteiro ↔ float |
| `FMV.W.X`, `FMV.X.W` | Movimentações entre domínios |
| `FLW` | Load de valor float da memória |

> **Limitação conhecida:** `FDIV.S` (divisão float) não está implementada. Exceções, CSRs, instruções atômicas e acesso desalinhado foram deliberadamente excluídos do escopo.

---

## ⚙️ Arquitetura

### Pipeline de 5 Estágios

```
IF → ID → EX → MEM → WB
```

| Estágio | Função |
|---|---|
| **IF** — Instruction Fetch | Seleção do PC, leitura da instrução, cálculo de PC+4 |
| **ID** — Instruction Decode | Decodificação, leitura dos bancos X e F, extensão de imediatos, geração de sinais de controle |
| **EX** — Execute | Execução ALU (inteiro) ou FPU (float), cálculo do destino de branches |
| **MEM** — Memory | Acesso à memória de dados para loads e stores |
| **WB** — Write Back | Seleção do resultado (ALU / Memória / FPU) e escrita no banco correto (X ou F) |

O top-level `cpu` instancia os módulos `control` (decodificação) e `datapath` (caminho de dados, registradores de pipeline e memórias). O encaminhamento é gerenciado por `fowarding_control`, que produz os sinais `ForwardA`/`ForwardB` (inteiro) e `ForwardFA`/`ForwardFB` (float).

> **Hazards de controle (branches)** são tratados de forma simplificada. Os programas de teste devem minimizar efeitos de especulação incorreta.

### Forwarding Unit

Dependências RAW ocorrem quando uma instrução lê um registrador que ainda está sendo escrito por uma instrução anterior no pipeline. Sem forwarding, seriam necessários stalls para aguardar o write-back.

**Exemplo clássico:**
```asm
add x5, x1, x2   # resultado de x5 disponível ao fim de EX
sub x6, x5, x3   # precisa de x5 quando está em EX — antes do WB
```

A unidade `fowarding_control` compara os registradores fonte em `ID/EX` com os destinos em `EX/MEM` e `MEM/WB`, gerando seletores de 2 bits:

| Seletor | Origem |
|---|---|
| `2'b10` | Encaminhar de EX/MEM (resultado mais recente) |
| `2'b01` | Encaminhar de MEM/WB (resultado a ser escrito) |
| `2'b00` | Usar valor original do registrador (ID/EX) |

A prioridade é sempre dada à fonte mais recente (EX/MEM > MEM/WB). O dado de store (`write_data_EXMEM`) também usa o valor encaminhado, evitando erros em sequências como `add x1,...; sw x1,...`.

> **Load-use hazard:** o `hazard_detection` existe no repositório, mas não está integrado ao controle de PC/registradores de pipeline na versão atual. Para sequências `LW` seguidas de uso imediato, recomenda-se inserir uma instrução independente entre as duas (workaround por programação de teste).

### FPU e Extensão RV32F

A FPU opera como uma **"ALU especializada"** para operandos IEEE-754 de 32 bits (single precision), selecionando operações via `sel` (5 bits):

- Soma/subtração (`adder`)
- Multiplicação (`multiply`)
- Conversões (`int2fp`, `fp2int`)

O resultado da FPU percorre os registradores de pipeline como qualquer outro valor (`FPU → EX/MEM → MEM/WB`), contribuindo significativamente para o timing nos cenários mais rápidos (10 ns).

**Write-back com 3 fontes (banco inteiro X):**

```
ResultSrc → mux(ALU, MEM) → mux(anterior, FPU) → banco X
```

Essa estrutura suporta `FCVT.W.S` e `FMV.X.W`, que escrevem resultado float no banco inteiro.

**Write-back float (banco F):**

O mux seleciona entre resultado da FPU e dado lido da memória, habilitando `FLW` quando `FPUResultSrc_MEMWB=1`.

### Bancos de Registradores X e F

Para evitar race conditions entre forwarding e escrita/leitura no mesmo ciclo:

- **Escrita** nos bancos X e F ocorre na **borda de descida** do clock (`CLK(!CLK)`)
- **Captura** dos registradores de pipeline ocorre na **borda de subida**
- **Leituras** são assíncronas

Essa separação temporal garante clareza na depuração: se um valor escrito no ciclo anterior não aparece em ID, o problema está no controle ou na seleção do write-back, não em uma race de clock.

### Memória de Instrução

Implementada como **RAM de 64 palavras** com endereçamento por palavra via `A[31:2]`:

- **Escrita** síncrona na borda de subida de `clk_load` (quando `we=1`) — fase de carga
- **Leitura** assíncrona — fase de execução (`we=0`), operando como ROM

Portas externas expostas pelo módulo `cpu`:

| Porta | Largura | Função |
|---|---|---|
| `Instrucoes` | 32 bits | Dados de instrução para escrita |
| `ADDR_INST` | 32 bits | Endereço de carga |
| `clk_load` | — | Clock dedicado à escrita |
| `we` | — | Habilitação de escrita |

Sinais de observabilidade (essenciais para UVM e síntese): `Dado`, `mem_we`, `mem_read`, `mem_addr`, `mem_rdata`.

---

## 🧪 Simulação e Verificação

### Testbench Tradicional (`cpu_tb.v`)

Segue uma metodologia **incremental**:

1. Validação de blocos isolados (ALU, memórias, registradores)
2. Integração no datapath (coreografia do pipeline)
3. Sistema completo no `cpu` (controle global, PC, branch, write-back)

**Fluxo de execução:**

```
Carga (we=1, clk_load ativo, CLK parado)
         ↓
Execução (we=0, pipeline determinístico)
         ↓
Impressão do estado final dos registradores X e F
```

**Exemplo de saída:**

```
=== Estado Final dos Registradores ===
x5 = 0001199a
x6 = 00028000
x7 = fffc4000
x8 = 00042000
x9 (resultado int) = 00000003
f1 = 3f8ccd00
f2 = 40200000
f3 = c0700000
f4 = 40840000
f5 = 40666680
f6 = be199800
f7 (resultado fp) = 407e6680
```

**Casos de teste cobertos:**

- ALU inteira: `ADD/ADDI`, `SUB`, `AND`, `OR`, `SLT`
- Memória: sequências `SW`→`LW` para mesmo e diferentes endereços
- Hazards: dependências consecutivas RAW
- RV32F: `FADD.S`, `FSUB.S`, `FMUL.S`, conversões `FCVT`

### Verificação UVM

A complexidade crescente do pipeline (forwarding + RV32F + múltiplos domínios) motivou uma infraestrutura UVM completa.

**Topologia do ambiente:**

| Arquivo | Responsabilidade |
|---|---|
| `tb_top.sv` | Topo estático; instancia DUT e gera clocks/reset |
| `tb_package.sv` | Pacote com todas as classes UVM do ambiente |
| `dut_if.sv` | Interface física com asserts de integridade |
| `dut_cfg.sv` | Objeto de configuração (vif, flags de cobertura) |
| `dut_txn.sv` | Transações `TXN_LOAD`, `TXN_RUN`, `TXN_MEM_EVT` |
| `dut_driver.sv` | Aplica estímulos físicos via interface virtual |
| `dut_monitor.sv` | Observa sinais do DUT e publica via `analysis_port` |
| `dut_predictor.sv` | Modelo de referência (memória shadow) |
| `dut_scoreboard.sv` | Compara transações expected vs actual |
| `dut_cov.sv` | Cobertura funcional sobre eventos de memória |
| `dut_seq_lib.sv` | Sequências direcionadas e aleatórias |

**Sequências disponíveis:**

- `dut_data_pattern_seq` — padrões relevantes incluindo valores float especiais (NaN/Inf/±0)
- `dut_addr_sweep_seq` — varredura de endereços para cobrir faixas e limites
- `dut_mixed_ops_seq` — mistura instruções com offsets randomizados

---

## 🔭 Trabalhos Futuros

- [ ] **Integração formal do `hazard_detection`** para stalls/flush automáticos em load-use hazard e demais casos não cobertos por forwarding
- [ ] **Expansão da ISA** — suporte a exceções, CSRs, `FDIV.S` e acesso desalinhado
- [ ] **Predictor arquitetural completo** — modelo de referência com PC, registradores X e F para checagem mais profunda no scoreboard UVM
- [ ] **Estimativa de potência com atividade real** — geração de VCD/SAIF a partir de programas representativos para comparar impacto de cargas ALU vs memória vs FPU
- [ ] **Pipeline interno na FPU** — reduzir atraso combinacional em EX para viabilizar frequências acima de 100 MHz

---

## 🗂️ Estrutura do Repositório

```
.
├── rtl/                    # Código RTL em Verilog/SystemVerilog
│   ├── cpu.v               # Top-level
│   ├── datapath.v
│   ├── control.v
│   ├── fowarding_control.v
│   ├── fpu/                # Submódulos da FPU (adder, multiply, int2fp, fp2int)
│   └── ...
├── tb/                     # Testbenches tradicionais
│   └── cpu_tb.v
├── uvm/                    # Ambiente de verificação UVM
│   ├── tb_top.sv
│   ├── tb_package.sv
│   ├── dut_if.sv
│   ├── dut_seq_lib.sv
│   └── ...
├── syn/                    # Scripts e constraints de síntese
│   └── constraints_*.sdc
└── docs/                   # Relatório e documentação
    └── Relatorio.pdf
```

---

*Universidade Federal de Itajubá — IESTI — 2026*