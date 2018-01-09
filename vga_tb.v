module vga_tb;

  reg clk = 0;

  initial begin
     $dumpfile("vga.vcd");
     $dumpvars(0, vga_test);
     $dumpon;
     
     wait(vga_vs == 1);
     wait(vga_vs == 0);
     wait(vga_vs == 1);
     # 2000
     $finish;
  end

  wire [3:0] vga_r;
  wire [3:0] vga_g;
  wire [3:0] vga_b;
  wire vga_hs, vga_vs, vga_blank, fetch_cell, fetch_font, load_nshift;
  wire [11:0] cell_addr;

  wire [8:1] LED;

  vga vga_test(.clk_vga(clk),
               .vga_frame(LED),
               .vga_r(vga_r),
               .vga_g(vga_g),
               .vga_b(vga_b),
               .vga_hs(vga_hs),
               .vga_vs(vga_vs),
               .vga_blank(vga_blank),
	       .fetch_cell(fetch_cell),
	       .fetch_font(fetch_font),
               .load_nshift(load_nshift),
               .cell_addr(cell_addr)
);
               

  always #1 clk = !clk;

endmodule
