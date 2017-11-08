module top (
    input clk_12mhz,
    input sel,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,
    output LED6,
    output LED7,
    output LED8,
    output pin_c16,
    output pin_d16
);

// use 1 pll to generate 100MHz from 12MHz

// make ~48MHz from 100MHz
    reg [24:0] ring = 25'hAAAAAA;

    always @(posedge clk_100mhz)
        ring <= ({ring[0],ring[24:1]});

    wire f_feedback = ring[0];

// feed everything into PLL
// f_vco = 800MHz
// DIVQ = 3 (->f_pllout=fvco/(2**divQ) = 100MHz)
// FREF = 12MHz
// DIVR = 0
// -> DIVF = 3 (f_ref = f_feedback/(divf+1)

    wire pll_locked;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("EXTERNAL"),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
        .PLLOUT_SELECT("SHIFTREG_0deg"),
        .SHIFTREG_DIV_MODE(1'b0),
        .FDA_FEEDBACK(4'b0000),
        .FDA_RELATIVE(4'b0000),
        .DIVR(4'b0000),
        .DIVF(7'b0000011), // frecuency multiplier = 3+1 = 4
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001),
    ) uut (
        .REFERENCECLK   (clk_12mhz),
        .PLLOUTGLOBAL   (clk_100mhz),
        .BYPASS         (1'b0),
        .RESETB         (1'b1),
        .EXTFEEDBACK    (f_feedback),
        .LOCK (pll_locked)
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
    
    always@(posedge clk_100mhz)
        counter <= counter + 1;
        
    
    reg [31:0] rng = 32'h00010000; 
    
    always@(posedge counter[LOG2DELAY-2]) 
        rng <= ({rng[0],(rng >> 1)})^(rng | {(rng << 1),rng[31]});
        
        
    assign {LED1, LED2, LED3, LED4, LED5, LED6, LED7} = sel ? rng[14:7] : bin2gray(counter >> LOG2DELAY-1);


    reg [25:0] s_counter =0; 
    reg second = 0;
    always @(posedge clk_100mhz) begin
        if (s_counter == 50000000) begin
            s_counter <= 1;
            second <= ~second;
            end
        else
            s_counter <= s_counter + 1;
    end
    assign LED8 = second;

/*
// output 1MHz on pin_c16
    reg [5:0] m_counter = 0;
    reg mhz = 0;
    always @(posedge clk_100mhz) begin
        if (m_counter == 49)
            begin
                m_counter <= 0;
                mhz <= ~mhz;
            end
        else
            m_counter <= m_counter + 1;
    end
    wire pin_c16 = ~mhz;
*/
    


// generate a slow signal
    reg [18:0] slow_counter = 0;
    always @(posedge clk_12mhz) slow_counter <= slow_counter +1;
    
    wire slow_signal = (slow_counter[18:9] == 0);

    assign pin_c16 = slow_signal;



// tripler : MAGIC :

// input synchronizer
    wire input_signal = slow_signal;
    reg [2:0] input_sync = 0;
    wire input_synced;
    assign input_synced = input_sync[2];
   
    always @(posedge clk_100mhz)
        input_sync <= ({input_sync[1:0], input_signal});


// count pulse_len
    reg [30:0] pulselen_counter = 0;
    reg [30:0] last_pulselen = 0;
    wire pulselen_valid = (last_pulselen != 0);

    always @(posedge clk_100mhz) begin
        if (input_synced)
            pulselen_counter <= pulselen_counter + 1;
        else
            if (pulselen_counter > 0) begin
                last_pulselen <= pulselen_counter;
                pulselen_counter <= 0;
            end
    end
 
// count pulse_freq (in 10ns ticks)
    reg last_input = 0;
    reg [31:0] cycle_counter = 0;
    reg [31:0] last_cycle = 0;
    wire cycle_valid = (last_cycle > 0);

    wire [1:0] trig_check = ({last_input, input_synced});

    always @(posedge clk_100mhz) begin
        last_input <= input_synced;

        if (trig_check == 2'b01) begin
            last_cycle <= cycle_counter;
            cycle_counter <= 0;
        end else
            cycle_counter <= cycle_counter +1;
    end
 
// generate triple the pulses 

    reg [31:0] gen_counter = 0;
    wire start_pulse = ((gen_counter >= last_cycle) ||(cycle_counter == 0));
    always @(posedge clk_100mhz) begin
        if (cycle_valid && pulselen_valid && (cycle_counter != 0)) begin
        
        gen_counter <= (start_pulse)?(gen_counter-last_cycle):(gen_counter + 3);
        end else gen_counter <= 0;
    end

// extend the 'start' pulses to measured pulse length
    reg [30:0] gen_pulsectr = 0;
    wire active = (gen_pulsectr > 0);

    always @(posedge clk_100mhz) begin
        if (start_pulse && ~active)
            gen_pulsectr <= last_pulselen;
        else
            gen_pulsectr <= (active)?gen_pulsectr-1:0;
    end

    assign pin_d16 = active;

endmodule 
