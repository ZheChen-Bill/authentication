

`include "./packet_parameter.v"


module B_unpacket (
    input clk,
    input rst_n,


    input busy_Net2PP_RX,
    input msg_accessed,
    input [10:0] sizeRX_msg,

    output busy_PP2Net_RX,


    input reset_er_parameter,
    output EVrandombit_full,

    input reset_pa_parameter,
    output PArandombit_full,

    output wire [3:0] B_unpacket_state,



    // B_A2B decoy fifo
    output wire  B_RX_Zbasis_decoy_wr_clk,
    output wire  [31:0] B_RX_Zbasis_decoy_wr_din,
    output wire  B_RX_Zbasis_decoy_wr_en,
    input wire B_RX_Zbasis_decoy_full,
    input wire B_RX_Zbasis_decoy_wr_ack,

    // B_A2B ER fifo
    output wire B_RX_er_wr_clk,
    output wire [31:0] B_RX_er_wr_din,
    output wire B_RX_er_wr_en,
    input wire B_RX_er_full,
    input wire B_RX_er_wr_ack,

    // B_A2B EV random bit bram
    output wire [63:0] B_RX_EVrandombit_dina,
    output reg [13:0] B_RX_EVrandombit_addra,   //0~16383
    output wire B_RX_EVrandombit_clka,
    output wire B_RX_EVrandombit_ena,           //1'b1
    output wire B_RX_EVrandombit_wea,

    // B_A2B secret key length fifo
    output wire  B_RX_secretkey_length_wr_clk,
    output wire  [31:0] B_RX_secretkey_length_wr_din,
    output wire  B_RX_secretkey_length_wr_en,
    input wire B_RX_secretkey_length_full,
    input wire B_RX_secretkey_length_wr_ack,

    // B_A2B PA randombit bram
    output wire [63:0] B_RX_PArandombit_dina,
    output reg [13:0] B_RX_PArandombit_addra,    //0~16383
    output wire  B_RX_PArandombit_clka,
    output wire  B_RX_PArandombit_ena,            //1'b1
    output wire  B_RX_PArandombit_wea,


    // RX BRAM
    output wire B_RX_bram_clkb,
    output wire B_RX_bram_enb,
    output wire B_RX_bram_web,
    output reg [10:0] B_RX_bram_addrb,
    input wire [31:0] B_RX_bram_doutb
    
);

//****************************** FIFO setup ******************************
    // B_A2B decoy fifo
    assign B_RX_Zbasis_decoy_wr_clk = clk;
    // B_A2B ER fifo
    assign B_RX_er_wr_clk = clk;
    // B_A2B secret key length fifo
    assign B_RX_secretkey_length_wr_clk = clk;
//****************************** FIFO setup ******************************
//****************************** BRAM setup ******************************
    // B_A2B EV random bit bram
    assign B_RX_EVrandombit_clka = clk;
    assign B_RX_EVrandombit_ena = 1'b1;
    // B_A2B PA randombit bram
    assign B_RX_PArandombit_clka = clk;
    assign B_RX_PArandombit_ena = 1'b1;
    // RX BRAM
    assign B_RX_bram_clkb = clk;
    assign B_RX_bram_enb = 1'b1;
    assign B_RX_bram_web = 1'b0;
//****************************** BRAM setup ******************************
//****************************** DFF for bram output ******************************
    reg [31:0] B_RX_bram_doutb_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_RX_bram_doutb_ff <= 32'b0;
        end
        else begin
            B_RX_bram_doutb_ff <= B_RX_bram_doutb;
        end
    end
//****************************** DFF for bram output ******************************






//****************************** B unpacket fsm ******************************

    // Input 
    // wire clk;
    // wire rst_n;
    // wire busy_Net2PP_RX;
    // wire msg_accessed;
    wire write_fifo_bram_done;

    // Output 
    // wire busy_PP2Net_RX;
    wire set_parameter_en;
    wire read_bram_header_en;
    wire write_fifo_bram_en;
    wire reset_parameter;
    wire [3:0] B_unpacket_state;

    B_unpacket_fsm Bpacket_fsm (
        .clk(clk),                           // Clock signal
        .rst_n(rst_n),                       // Reset signal

        .busy_Net2PP_RX(busy_Net2PP_RX),     // Input indicating the network to post-processing reception is busy
        .msg_accessed(msg_accessed),         // Input indicating message access
        .write_fifo_bram_done(write_fifo_bram_done), // Input indicating write to FIFO/BRAM is done

        .B_RX_Zbasis_decoy_full(B_RX_Zbasis_decoy_full),
        .B_RX_er_full(B_RX_er_full),

        .busy_PP2Net_RX(busy_PP2Net_RX),     // Output indicating post-processing to network reception is busy
        .set_parameter_en(set_parameter_en), // Output to enable setting parameters
        .read_bram_header_en(read_bram_header_en),   // Output to enable reading BRAM header
        .write_fifo_bram_en(write_fifo_bram_en),     // Output to enable writing to FIFO/BRAM
        .reset_parameter(reset_parameter),   // Output to reset parameters

        .B_unpacket_state(B_unpacket_state)  // Output register for B's unpacket state
    );

//****************************** B unpacket fsm ******************************








//****************************** read BRAM header ******************************
    reg [31:0] bram_header_ff;
    always @(posedge clk ) begin
        if (~rst_n)begin
            bram_header_ff <= 32'b0;
        end
        else if (read_bram_header_en) begin
            bram_header_ff <= B_RX_bram_doutb_ff;
        end
        else if (reset_parameter) begin
            bram_header_ff <= 32'b0;
        end
        else begin
            bram_header_ff <= bram_header_ff;
        end
    end

    wire [`PACKET_LENGTH_WIDTH-1:0] bram_packet_depth;
    assign bram_packet_depth = bram_header_ff[27:24];

    wire [`PACKET_TYPE_WIDTH-1:0] bram_packet_type;
    assign bram_packet_type = bram_header_ff[31:28];


    reg [10:0] bram_real_depth;
    always @(*) begin
        if (bram_packet_depth==`PACKET_LENGTH_257) begin
            bram_real_depth = bram_header_ff[23:15];
        end
        else if (bram_packet_depth==`PACKET_LENGTH_514) begin
            bram_real_depth = 11'd512;
        end
        else if (bram_packet_depth==`PACKET_LENGTH_771) begin
            bram_real_depth = 11'd768;
        end
        else if (bram_packet_depth==`PACKET_LENGTH_1028) begin
            bram_real_depth = 11'd1024;
        end
        else begin
            bram_real_depth = 11'd1024;
        end
    end
//****************************** read BRAM header ******************************




//****************************** read from BRAM ******************************

    reg [10:0] read_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            read_bram_cnt <= 11'b0;
        end
        else if (reset_parameter) begin
            read_bram_cnt <= 11'b0;
        end
        else if (write_fifo_bram_en) begin
            read_bram_cnt <= read_bram_cnt + 1;
        end
        else begin
            read_bram_cnt <= read_bram_cnt;
        end
    end

    assign write_fifo_bram_done = (read_bram_cnt==(bram_real_depth+9))? 1'b1:1'b0;

    always @(posedge clk) begin
        if (~rst_n) begin
            B_RX_bram_addrb <= 11'b0;
        end
        else if ((read_bram_cnt>2)&&(read_bram_cnt<(bram_real_depth+4))) begin
            B_RX_bram_addrb <= read_bram_cnt - 3;
        end
        else begin
            B_RX_bram_addrb <= 11'b0;
        end
    end

    wire write_header_en;
    assign write_header_en = ((bram_packet_type==`A2B_CORRECT_PARITY)||(bram_packet_type==`A2B_TARGET_HASHTAG))? 1'b1:1'b0;


    wire B_A2B_wr_en;
    wire [31:0] B_A2B_wr_din;

    assign B_A2B_wr_en = ((read_bram_cnt>(7 - write_header_en))&&(read_bram_cnt<(bram_real_depth+8)))? 1'b1:1'b0;
    assign B_A2B_wr_din = (B_A2B_wr_en)? B_RX_bram_doutb_ff:32'b0;

//****************************** read from BRAM ******************************




//****************************** RX port sel ******************************



    assign B_RX_er_wr_en = ((bram_packet_type==`A2B_CORRECT_PARITY) || (bram_packet_type==`A2B_TARGET_HASHTAG))? 
                                B_A2B_wr_en:1'b0;
    assign B_RX_er_wr_din = ((bram_packet_type==`A2B_CORRECT_PARITY) || (bram_packet_type==`A2B_TARGET_HASHTAG))? 
                                B_A2B_wr_din:32'b0;

    assign B_RX_Zbasis_decoy_wr_en = ((bram_packet_type==`A2B_Z_BASIS_DECOY))? 
                                B_A2B_wr_en:1'b0;
    assign B_RX_Zbasis_decoy_wr_din = ((bram_packet_type==`A2B_Z_BASIS_DECOY))? 
                                B_A2B_wr_din:32'b0;

    assign B_RX_secretkey_length_wr_en = ((bram_packet_type==`A2B_SECRETKEY_LENGTH))? 
                                B_A2B_wr_en:1'b0;
    assign B_RX_secretkey_length_wr_din = ((bram_packet_type==`A2B_SECRETKEY_LENGTH))? 
                                B_A2B_wr_din:32'b0;


    assign B_RX_EVrandombit_wea = ((bram_packet_type==`A2B_EV_RANDOMBIT)&&B_A2B_wr_en)? 
                                        (RX_randombit_we_sel):1'b0;
    assign B_RX_EVrandombit_dina = ((bram_packet_type==`A2B_EV_RANDOMBIT)&&RX_randombit_we_sel)?
                                        ({B_A2B_wr_din_delay, B_A2B_wr_din}):64'b0;

    assign B_RX_PArandombit_wea = ((bram_packet_type==`A2B_PA_RANDOMBIT)&&B_A2B_wr_en)? 
                                        (RX_randombit_we_sel):1'b0;
    assign B_RX_PArandombit_dina = ((bram_packet_type==`A2B_PA_RANDOMBIT)&&RX_randombit_we_sel)?
                                        ({B_A2B_wr_din_delay, B_A2B_wr_din}):64'b0;



    always @(posedge clk ) begin
        if (~rst_n) begin
            B_RX_EVrandombit_addra <= 14'b0;
        end
        else if (reset_er_parameter) begin
            B_RX_EVrandombit_addra <= 14'b0;
        end
        else if (B_RX_EVrandombit_wea) begin
            B_RX_EVrandombit_addra <= B_RX_EVrandombit_addra + 1;
        end
        else begin
            B_RX_EVrandombit_addra <= B_RX_EVrandombit_addra;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            B_RX_PArandombit_addra <= 14'b0;
        end
        else if (reset_pa_parameter) begin
            B_RX_PArandombit_addra <= 14'b0;
        end
        else if (B_RX_PArandombit_wea) begin
            B_RX_PArandombit_addra <= B_RX_PArandombit_addra + 1;
        end
        else begin
            B_RX_PArandombit_addra <= B_RX_PArandombit_addra;
        end
    end


    // RX bram 32 bit -> randombit bram 64 bit
    reg [31:0] B_A2B_wr_din_delay;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_A2B_wr_din_delay <= 32'b0;
        end
        else begin
            B_A2B_wr_din_delay <= B_A2B_wr_din;
        end
    end

    reg RX_randombit_we_sel;
    always @(posedge clk ) begin
        if (~rst_n) begin
            RX_randombit_we_sel <= 1'b0;
        end
        else if (reset_parameter) begin
            RX_randombit_we_sel <= 1'b0;
        end
        else if (B_A2B_wr_en) begin
            RX_randombit_we_sel <= ~RX_randombit_we_sel;
        end
        else begin
            RX_randombit_we_sel <= RX_randombit_we_sel;
        end
    end
//****************************** RX port sel ******************************




//****************************** EV random bit full ******************************
    reg [31:0] EVrandombit_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            EVrandombit_bram_cnt <= 32'b0;
        end
        else if (reset_er_parameter) begin
            EVrandombit_bram_cnt <= 32'b0;
        end
        else if (reset_parameter && (bram_packet_type==`A2B_EV_RANDOMBIT)) begin
            EVrandombit_bram_cnt <= EVrandombit_bram_cnt + 1;
        end
        else begin
            EVrandombit_bram_cnt <= EVrandombit_bram_cnt;
        end
    end
    assign EVrandombit_full = (EVrandombit_bram_cnt==32);
//****************************** EV random bit full ******************************
//****************************** PA random bit full ******************************
    reg [31:0] PArandombit_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            PArandombit_bram_cnt <= 32'b0;
        end
        else if (reset_pa_parameter) begin
            PArandombit_bram_cnt <= 32'b0;
        end
        else if (reset_parameter && (bram_packet_type==`A2B_PA_RANDOMBIT)) begin
            PArandombit_bram_cnt <= PArandombit_bram_cnt + 1;
        end
        else begin
            PArandombit_bram_cnt <= PArandombit_bram_cnt;
        end
    end
    assign PArandombit_full = (PArandombit_bram_cnt==32);
//****************************** PA random bit full ******************************



endmodule

















module B_unpacket_fsm (
    input clk,
    input rst_n,

    input busy_Net2PP_RX,
    input msg_accessed,
    input write_fifo_bram_done,


    input wire B_RX_Zbasis_decoy_full,
    input wire B_RX_er_full,

    output reg busy_PP2Net_RX,
    output reg set_parameter_en,
    output reg read_bram_header_en,
    output reg write_fifo_bram_en,
    output reg reset_parameter,

    output reg [3:0] B_unpacket_state

);

    localparam IDLE                 = 4'd0;
    localparam READ_BRAM_HEADER     = 4'd1;
    localparam SET_PARAMETER        = 4'd2;
    localparam WRITE_FIFO_BRAM      = 4'd3;
    localparam UNPACKET_DONE        = 4'd4;
    localparam WAIT_NEXT_PACKET     = 4'd5;


    reg [3:0] next_B_unpacket_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_unpacket_state <= IDLE;
        end
        else begin
            B_unpacket_state <= next_B_unpacket_state;
        end
    end


    always @(*) begin
        case (B_unpacket_state)
            IDLE: begin
                if (msg_accessed && (~busy_Net2PP_RX) && (~B_RX_Zbasis_decoy_full) && (~B_RX_er_full)) begin
                // if (msg_accessed && (~busy_Net2PP_RX)) begin
                    next_B_unpacket_state = READ_BRAM_HEADER;
                    busy_PP2Net_RX = 1'b0;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_B_unpacket_state = IDLE;
                    busy_PP2Net_RX = 1'b0;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end

            READ_BRAM_HEADER: begin
                next_B_unpacket_state = SET_PARAMETER;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b1;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end

            SET_PARAMETER: begin
                next_B_unpacket_state = WRITE_FIFO_BRAM;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b1;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end

            WRITE_FIFO_BRAM: begin
                if (write_fifo_bram_done) begin
                    next_B_unpacket_state = UNPACKET_DONE;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b1;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_B_unpacket_state = WRITE_FIFO_BRAM;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b1;
                    reset_parameter = 1'b0;
                end
            end


            UNPACKET_DONE: begin
                next_B_unpacket_state = WAIT_NEXT_PACKET;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b1;
            end

            WAIT_NEXT_PACKET: begin
                if (~msg_accessed) begin
                    next_B_unpacket_state = IDLE;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_B_unpacket_state = WAIT_NEXT_PACKET;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end






            default: begin
                next_B_unpacket_state = IDLE;
                busy_PP2Net_RX = 1'b0;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end
        endcase
    end


endmodule