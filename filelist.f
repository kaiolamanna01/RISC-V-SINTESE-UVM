+incdir+./UVM
+incdir+./CPU

# UVM Files (compile package and top; package includes UVM classes)
UVM/dut_if.sv
UVM/tb_package.sv
UVM/tb_top.sv

# RTL (CPU)
CPU/adder.v
CPU/alu.v
CPU/aludec.v
CPU/control.v
CPU/cpu.v
CPU/data_memory.v
CPU/datapath.v
CPU/ex_mem_reg.v
CPU/fowarding_control.v
CPU/fp2int.v
CPU/FPU.v
CPU/hazard_detection.v
CPU/id_ex_reg.v
CPU/if_id_reg.v
CPU/instruction_memory.v
CPU/int2fp.v
CPU/maindec.v
CPU/mem_wb_reg.v
CPU/memByteAddressable32WF.v
CPU/memory_write_first.v
CPU/multiply.v
CPU/mux.v
CPU/pc_reg.v
CPU/register_file_f.v
CPU/register_file.v
CPU/sign_extender.v
