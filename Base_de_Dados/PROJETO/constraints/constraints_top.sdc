####################################################################
## Configuração de Constraints - CENÁRIO: 10ns (100 MHz)
####################################################################

# 1. Definição do Clock Principal
# Período reduzido para 10ns
create_clock -name CLK -period 10 -waveform {0 5} [get_ports CLK] 

# 2. Qualidade e Incerteza do Clock
# Reduzi a incerteza para 1.0ns (10% do período) para não sufocar o design
set_clock_transition 0.8 [get_clocks CLK]
set_clock_uncertainty 1.0 [get_clocks CLK]

# Latência do Clock
set_clock_latency 0.5 -source [get_clocks CLK]
set_clock_latency 0.3 [get_clocks CLK]

# 3. Delays de Interface (I/O Delays)
# Mantendo a regra de 30% do período: 30% de 10ns = 3ns
set_input_delay -max 3.0 -clock CLK [remove_from_collection [all_inputs] [get_ports CLK]]
set_output_delay -max 3.0 -clock CLK [all_outputs]

# 4. Parâmetros Elétricos e Carga
set_load 0.04 [all_outputs]
set_input_transition -min 0.2 [all_inputs]
set_input_transition -max 1.0 [all_inputs]