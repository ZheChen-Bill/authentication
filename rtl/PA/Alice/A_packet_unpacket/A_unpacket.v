

`include "./packet_parameter.v"






module A_unpacket (
    input clk,
    input rst_n,


    input busy_Net2PP_RX,
    input msg_accessed,
    input [10:0] sizeRX_msg,

    output busy_PP2Net_RX,


    input reset_sift_parameter,
    output Zbasis_Xbasis_fifo_full,


    output wire [3:0] A_unpacket_state,



    // A_B2A Zbasis fifo
    output wire A_RX_Zbasis_detected_wr_clk,
    output wire [31:0] A_RX_Zbasis_detected_wr_din,
    output wire A_RX_Zbasis_detected_wr_en,
    input wire A_RX_Zbasis_detected_full,
    input wire A_RX_Zbasis_detected_wr_ack,

    // A_B2A Xbasis fifo
    output wire A_RX_Xbasis_detected_wr_clk,
    output wire [63:0] A_RX_Xbasis_detected_wr_din,
    output wire A_RX_Xbasis_detected_wr_en,
    input wire A_RX_Xbasis_detected_full,
    input wire A_RX_Xbasis_detected_wr_ack,

    // A_B2A er fifo
    output wire A_RX_er_wr_clk,
    output wire [31:0] A_RX_er_wr_din,
    output wire A_RX_er_wr_en,
    input wire A_RX_er_full,
    input wire A_RX_er_wr_ack,


    // RX BRAM
    output wire A_RX_bram_clkb,
    output wire A_RX_bram_enb,
    output wire A_RX_bram_web,
    output reg [10:0] A_RX_bram_addrb,
    input wire [31:0] A_RX_bram_doutb
    

);
//****************************** FIFO setup ******************************
    // A_B2A Zbasis fifo
    assign A_RX_Zbasis_detected_wr_clk = clk;
    // A_B2A Xbasis fifo
    assign A_RX_Xbasis_detected_wr_clk = clk;
    // A_B2A er fifo
    assign A_RX_er_wr_clk = clk;
//****************************** FIFO setup ******************************
//****************************** BRAM setup ******************************
    // RX BRAM
    assign A_RX_bram_clkb = clk;
    assign A_RX_bram_enb = 1'b1;
    assign A_RX_bram_web = 1'b0;
//****************************** BRAM setup ******************************
//****************************** DFF for bram output ******************************
    reg [31:0] A_RX_bram_doutb_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_RX_bram_doutb_ff <= 32'b0;
        end
        else begin
            A_RX_bram_doutb_ff <= A_RX_bram_doutb;
        end
    end
//****************************** DFF for bram output ******************************











//****************************** A unpacket fsm ******************************

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
    wire [3:0] A_unpacket_state;

    A_unpacket_fsm Aunpacket_fsm (
        .clk(clk),                           // Clock signal
        .rst_n(rst_n),                       // Reset signal

        .busy_Net2PP_RX(busy_Net2PP_RX),     // Input indicating the network to post-processing reception is busy
        .msg_accessed(msg_accessed),         // Input indicating message access
        .write_fifo_bram_done(write_fifo_bram_done), // Input indicating write to FIFO/BRAM is done


        .busy_PP2Net_RX(busy_PP2Net_RX),     // Output indicating post-processing to network reception is busy
        .set_parameter_en(set_parameter_en), // Output to enable setting parameters
        .read_bram_header_en(read_bram_header_en),   // Output to enable reading BRAM header
        .write_fifo_bram_en(write_fifo_bram_en),     // Output to enable writing to FIFO/BRAM
        .reset_parameter(reset_parameter),   // Output to reset parameters

        .A_unpacket_state(A_unpacket_state)  // Output register for B's unpacket state
    );

//****************************** A unpacket fsm ******************************





//****************************** read BRAM header ******************************
    reg [31:0] bram_header_ff;
    always @(posedge clk ) begin
        if (~rst_n)begin
            bram_header_ff <= 32'b0;
        end
        else if (read_bram_header_en) begin
            bram_header_ff <= A_RX_bram_doutb_ff;
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
            A_RX_bram_addrb <= 11'b0;
        end
        else if ((read_bram_cnt>2)&&(read_bram_cnt<(bram_real_depth+4))) begin
            A_RX_bram_addrb <= read_bram_cnt - 3;
        end
        else begin
            A_RX_bram_addrb <= 11'b0;
        end
    end

    wire write_header_en;
    assign write_header_en = ((bram_packet_type==`B2A_ASK_PARITY)||(bram_packet_type==`B2A_VERIFICATION_HASHTAG))? 1'b1:1'b0;


    wire A_B2A_wr_en;
    wire [31:0] A_B2A_wr_din;

    assign A_B2A_wr_en = ((read_bram_cnt>(7 - write_header_en))&&(read_bram_cnt<(bram_real_depth+8)))? 1'b1:1'b0;
    assign A_B2A_wr_din = (A_B2A_wr_en)? A_RX_bram_doutb_ff:32'b0;

//****************************** read from BRAM ******************************






//****************************** RX port sel ******************************



    assign A_RX_er_wr_en = ((bram_packet_type==`B2A_ASK_PARITY) || (bram_packet_type==`B2A_VERIFICATION_HASHTAG))? 
                                A_B2A_wr_en:1'b0;
    assign A_RX_er_wr_din = ((bram_packet_type==`B2A_ASK_PARITY) || (bram_packet_type==`B2A_VERIFICATION_HASHTAG))? 
                                A_B2A_wr_din:32'b0;

    assign A_RX_Zbasis_detected_wr_en = ((bram_packet_type==`B2A_Z_BASIS_DETECTED))? 
                                A_B2A_wr_en:1'b0;
    assign A_RX_Zbasis_detected_wr_din = ((bram_packet_type==`B2A_Z_BASIS_DETECTED))? 
                                A_B2A_wr_din:32'b0;

    assign A_RX_Xbasis_detected_wr_en = ((bram_packet_type==`B2A_X_BASIS_DETECTED)&&A_B2A_wr_en)? 
                                        (A_RX_Xbasis_detected_wr_en_sel):1'b0;
    assign A_RX_Xbasis_detected_wr_din = ((bram_packet_type==`B2A_X_BASIS_DETECTED)&&A_RX_Xbasis_detected_wr_en_sel)?
                                        ({A_B2A_wr_din_delay, A_B2A_wr_din}):64'b0;






    // RX bram 32 bit -> Xbasis fifo 64 bit
    reg [31:0] A_B2A_wr_din_delay;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_B2A_wr_din_delay <= 32'b0;
        end
        else begin
            A_B2A_wr_din_delay <= A_B2A_wr_din;
        end
    end

    reg A_RX_Xbasis_detected_wr_en_sel;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_RX_Xbasis_detected_wr_en_sel <= 1'b0;
        end
        else if (reset_parameter) begin
            A_RX_Xbasis_detected_wr_en_sel <= 1'b0;
        end
        else if (A_B2A_wr_en) begin
            A_RX_Xbasis_detected_wr_en_sel <= ~A_RX_Xbasis_detected_wr_en_sel;
        end
        else begin
            A_RX_Xbasis_detected_wr_en_sel <= A_RX_Xbasis_detected_wr_en_sel;
        end
    end

//****************************** RX port sel ******************************







//****************************** EV random bit full ******************************
    reg [31:0] sift_fifo_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            sift_fifo_cnt <= 32'b0;
        end
        else if (reset_sift_parameter) begin
            sift_fifo_cnt <= 32'b0;
        end
        else if (reset_parameter && ((bram_packet_type==`B2A_X_BASIS_DETECTED)||(bram_packet_type==`B2A_Z_BASIS_DETECTED))) begin
            sift_fifo_cnt <= sift_fifo_cnt + 1;
        end
        else begin
            sift_fifo_cnt <= sift_fifo_cnt;
        end
    end
    assign Zbasis_Xbasis_fifo_full = (sift_fifo_cnt==96);
//****************************** EV random bit full ******************************




endmodule





















module A_unpacket_fsm (
    input clk,
    input rst_n,

    input busy_Net2PP_RX,
    input msg_accessed,
    input write_fifo_bram_done,


    output reg busy_PP2Net_RX,
    output reg set_parameter_en,
    output reg read_bram_header_en,
    output reg write_fifo_bram_en,
    output reg reset_parameter,

    output reg [3:0] A_unpacket_state

);

    localparam IDLE                 = 4'd0;
    localparam READ_BRAM_HEADER     = 4'd1;
    localparam SET_PARAMETER        = 4'd2;
    localparam WRITE_FIFO_BRAM      = 4'd3;
    localparam UNPACKET_DONE        = 4'd4;
    localparam WAIT_NEXT_PACKET     = 4'd5;


    reg [3:0] next_A_unpacket_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_unpacket_state <= IDLE;
        end
        else begin
            A_unpacket_state <= next_A_unpacket_state;
        end
    end


    always @(*) begin
        case (A_unpacket_state)
            IDLE: begin
                if (msg_accessed && (~busy_Net2PP_RX)) begin
                // if (msg_accessed && (~busy_Net2PP_RX)) begin
                    next_A_unpacket_state = READ_BRAM_HEADER;
                    busy_PP2Net_RX = 1'b0;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A_unpacket_state = IDLE;
                    busy_PP2Net_RX = 1'b0;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end

            READ_BRAM_HEADER: begin
                next_A_unpacket_state = SET_PARAMETER;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b1;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end

            SET_PARAMETER: begin
                next_A_unpacket_state = WRITE_FIFO_BRAM;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b1;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end

            WRITE_FIFO_BRAM: begin
                if (write_fifo_bram_done) begin
                    next_A_unpacket_state = UNPACKET_DONE;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b1;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A_unpacket_state = WRITE_FIFO_BRAM;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b1;
                    reset_parameter = 1'b0;
                end
            end


            UNPACKET_DONE: begin
                next_A_unpacket_state = WAIT_NEXT_PACKET;
                busy_PP2Net_RX = 1'b1;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b1;
            end

            WAIT_NEXT_PACKET: begin
                if (~msg_accessed) begin
                    next_A_unpacket_state = IDLE;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A_unpacket_state = WAIT_NEXT_PACKET;
                    busy_PP2Net_RX = 1'b1;
                    set_parameter_en = 1'b0;
                    read_bram_header_en = 1'b0;
                    write_fifo_bram_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end






            default: begin
                next_A_unpacket_state = IDLE;
                busy_PP2Net_RX = 1'b0;
                set_parameter_en = 1'b0;
                read_bram_header_en = 1'b0;
                write_fifo_bram_en = 1'b0;
                reset_parameter = 1'b0;
            end
        endcase
    end


endmodule