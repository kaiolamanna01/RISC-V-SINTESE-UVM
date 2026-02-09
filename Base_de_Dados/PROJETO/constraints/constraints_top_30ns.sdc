####################################################################
## 3. Configuração de Constraints (SDC) - Versão Final
####################################################################

# 1. Definição do Clock Principal
# Período de 30ns (Frequência de ~33.3 MHz)
create_clock -name CLK -period 30 -waveform {0 15} [get_ports CLK] 

# 2. Qualidade e Incerteza do Clock
# Transição (Slew) diferenciada para subida e descida
set_clock_transition -rise 3.0 [get_clocks CLK]
set_clock_transition -fall 3.0 [get_clocks CLK]

# Incerteza (Jitter + Skew) de 3ns
set_clock_uncertainty 3.0 [get_clocks CLK]

# Latência do Clock (1.5ns fonte + 0.9ns rede = 2.4ns total)
set_clock_latency 1.5 -source [get_clocks CLK]
set_clock_latency 0.9 [get_clocks CLK]

# 3. Delays de Interface (I/O Delays)
# Delay de entrada de 9ns para todas as portas de entrada (exceto o próprio CLK)
set_input_delay -max 9.0 -clock CLK [remove_from_collection [all_inputs] [get_ports CLK]]

# Delay de saída de 9ns para todas as portas de saída
set_output_delay -max 9.0 -clock CLK [all_outputs]

# 4. Parâmetros Elétricos e Carga
# Define a carga capacitiva nas saídas (0.04pF)
set_load 0.04 [all_outputs]

# Define os limites de transição para os sinais de entrada
set_input_transition -min 0.3 [all_inputs]
set_input_transition -max 3.0 [all_inputs]