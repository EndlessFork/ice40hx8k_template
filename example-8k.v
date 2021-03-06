module top (
    input clk,
    input sel,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,
    output LED6,
    output LED7,
    output LED8
);

    localparam BITS = 8;
    localparam LOG2DELAY = 22;
    
    function [BITS-1:0] bin2gray(input [BITS+1:0] in);
        integer i;
        reg [BITS+1:0] temp;
        begin
            temp = in;
            for (i=0; i<BITS; i=i+1)
                bin2gray[i] = ^temp[i +: 2];
        end
    endfunction
    

    reg [BITS+LOG2DELAY-1:0] counter = 0; 
    
    always@(posedge clk)
        counter <= counter + 1;
        
    
    reg [31:0] rng = 32'h00010000; 
    
    always@(posedge counter[LOG2DELAY-2]) rng <= ({rng[0],(rng >> 1)})^(rng | {(rng << 1),rng[31]});
        
        
    assign {LED1, LED2, LED3, LED4, LED5, LED6, LED7, LED8} = sel ? rng[14:7] : bin2gray(counter >> LOG2DELAY-1);
    
    
    
endmodule 



module top_tb;

  reg sel = 0;
  initial begin
     $dumpfile("top_tb.vcd");
     $dumpvars(0,top_tb);

     # 10000 sel = 1;
     # 10000 sel = 0;
     # 30000 $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

  /* UUT */
  wire [7:0] LED;
  top uut (clk, sel, LED);

endmodule
