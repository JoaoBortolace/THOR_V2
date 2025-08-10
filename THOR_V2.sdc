# =========================================================
# THOR_V2 — Timing Constraints (Quartus / SDC)
# =========================================================

# -------------------------
# Clock
# -------------------------
# Clock principal (AJUSTE o período para sua frequência alvo)
create_clock -name clk -period 3.000 [get_ports {clock}]  ;# 333.000 MHz

# Incertezas (jitter, skew) — ajusta automaticamente por topologia
derive_clock_uncertainty

# -------------------------
# Reset assíncrono
# -------------------------
# Corta caminhos partindo do resetn (não faz setup/hold sense)
set_false_path -from [get_ports {resetn}]

# -------------------------
# I/O timing — MEM síncrona ao clk
# -------------------------
# Ajuste estes números de acordo com a memória/dispositivos externos:
#   -max: janela de setup disponível no externo
#   -min: janela de hold (mínimo de atraso de trilha/driver)

# Entradas de dados (da memória/barramento para o THOR_V2)
set_input_delay  1.0 -clock clk [get_ports {iData[*] dData[*]}]
set_input_delay  0.5 -clock clk -min [get_ports {iData[*] dData[*]}]

# Saídas de controle/endereço/dados (do THOR_V2 para fora)
set_output_delay 1.0 -clock clk [get_ports {iMemEn iAddr[*] dMemEn dMemCmd dAddr[*] interruptTaken}]
set_output_delay 0.5 -clock clk -min [get_ports {iMemEn iAddr[*] dMemEn dMemCmd dAddr[*] interruptTaken}]

# -------------------------
# Interrupções — assíncronas por padrão
# -------------------------
# Se interruptRequest e handlerAddr chegam assíncronos, corte do STA:
# set_false_path -from [get_ports {interruptRequest}]
# set_false_path -from [get_ports {handlerAddr[*]}]

# Caso sejam SÍNCRONOS ao mesmo clk, use delays de entrada em vez de false_path:
set_input_delay  1.0 -clock clk [get_ports {interruptRequest handlerAddr[*]}]
set_input_delay  0.5 -clock clk -min [get_ports {interruptRequest handlerAddr[*]}]

# -------------------------
# (Opcional) Grupos de clock
# -------------------------
# Se adicionar outros clocks/PLLs, descomente:
# derive_pll_clocks
# set_clock_groups -asynchronous -group {clk} -group {outro_clk}

# -------------------------
# (Opcional) Margens adicionais
# -------------------------
# Exemplo de margem manual extra (se não usar derive_clock_uncertainty):
#set_clock_uncertainty 0.150 [get_clocks {clk}]

# =========================================================
# Dicas:
# - Ajuste os valores de -max/-min à sua folha de dados/placa.
# - Rode: report_clocks, report_datasheet, report_unconstrained_paths.
# - Unconstrained = problema: tudo deve estar coberto por clock/delays/false_path.
# =========================================================
