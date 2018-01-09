module cpu (
    input clk,
    input reset,
    input  [7:0] mem_data_in,
    output [7:0] mem_data_out,
    output [15:0] mem_addr_out,
    output mem_read,
    output mem_write,
    input  mem_done
);

    reg [15:0] pc, nextpc;
    reg [7:0] ir, accu;
    reg [7:0] regs [7:0];
    
    wire [7:0] reg_0 = regs[0];
    wire [7:0] reg_1 = regs[1];
    wire [7:0] reg_2 = regs[2];
    wire [7:0] reg_3 = regs[3];
    wire [7:0] reg_4 = regs[4];
    wire [7:0] reg_5 = regs[5];
    wire [7:0] reg_6 = regs[6];
    wire [7:0] reg_7 = regs[7];

    initial begin
        pc <= 0;
        ir <= 0;
        nextpc <= 0;
        alu_out <= 0;
        accu <= 0;
        regs[0] <= 0;
        regs[1] <= 0;
        regs[2] <= 0;
        regs[3] <= 0;
        regs[4] <= 0;
        regs[5] <= 0;
        regs[6] <= 0;
        regs[7] <= 0;
        phase <= 0;
        maxphase <= 0;
        nextphase <= 0;
        Flags <= 8'h2a;
    end


    reg [2:0] rx;
    reg [8:0] alu_out, alu_src1, alu_src2;
    reg [7:0] Flags;  // Ie,If,nZ,Z,nN,N,nC,C
    wire  CFlag = Flags[0];
    wire nCFlag = Flags[1];
    wire  NFlag = Flags[2];
    wire nNFlag = Flags[3];
    wire  ZFlag = Flags[4];
    wire nZFlag = Flags[5];
    reg [7:0] next_Flags;  
  
    reg [1:0] phase, nextphase, maxphase;
    reg [23:0] imm;

    always @* begin
        nextpc = reset ? 16'd0 : pc + 16'd1;
        rx = ir[2:0];
        alu_src1 = {1'b0, ir[3] ? regs[rx] : accu};
        alu_src2 = {1'b0, ~ir[3] ? regs[rx] : accu};
        case (ir[7:4])
            4'h0 : alu_out = alu_src2;                              // 00..07: MOV A, Rx   - 08..0F: MOV Rx, A
            4'h1 : alu_out = alu_src1 & alu_src2;                   // 10..17: AND A, RX   - 18..1F: AND Rx, A
            4'h2 : alu_out = alu_src1 | alu_src2;                   // 20..27: OR  A, RX   - 28..2F: OR  RX, A
            4'h3 : alu_out = alu_src1 ^ alu_src2;                   // 30..37: XOR A, RX   - 38..3F: XOR RX, A
            4'h4 : alu_out = alu_src1 + alu_src2;                   // 40..47: ADD A, RX   - 48..4F: ADD RX, A
            4'h5 : alu_out = alu_src1 + alu_src2 + {8'b0, CFlag};   // 50..57: ADC A, RX   - 58..5F: ADC RX, A
            4'h6 : alu_out = alu_src1 - alu_src2;                   // 60..67: SUB A, RX   - 68..6F: SUB RX, A
            4'h7 : alu_out = alu_src1 - alu_src2 - {8'b0, ~CFlag};  // 70..77: SBC A, RX   - 78..7F: SBC RX, A
            4'h8 : case (ir[3:0])
                       4'h0 : alu_out = {CFlag, accu + 8'h1};          // 80: INC A
                       4'h1 : alu_out = {CFlag, accu + 8'hff};          // 81: DEC A
                       4'h2 : alu_out = {CFlag, accu[3:0], accu[7:4]};          // 82: SWAP A
                       4'h3 : alu_out = {CFlag, accu[0], accu[1], accu[2], accu[3], accu[4], accu[5], accu[6], accu[7]};          // 83: REV A  (bit reverse)
                    default : alu_out = 9'hX;
                   endcase
         default : alu_out = 9'hX;
        endcase

        next_Flags = {Flags[7:6], |alu_out[7:0], ~|alu_out[7:0], ~alu_out[7], alu_out[7], ~alu_out[8], alu_out[8]};


        // number of extry bytes to fetch
        maxphase = 0;
        if (ir[7:4] == 4'hf) maxphase = 2;

        if (phase != maxphase)
            nextphase = phase + 1;
        else
            nextphase = 0;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            pc <= 0;
            ir <= 0;
            nextpc <= 1;
        end else begin
            pc <= nextpc;
            case (nextphase)
                2'd0 : begin 
                           ir <= mem_data_in;
                           imm <= 0; 
                           // also 'execute'
                           Flags <= next_Flags;
                           casez (ir[7:5])
                               5'b0xxx0 : accu <= alu_out;
                               5'b0xxx1 : regs[rx] <= alu_out;
                               5'b10000 : accu <= alu_out;
                               5'b11110 : pc <= imm[15:0];
                            default : ;
                           endcase
                       end
                2'd1 : imm[7:0] <= mem_data_in;
                2'd2 : imm[15:8] <= mem_data_in;
                2'd3 : imm[23:16] <= mem_data_in;
             default : ;
            endcase
                
            phase <= nextphase;
        end
    end
  
    assign mem_addr_out = pc;
    assign mem_read = ~reset;
    assign mem_write = 0;
endmodule 
