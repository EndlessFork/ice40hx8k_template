module vga (
    input clk_vga,
    output [7:0] vga_frame,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output vga_hs,
    output vga_vs,
    output vga_blank,
    output fetch_first,
    output line_top,
    output fetch_start,
    output fetch_cell,
    output fetch_font,
    output load_nshift,
    output [11:0] cell_addr,
    output [9:0] hpos,
    output [9:0] vpos
);
    wire clk_vga;
    reg [7:0] vga_frame = 0;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hs, vga_vs, vga_blank, fetch_cell, fetch_font, load_nshift;  
    reg [11:0] cell_addr;

    
/*    // 640 colums
    localparam hfp = 10'd16;
    localparam hsp = 10'd96;
    localparam hbp = 10'd48;
    localparam hactive = 10'd640;
    localparam htotal = hactive + hfp + hsp + hbp;
    localparam hend = hactive + hfp + hsp - 1;
    localparam hstart =  -hbp;
/**/
/**/
    // 720 colums
    localparam hfp = 10'd18;
    localparam hsp = 10'd108;
    localparam hbp = 10'd54;
    localparam hactive = 10'd720;
    localparam htotal = hactive + hfp + hsp + hbp;
    localparam hend = hactive + hfp + hsp - 1;
    localparam hstart =  -hbp;
/**/


/**/    // 400 lines
    localparam vfp = 10'd13;
    localparam vsp = 10'd2;
    localparam vbp = 10'd34;
    localparam vactive = 10'd400;
    localparam vtotal = vactive + vfp + vsp + vbp;
    localparam vend = vactive + vfp + vsp - 1;
    localparam vstart = -vbp;
/**/
/*
    // 480 lines
    localparam vfp = 10'd10;
    localparam vsp = 10'd2;
    localparam vbp = 10'd33;
    localparam vactive = 10'd480;
    localparam vtotal = vactive + vfp + vsp + vbp;
    localparam vend = vactive + vfp + vsp - 1;
    localparam vstart = -vbp;
/**/
  

    reg [9:0] hpos = -hfp;
    reg [9:0] vpos = -vfp;

    // counting mode: *bp..0...*active...*fp...*sync

    wire hblank_start = hpos == hactive - 1;
    wire hblank_stop  = hpos == -10'd1;
    wire hsync_start  = hpos == (hactive + hfp) - 1;
    wire hsync_stop   = hpos == (hactive + hfp + hsp) - 1;    
    wire hreset       = hpos == hend;

    wire vblank_start = vpos == vactive;
    wire vblank_stop  = vpos == 10'd0;
    wire vsync_start  = vpos == (vactive + vfp);
    wire vsync_stop   = vpos == vstart;
    wire vreset       = vpos == vend;

    reg hblank=1;
    reg vblank=1;
    reg hsync=0;
    reg vsync=0;

    wire fetch_start = hpos == -10'd9;
    wire fetch_stop = hpos == hactive - 9;
    wire fetch_first = vpos == 0;
    wire line_top = vpos[3:0] == 0;
    reg fetching=0;


    // just the h/v counters
    always@(posedge clk_vga) begin
        if (hreset) begin
            hpos <= hstart;
            if (vreset) begin
                vpos <= vstart;
                vga_frame <= vga_frame + 1;
            end else
                vpos <= vpos + 1;
        end else begin
            hpos <= (hpos + 1);
        end
    end

    // generate blank/sync signals
    always@(posedge clk_vga) begin
        hblank <= hblank_start ? 1 : (hblank_stop ? 0 : hblank);
        hsync <= hsync_start ? 1 : (hsync_stop ? 0 : hsync);
        vblank <= vblank_start ? 1 : (vblank_stop ? 0 : vblank);
        vsync <= vsync_start ? 1 : (vsync_stop ? 0 : vsync);
        fetching <= fetch_start ? ~vblank : (fetch_stop ? 0 : fetching);
    end

    assign vga_hs = ~hsync;  // negative polarity!
    assign vga_vs = vsync;  // negative polarity!

    wire blank = vblank | hblank;

    assign fetch_cell = fetching ? hpos[2:0] == 3'b000 : 0;
    assign fetch_font = fetching ? hpos[2:0] == 3'b100 : 0;
    assign load_nshift = fetching ? hpos[2:0] == 3'b111 : 0;
    
    reg new_line;
    reg [11:0] text_line_addr;

    always @(posedge clk_vga) begin
        new_line <= hreset;
        if (new_line) begin
            if (vpos == 0)  begin // reset addr pointers at top
                cell_addr <= 0;
                text_line_addr <= 0;
            end else if (line_top) begin
                text_line_addr <= cell_addr;
            end else begin
                cell_addr <= text_line_addr;
            end

        end
        if (fetch_cell)
            cell_addr <= cell_addr + 1;
    end




    wire border = ((hpos == 0) || (hpos == hactive - 1) ||
                   (vpos == 0) || (vpos == vactive -1) ||
                   (hpos == hactive / 2) || (vpos == vactive / 2));

    

/*    // test pattern
    assign vga_r = blank ? 4'h0 : (border ? 4'hf : hpos[8:5]);
    assign vga_g = blank ? 4'h0 : (border ? 4'hf : hpos[3:0]);
    assign vga_b = blank ? 4'h0 : (border ? 4'hf : vpos[7:4]);
*/

    wire [3:0] rgbi = blank ? 4'h0 : (border ? 4'hf : hpos[8:5] ^ vpos[7:4]);
    wire r = rgbi[2];
    wire g = rgbi[1];
    wire b = rgbi[0];
    wire i = rgbi[3];

    wire [7:0] rgbii = blank ? 8'h0 : (border ? 8'hff : hpos[8:1] - vpos[7:0]);
    wire [1:0] bb = rgbii[1:0];
    wire [1:0] gg = rgbii[3:2];
    wire [1:0] rr = rgbii[5:4];
    wire [1:0] ii = rgbii[7:6];

    wire left = hpos < hactive /2;

    assign vga_r = left?{rr[1], ii[1], rr[0], ii[0]}:{rr,ii};
    assign vga_g = left?{gg[1], ii[1], gg[0], gg[0]}:{gg,ii};
    assign vga_b = left?{bb[1], ii[1], bb[0], bb[0]}:{bb,ii};

    assign vga_blank = blank;

endmodule 
