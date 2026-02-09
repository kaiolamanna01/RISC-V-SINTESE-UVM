####################################################################
## Configuração de Constraints - CENÁRIO PPA1: 20ns
####################################################################

# 1. Definição do Clock Principal
# Período de 20ns (Frequência de 50 MHz)
create_clock -name CLK -period 20 -waveform {0 10} [get_ports CLK] 

# 2. Qualidade e Incerteza do Clock
# Mantendo a incerteza proporcional ou ligeiramente mais rígida
set_clock_transition 1.5 [get_clocks CLK]
set_clock_uncertainty 2.0 [get_clocks CLK]

# Latência do Clock (Source + Network)
set_clock_latency 1.0 -source [get_clocks CLK]
set_clock_latency 0.5 [get_clocks CLK]

# 3. Delays de Interface (I/O Delays)
# Ajustado para 30% de 20ns = 6ns
set_input_delay -max 6.0 -clock CLK [remove_from_collection [all_inputs] [get_ports CLK]]
set_output_delay -max 6.0 -clock CLK [all_outputs]

# 4. Parâmetros Elétricos e Carga (Mantidos do padrão da tecnologia)
set_load 0.04 [all_outputs]
set_input_transition -min 0.3 [all_inputs]
set_input_transition -max 2.0 [all_inputs]