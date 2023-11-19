`include "uvm_macros.svh"
import uvm_pkg::*;

class my_sequence_item extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0] b;
  bit      [4:0] s;

  `uvm_object_utils_begin(my_sequence_item)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_int(s, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "my_sequence_item");
    super.new(name);
  endfunction

endclass

class my_sequence extends uvm_sequence #(my_sequence_item);
  `uvm_object_utils(my_sequence)

  my_sequence_item item;

  function new(string name = "my_sequence");
    super.new(name);
  endfunction

  virtual task body();
    item = my_sequence_item::type_id::create("item");
    repeat(10) begin
      start_item(item);
      item.randomize();
      finish_item(item);
    end
  endtask

endclass

class my_driver extends uvm_driver #(my_sequence_item);
  `uvm_component_utils(my_driver)

  my_sequence_item item;
  virtual adder_if intf;

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    item = my_sequence_item::type_id::create("item");
    if (!uvm_config_db #(virtual adder_if)::get(this, "", "intf", intf)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface adder_if")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(item);
      intf.a <= item.a;
      intf.b <= item.b;
      #10;
      seq_item_port.item_done();
    end
  endtask

endclass

class my_monitor extends uvm_monitor;
  `uvm_component_utils(my_monitor)

  my_sequence_item item;
  virtual adder_if intf;
  uvm_analysis_port #(my_sequence_item) port;

  function new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
    port = new("port", this);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    item = my_sequence_item::type_id::create("item");
    if (!uvm_config_db #(virtual adder_if)::get(this, "", "intf", intf)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface adder_if")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      item.a = intf.a;
      item.b = intf.b;
      item.s = intf.s;
      port.write(item);
    end
  endtask

endclass

class my_agent extends uvm_agent;
  `uvm_component_utils(my_agent)

  my_monitor mon;
  my_driver drv;
  uvm_sequencer #(my_sequence_item) seqr;

  function new(string name = "my_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = my_monitor::type_id::create("mon", this);
    drv = my_driver::type_id::create("drv", this);
    seqr = uvm_sequencer #(my_sequence_item)::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass

class my_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(my_scoreboard)

  my_sequence_item item;
  uvm_analysis_imp #(my_sequence_item, my_scoreboard) imp;

  function new(string name = "my_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    item = my_sequence_item::type_id::create("item");
  endfunction

  virtual function void write(my_sequence_item _item);
    item = _item;
    if (item.s == item.a + item.b) begin
      `uvm_info(get_type_name(), "Test passed", UVM_NONE)
    end else begin
      `uvm_info(get_type_name(), "Test failed", UVM_NONE)
    end
  endfunction

endclass

class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_scoreboard scbd;
  my_agent agt;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scbd = my_scoreboard::type_id::create("scbd", this);
    agt = my_agent::type_id::create("agt", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.port.connect(scbd.imp);
  endfunction

endclass

class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_sequence seq;
  my_env env;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq = my_sequence::type_id::create("seq", this);
    env = my_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask

endclass

module my_testbench;
  adder_if intf();

  adder dut (
    .a(intf.a),
    .b(intf.b),
    .s(intf.s)
  );

  initial begin
    uvm_config_db #(virtual adder_if)::set(null, "uvm_test_top.env.agt*", "intf", intf);
    run_test("my_test");
  end

endmodule
