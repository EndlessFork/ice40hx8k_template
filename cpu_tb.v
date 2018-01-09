module cpu_tb;

  reg clk = 0;
  reg reset = 1;

  reg [7:0] mem [1024:0];

  initial begin
     $dumpfile("cpu.vcd");
     $dumpvars(0, cpu_test);
     $dumpon;

     mem[0]  = 8'h08;
     mem[1]  = 8'h09;
     mem[2]  = 8'h0a;
     mem[3]  = 8'h0b;
     mem[4]  = 8'h0c;
     mem[5]  = 8'h0d;
     mem[6]  = 8'h0e;
     mem[7]  = 8'h0f;
     mem[8]  = 8'h80;
     mem[9] = 8'hf0;
     mem[10] = 8'h01;
     mem[11] = 8'h00;
     mem[12] = 8'h83;

     # 5
     reset <= 0;
     
     # 2000
     $finish;
  end

  wire [15:0] mem_addr;
  wire [7:0] mem_data_out;
  wire [7:0] mem_data_in;
  wire mem_read;
  wire mem_write;
  wire mem_done;

  cpu cpu_test( .clk(clk),
		.reset(reset),
		.mem_addr_out(mem_addr),
		.mem_data_out(mem_data_out),
		.mem_data_in(mem_data_in),
		.mem_read(mem_read),
		.mem_write(mem_write),
		.mem_done(mem_done)
);

  assign mem_data_in = mem[mem_addr];
               

  always #1 clk = !clk;

endmodule
