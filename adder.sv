module adder (
  input  [3:0] a,
  input  [3:0] b,
  output [4:0] s
);
  assign s = a + b;
endmodule

interface adder_if;
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] s;
endinterface
