`ifndef DUT_DRIVER_SV
`define DUT_DRIVER_SV

class dut_driver extends uvm_driver #(dut_txn);
  `uvm_component_utils(dut_driver)

  // Interface compartilhada (recebida via agent)
  virtual dut_if vif;

  dut_cfg cfg;

  bit fast_load = 0;

  // -----------------------------------
  // Construtor
  // -----------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -----------------------------------
  // build_phase
  // -----------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface nao encontrada para driver")

    void'(uvm_config_db#(dut_cfg)::get(this, "", "cfg", cfg));
    if (cfg != null)
      fast_load = cfg.fast_load;

    void'(uvm_config_db#(bit)::get(this, "", "fast_load", fast_load));
    if ($test$plusargs("FAST_LOAD"))
      fast_load = 1;
  endfunction

  // ------------------------------------
  // run_phase: recebe, aplica e publica transacoes
  // ------------------------------------
  task run_phase(uvm_phase phase);
    dut_txn tx;

    // Valores iniciais
    vif.we         <= 1'b0;
    vif.ADDR_INST  <= '0;
    vif.Instrucoes <= '0;

    // Aguarda sair de reset antes de iniciar
    wait (vif.rst === 1'b0);

    forever begin
      seq_item_port.get_next_item(tx);

      if (tx == null) begin
        `uvm_error("DRIVER", "Recebeu transacao nula")
        continue;
      end

  tx.accept_tr();
  void'(tx.begin_tr());

      case (tx.kind)
        dut_txn::TXN_LOAD: begin
          vif.we         <= 1'b1;
          vif.ADDR_INST  <= tx.addr_inst;
          vif.Instrucoes <= tx.instr;
          @(posedge vif.clk_load);
          vif.we         <= 1'b0;
          if (!fast_load) begin
            vif.ADDR_INST  <= '0;
            vif.Instrucoes <= '0;
          end
        end
        dut_txn::TXN_RUN: begin
          vif.we         <= 1'b0;
          vif.ADDR_INST  <= '0;
          vif.Instrucoes <= '0;
          if (tx.run_cycles > 0)
            repeat (tx.run_cycles) @(posedge vif.clk);
        end
        default: begin
          // TXN_MEM_EVT nÃ£o Ã© dirigido pelo driver
          @(posedge vif.clk);
        end
      endcase

  void'(tx.end_tr());
      seq_item_port.item_done();
    end
  endtask

endclass

`endif // DUT_DRIVER_SV

