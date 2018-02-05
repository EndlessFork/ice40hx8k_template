`timescale 100ns/10ns
module top_tb;

  reg sel = 0;
  initial begin
     $dumpfile("example_tb.vcd");
     $dumpvars(0,top_tb);

     # 10000 sel = 1;
     # 10000 sel = 0;
     # 900000 $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

  /* UUT */
  wire [7:0] LED;
  top uut (clk, sel, LED[7], LED[6], LED[5], LED[4], LED[3], LED[2], LED[1], LED[0], LOG2DELAY=8);

endmodule
