
module top (
    input clk_12mhz,
    output [8:1] LED,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output vga_hs,
    output vga_vs,
    output [2:0] dbg
);

    wire clk_12mhz;
    wire [8:1] LED;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hs;
    wire vga_vs;
    wire vga_blank;

// use 1 pll to generate 25.15MHz from 12MHz

// f_vco = 67*12MHz = 804 MHz
// DIVQ = 5 (->f_pllout=fvco/(2**divQ) = 25.125MHz)
// FREF = 12MHz
// DIVR = 0
// DIVF = 66 (f_ref = f_vco/(divf+1))

    wire pll_locked;
    wire clk_vga;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
//        .PLLOUT_SELECT("GENCLK"),
        .PLLOUT_SELECT("SHIFTREG_0deg"),
        .DIVR(4'b0000),
        .DIVF(7'b1001010),
//        .DIVF(7'b1000010),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) uut (
        .LOCK(pll_locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_12mhz),
        .PLLOUTCORE(clk_vga)
    );

    wire fetch_cell, fetch_font, load_nshift, vga_vs, vga_hs;
    wire fetch_first, fetch_start, line_top;
    wire [9:0] hpos, vpos;
    wire [3:0] inner_vga_r, inner_vga_g, inner_vga_b;
    wire [11:0] cell_addr;

    vga vga(	.clk_vga(clk_vga),
		.vga_hs(vga_hs),
		.vga_vs(vga_vs),
                .vga_r(inner_vga_r),
                .vga_g(inner_vga_g),
                .vga_b(inner_vga_b),
		.vga_blank(vga_blank),
                .vga_frame(LED),
                .hpos(hpos),
                .vpos(vpos),
		.fetch_cell(fetch_cell),
		.fetch_font(fetch_font),
		.load_nshift(load_nshift),
                .fetch_first(fetch_first),
                .fetch_start(fetch_start),
                .line_top(line_top),
                .cell_addr(cell_addr)
    );


    reg  [15:0] cells [4095:0];
    reg  [15:0] cell_data;
    reg  [7:0] font [4095:0]; // 8x16 font
    reg  [7:0] font_data;
//    reg  [11:0] palette [15:0]; // palette of 16 colors

    initial begin
/*        palette[0]  <= 12'h000; // rgb
        palette[1]  <= 12'h00a;
        palette[2]  <= 12'h0a0;
        palette[3]  <= 12'h0aa;
        palette[4]  <= 12'ha00;
        palette[5]  <= 12'ha0a;
        palette[6]  <= 12'ha50;
        palette[7]  <= 12'haaa;
        palette[8]  <= 12'h555;
        palette[9]  <= 12'h55f;
        palette[10] <= 12'h5f5;
        palette[11] <= 12'h5ff;
        palette[12] <= 12'hf55;
        palette[13] <= 12'hf5f;
        palette[14] <= 12'hff5;
        palette[15] <= 12'hfff;
*/
        cells[0] <= 16'h8001;
        cells[1] <= 16'h8101;
        cells[2] <= 16'h8201;
        cells[3] <= 16'h8301;
        cells[4] <= 16'h8401;
        cells[5] <= 16'h8501;
        cells[6] <= 16'h8601;
        cells[7] <= 16'h8701;
        cells[8] <= 16'h8801;
        cells[9] <= 16'h8901;
        cells[10] <= 16'h8a01;
        cells[11] <= 16'h8b01;
        cells[12] <= 16'h8c01;
        cells[13] <= 16'h8d01;
        cells[14] <= 16'h8e01;
        cells[15] <= 16'h8f01;
        cells[16] <= 16'h0f01;
        cells[17] <= 16'hf000;
        cells[18] <= 16'hf001;

        cells[80] <= 16'h0f01;
        cells[81] <= 16'h0e01;
        cells[82] <= 16'h0d01;
        cells[83] <= 16'h0c01;
        cells[84] <= 16'h0b01;
        cells[85] <= 16'h0a01;
        cells[86] <= 16'h0901;
        cells[87] <= 16'h0801;
        cells[88] <= 16'h0701;
        cells[89] <= 16'h0601;
        cells[90] <= 16'h0501;
        cells[91] <= 16'h0401;
        cells[92] <= 16'h0301;
        cells[93] <= 16'h0201;
        cells[94] <= 16'h0101;
        cells[95] <= 16'h0001;

        font[0]   <= 8'b00000000;
        font[1]   <= 8'b00000000;
        font[2]   <= 8'b00000000;
        font[3]   <= 8'b00000000;
        font[4]   <= 8'b00000000;
        font[5]   <= 8'b00000000;
        font[6]   <= 8'b00000000;
        font[7]   <= 8'b00000000;
        font[8]   <= 8'b00000000;
        font[9]   <= 8'b00000000;
        font[10]  <= 8'b00000000;
        font[11]  <= 8'b00000000;
        font[12]  <= 8'b00000000;
        font[13]  <= 8'b00000000;
        font[14]  <= 8'b00000000;
        font[15]  <= 8'b00000000;

        font[16]  <= 8'b00000000;
        font[17]  <= 8'b01111110;
        font[18]  <= 8'b00000110;
        font[19]  <= 8'b00001010;
        font[20]  <= 8'b00010010;
        font[21]  <= 8'b00100010;
        font[22]  <= 8'b01000010;
        font[23]  <= 8'b00011000;
        font[24]  <= 8'b00011000;
        font[25]  <= 8'b01000010;
        font[26]  <= 8'b01000100;
        font[27]  <= 8'b01001000;
        font[28]  <= 8'b01010000;
        font[29]  <= 8'b01000000;
        font[30]  <= 8'b01111110;
        font[31]  <= 8'b00000000;

        font[32]  <= 8'b00000000;
        font[33]  <= 8'b00000000;
        font[34]  <= 8'b00000000;
        font[35]  <= 8'b00000000;
        font[36]  <= 8'b00000000;
        font[37]  <= 8'b00000000;
        font[38]  <= 8'b00000000;
        font[39]  <= 8'b00000000;
        font[40]  <= 8'b00000000;
        font[41]  <= 8'b00000000;
        font[42]  <= 8'b00000000;
        font[43]  <= 8'b00000000;
        font[44]  <= 8'b11111111;
        font[45]  <= 8'b11111111;
        font[46]  <= 8'b11111111;
        font[47]  <= 8'b11111111;

        font[48]  <= 8'b00000000;
        font[49]  <= 8'b00000000;
        font[50]  <= 8'b00000000;
        font[51]  <= 8'b00000000;
        font[52]  <= 8'b00000000;
        font[53]  <= 8'b00000000;
        font[54]  <= 8'b00000000;
        font[55]  <= 8'b00000000;
        font[56]  <= 8'b11111111;
        font[57]  <= 8'b11111111;
        font[58]  <= 8'b11111111;
        font[59]  <= 8'b11111111;
        font[60]  <= 8'b00000000;
        font[61]  <= 8'b00000000;
        font[62]  <= 8'b00000000;
        font[63]  <= 8'b00000000;

        font[64]  <= 8'b00000000;
        font[65]  <= 8'b00000000;
        font[66]  <= 8'b00000000;
        font[67]  <= 8'b00000000;
        font[68]  <= 8'b00000000;
        font[69]  <= 8'b00000000;
        font[70]  <= 8'b00000000;
        font[71]  <= 8'b00000000;
        font[72]  <= 8'b11111111;
        font[73]  <= 8'b11111111;
        font[74]  <= 8'b11111111;
        font[75]  <= 8'b11111111;
        font[76]  <= 8'b11111111;
        font[77]  <= 8'b11111111;
        font[78]  <= 8'b11111111;
        font[79]  <= 8'b11111111;

        font[80]  <= 8'b00000000;
        font[81]  <= 8'b00000000;
        font[82]  <= 8'b00000000;
        font[83]  <= 8'b00000000;
        font[84]  <= 8'b11111111;
        font[85]  <= 8'b11111111;
        font[86]  <= 8'b11111111;
        font[87]  <= 8'b11111111;
        font[88]  <= 8'b00000000;
        font[89]  <= 8'b00000000;
        font[90]  <= 8'b00000000;
        font[91]  <= 8'b00000000;
        font[92]  <= 8'b00000000;
        font[93]  <= 8'b00000000;
        font[94]  <= 8'b00000000;
        font[95]  <= 8'b00000000;

        font[96]  <= 8'b00000000;
        font[97]  <= 8'b00000000;
        font[98]  <= 8'b00000000;
        font[99]  <= 8'b00000000;
        font[100] <= 8'b11111111;
        font[101] <= 8'b11111111;
        font[102] <= 8'b11111111;
        font[103] <= 8'b11111111;
        font[104] <= 8'b00000000;
        font[105] <= 8'b00000000;
        font[106] <= 8'b00000000;
        font[107] <= 8'b00000000;
        font[108] <= 8'b11111111;
        font[109] <= 8'b11111111;
        font[110] <= 8'b11111111;
        font[111] <= 8'b11111111;

        font[112] <= 8'b00000000;
        font[113] <= 8'b00000000;
        font[114] <= 8'b00000000;
        font[115] <= 8'b00000000;
        font[116] <= 8'b11111111;
        font[117] <= 8'b11111111;
        font[118] <= 8'b11111111;
        font[119] <= 8'b11111111;
        font[120] <= 8'b11111111;
        font[121] <= 8'b11111111;
        font[122] <= 8'b11111111;
        font[123] <= 8'b11111111;
        font[124] <= 8'b00000000;
        font[125] <= 8'b00000000;
        font[126] <= 8'b00000000;
        font[127] <= 8'b00000000;

        font[128] <= 8'b00000000;
        font[129] <= 8'b00000000;
        font[130] <= 8'b00000000;
        font[131] <= 8'b00000000;
        font[132] <= 8'b11111111;
        font[133] <= 8'b11111111;
        font[134] <= 8'b11111111;
        font[135] <= 8'b11111111;
        font[136] <= 8'b11111111;
        font[137] <= 8'b11111111;
        font[138] <= 8'b11111111;
        font[139] <= 8'b11111111;
        font[140] <= 8'b11111111;
        font[141] <= 8'b11111111;
        font[142] <= 8'b11111111;
        font[143] <= 8'b11111111;
    end


    wire [11:0] font_addr = {cell_data[7:0], vpos[3:0]};
    reg [3:0] textcolor, backcolor;

    reg [7:0] pixel_shiftreg;

    always @(posedge clk_vga) begin
        if (fetch_cell)
            cell_data <= cells[cell_addr];
        if (fetch_font) begin
            font_data <= font[font_addr];
        end
        if (load_nshift) begin
            backcolor <= cell_data[15:12];
            textcolor <= cell_data[11:8];
            pixel_shiftreg <= font_data;
        end else
            pixel_shiftreg <= pixel_shiftreg << 1;
//            pixel_shiftreg <= {pixel_shiftreg[6:0], 0};  // does not work: why???
    end


    wire dot;
    assign dot  = pixel_shiftreg[7];

    wire [3:0] dotcolor = vga_blank ? 4'h0 : ( dot ? textcolor :  backcolor);

    reg [3:0] my_r,my_g,my_b;
    reg my_hs, my_vs;
    always @(posedge clk_vga) begin
//        my_r <= dot ? {dotcolor[2], dotcolor[3], dotcolor[2], dotcolor[3]} : inner_vga_r >> 1;
//        my_g <= dot ? {dotcolor[1], dotcolor[3], dotcolor[1], dotcolor[3]} : inner_vga_g >> 1;
//        my_b <= dot ? {dotcolor[0], dotcolor[3], dotcolor[0], dotcolor[3]} : inner_vga_b >> 1;
        my_r <= {dotcolor[2], dotcolor[3], dotcolor[2], dotcolor[3]};
        my_g <= {dotcolor[1], dotcolor[3], dotcolor[1], dotcolor[3]};
        my_b <= {dotcolor[0], dotcolor[3], dotcolor[0], dotcolor[3]};
        my_hs <= vga_hs;
        my_vs <= vga_vs;
    end


    assign vga_r = my_r;
    assign vga_g = my_g;
    assign vga_b = my_b;
    assign vga_hsync = my_hs;
    assign vga_vsync = my_vs;



    assign dbg[2] = vga_hs;
    assign dbg[1] = vga_vs;
    assign dbg[0] = vga_blank;

    
/**********************
 * just testing stuff *
 **********************/
    reg [11:0] stuffptr;
    reg [3:0] stuffx;
    reg [3:0] stuffy;
    reg [7:0] stuffn;

    reg [12:0] stuffp;

    always @(posedge clk_vga) begin    
        if ((hpos == 42)&&(vpos == 17)) begin
            cells[stuffp] <= {stuffp[7:0], 4'h00, stuffp[12] ^ stuffp[11:8]};
            stuffp <= stuffp + 1;
        end
        if ((hpos == 17)&&(vpos == 42)) begin
            if (stuffx == 15) begin
                stuffx <= 0;
                if (stuffy == 15) begin
                    stuffy <= 0;
                    stuffptr <= 667;
                    stuffn <= stuffn < 9 ? stuffn + 1 : 0;
                end else begin
                    stuffy <= stuffy + 1;
                    stuffptr <= stuffptr + 75;
                end 
            end else begin
                stuffx <= stuffx + 1;
                stuffptr <= stuffptr + 1;
            end
            cells[stuffptr] <= stuffn ? {stuffy, stuffx, stuffn} : 0;
        end
    end
/**/
endmodule 
