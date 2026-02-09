###############################################################
## Library setup
###############################################################

set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ./RTL/
read_libs slow_vdd1v0_basicCells.lib

####################################################################
## Load Design
####################################################################

# Lista de arquivos HDL
set HDL_FILES {
    adder.v
    alu.v
    aludec.v
    control.v
    cpu.v
    data_memory.v
    datapath.v
    ex_mem_reg.v
    fowarding_control.v
    fp2int.v
    FPU.v
    hazard_detection.v
    id_ex_reg.v
    if_id_reg.v
    instruction_memory.v
    int2fp.v
    maindec.v
    mem_wb_reg.v
    memByteAddressable32WF.v
    memory_write_first.v
    multiply.v
    mux.v
    pc_reg.v
    register_file_f.v
    register_file.v
    sign_extender.v
}

read_hdl $HDL_FILES
elaborate cpu
check_design -unresolved

####################################################################
## Constraints Setup
####################################################################

read_sdc ./constraints/constraints_top.sdc

####################################################################################################
## Synthesis Effort
####################################################################################################

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

####################################################################################################
## Synthesizing to generic 
####################################################################################################

syn_generic

####################################################################################################
## Synthesizing to gates
####################################################################################################

syn_map

#######################################################################################################
## Optimize Netlist
#######################################################################################################

syn_opt

#################################
### Reports
#################################

report_timing > reports/report_timing.rpt
report_power  > reports/report_power.rpt
report_area   > reports/report_area.rpt
report_qor    > reports/report_qor.rpt

#################################
### Outputs
#################################
# Nota: Verifique se o nome do design no comando write_db deve ser 'cpu' ou o nome do seu top-module
write_db design_final -to_file design.db
write_hdl > outputs/cpu_netlist.v
write_sdc > outputs/cpu_sdc.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > outputs/delays.sdf
