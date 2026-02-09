# Makefile para simular com Xcelium (xrun)
XRUN = xrun
UVM_HOME=/apps/cds/XCELIUM2409/tools.lnx86/methodology/UVM/CDNS-1.2
XRUN_FLAGS = -uvmhome $(UVM_HOME) -uvm -coverage all -sv -64bit -access +rwc -clean -nowarn DLCPTH

# Arquivo contendo os modulos do projeto
FILELIST = filelist.f
TOP = tb_top

all:
	$(XRUN) $(XRUN_FLAGS) -f $(FILELIST) -top $(TOP) +UVM_TESTNAME=dut_extended_test +UVM_NO_RELNOTES

gui:
	$(XRUN) $(XRUN_FLAGS) -f $(FILELIST) -top $(TOP) -gui +UVM_TESTNAME=dut_extended_test +UVM_NO_RELNOTES

clean:
	rm -rf xrun.history xcelium.d INCA_libs *.log *.key *.shm *.vcd *.vpd worklib csrc

