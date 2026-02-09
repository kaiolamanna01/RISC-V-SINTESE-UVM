//classe dut_sequencer
//=====================================================
// dut_sequencer.sv
// Sequencer basico parametrizado por dut_txn
//=====================================================
class dut_sequencer extends uvm_sequencer #(dut_txn);
  `uvm_component_utils(dut_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

