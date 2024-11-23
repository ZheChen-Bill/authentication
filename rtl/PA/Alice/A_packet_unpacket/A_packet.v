`include "./packet_parameter.v"


module A_packet(
    input clk,
//    input clkRX_msg,
    input rst_n,

    input gmii_rx_dv,
    input busy_Net2PP_TX,

    output busy_PP2Net_TX,
    output msg_stored,
    output reg [10:0] sizeTX_msg,

    output wire [3:0] A_packet_state,


    // A_A2B decoy fifo
    output wire A_TX_decoy_rd_clk,
    output wire A_TX_decoy_rd_en,
    input wire [31:0] A_TX_decoy_rd_dout,
    input wire A_TX_decoy_empty,
    input wire A_TX_decoy_rd_valid,

    // A_A2B er fifo
    output wire A_TX_er_rd_clk,
    output wire A_TX_er_rd_en,
    input wire [31:0] A_TX_er_rd_dout,
    input wire A_TX_er_empty,
    input wire A_TX_er_rd_valid,


    // A_A2B pa fifo
    output wire A_TX_pa_rd_clk,
    output wire A_TX_pa_rd_en,
    input wire [31:0] A_TX_pa_rd_dout,
    input wire A_TX_pa_empty,
    input wire A_TX_pa_rd_valid,


    // TX BRAM
    output wire A_TX_bram_clkb,
    output wire A_TX_bram_enb,
    output reg A_TX_bram_web,
    output reg [10:0] A_TX_bram_addrb,
    output reg [31:0] A_TX_bram_dinb

);

//****************************** FIFO setup ******************************
    // A_A2B decoy fifo
    assign A_TX_decoy_rd_clk = clk;
    // A_A2B er fifo
    assign A_TX_er_rd_clk = clk;
    // A_A2B pa fifo
    assign A_TX_pa_rd_clk = clk;
//****************************** FIFO setup ******************************
//****************************** BRAM setup ******************************
    assign A_TX_bram_clkb = clk;
    assign A_TX_bram_enb = 1'b1;
//****************************** BRAM setup ******************************
//****************************** A packet fsm ******************************
    // Input 
    // wire clk;
    // wire rst_n;
    // wire busy_Net2PP_TX;
    // wire A_TX_decoy_rd_valid;
    // wire A_TX_er_rd_valid;
    // wire A_TX_pa_rd_valid;
    wire write_bram_done;

    // Output 
    // reg msg_stored;
    // reg busy_PP2Net_TX;
    wire set_parameter_en;
    wire read_header_en;
    wire write_bram_en;
    wire reset_parameter;
    wire [3:0] A_packet_state;

    A_packet_fsm Apacket_fsm (
        .clk(clk),                           // Clock signal
        .rst_n(rst_n),                       // Reset signal

        .busy_Net2PP_TX(busy_Net2PP_TX),     // Input indicating the network to post-processing transmission is busy
        .gmii_rx_dv(gmii_rx_dv),
        .A_TX_decoy_rd_valid(A_TX_decoy_rd_valid), // Input valid signal for decoy read
        .A_TX_er_rd_valid(A_TX_er_rd_valid),       // Input valid signal for error reconciliation read
        .A_TX_pa_rd_valid(A_TX_pa_rd_valid),       // Input valid signal for post-authentication read

        .write_bram_done(write_bram_done),   // Input signal indicating write to BRAM is done

        .msg_stored(msg_stored),             // Output indicating message is stored
        .busy_PP2Net_TX(busy_PP2Net_TX),     // Output indicating post-processing to network transmission is busy
        .set_parameter_en(set_parameter_en), // Output to enable setting parameters
        .read_header_en(read_header_en),     // Output to enable reading header
        .write_bram_en(write_bram_en),       // Output to enable writing to BRAM

        .reset_parameter(reset_parameter),
        .A_packet_state(A_packet_state)      // Output register for A's packet state
    );
//****************************** A packet fsm ******************************





//****************************** input fifo sel ******************************
    // wire set_parameter_en;
    // wire A_TX_decoy_rd_valid;
    // wire A_TX_er_rd_valid;
    // wire A_TX_pa_rd_valid;

    reg A_TX_decoy_fifo_sel;
    reg A_TX_er_fifo_sel;
    reg A_TX_pa_fifo_sel;

    wire A_A2B_rd_en;
    reg [31:0] A_A2B_rd_dout;

    assign A_TX_decoy_rd_en = (A_TX_decoy_fifo_sel)? A_A2B_rd_en:1'b0;
    assign A_TX_er_rd_en = (A_TX_er_fifo_sel)? A_A2B_rd_en:1'b0;
    assign A_TX_pa_rd_en = (A_TX_pa_fifo_sel)? A_A2B_rd_en:1'b0;

    always @(*) begin
        if(A_TX_decoy_fifo_sel) begin
            A_A2B_rd_dout = A_TX_decoy_rd_dout;
        end
        else if(A_TX_er_fifo_sel) begin
            A_A2B_rd_dout = A_TX_er_rd_dout;
        end
        else if(A_TX_pa_rd_valid) begin
            A_A2B_rd_dout = A_TX_pa_rd_dout;
        end
        else begin
            A_A2B_rd_dout = 32'b0;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            A_TX_decoy_fifo_sel <= 1'b0;
        end
        else if (set_parameter_en && A_TX_decoy_rd_valid) begin
            A_TX_decoy_fifo_sel <= 1'b1;
        end
        else if (reset_parameter) begin
            A_TX_decoy_fifo_sel <= 1'b0;
        end
        else begin
            A_TX_decoy_fifo_sel <= A_TX_decoy_fifo_sel;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            A_TX_er_fifo_sel <= 1'b0;
        end
        else if (set_parameter_en && A_TX_er_rd_valid) begin
            A_TX_er_fifo_sel <= 1'b1;
        end
        else if (reset_parameter) begin
            A_TX_er_fifo_sel <= 1'b0;
        end
        else begin
            A_TX_er_fifo_sel <= A_TX_er_fifo_sel;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            A_TX_pa_fifo_sel <= 1'b0;
        end
        else if (set_parameter_en && A_TX_pa_rd_valid) begin
            A_TX_pa_fifo_sel <= 1'b1;
        end
        else if (reset_parameter) begin
            A_TX_pa_fifo_sel <= 1'b0;
        end
        else begin
            A_TX_pa_fifo_sel <= A_TX_pa_fifo_sel;
        end
    end
//****************************** input fifo sel ******************************








//****************************** header ******************************
    reg [31:0] header_ff;
    always @(posedge clk ) begin
        if (~rst_n)begin
            header_ff <= 32'b0;
        end


        else if (read_header_en ) begin
            header_ff <= A_A2B_rd_dout;
        end



        else if (reset_parameter) begin
            header_ff <= 32'b0;
        end

        else begin
            header_ff <= header_ff;
        end
    end

    reg [10:0] real_depth;
    wire [`PACKET_LENGTH_WIDTH-1:0] packet_depth;
    assign packet_depth = header_ff[27:24];


    wire [`PACKET_TYPE_WIDTH-1:0] packet_type;
    assign packet_type = header_ff[31:28];

    always @(*) begin
        if (packet_depth==`PACKET_LENGTH_257) begin
            real_depth = header_ff[23:15];
            sizeTX_msg = 11'd257;
        end
        else if (packet_depth==`PACKET_LENGTH_514) begin
            real_depth = 11'd512;
            sizeTX_msg = 11'd514;
        end
        else if (packet_depth==`PACKET_LENGTH_771) begin
            real_depth = 11'd768;
            sizeTX_msg = 11'd771;
        end
        else if (packet_depth==`PACKET_LENGTH_1028) begin
            real_depth = 11'd1024;
            sizeTX_msg = 11'd1028;
        end
        else begin
            real_depth = 11'd1024;
            sizeTX_msg = 11'd1028;
        end
    end

//****************************** header ******************************

//****************************** write to BRAM ******************************
    reg [10:0] write_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            write_bram_cnt <= 11'b0;
        end
        else if (write_bram_en) begin
            write_bram_cnt <= write_bram_cnt + 1;
        end
        else if (reset_parameter) begin
            write_bram_cnt <= 11'b0;
        end
        else begin
            write_bram_cnt <= write_bram_cnt;
        end
    end

    assign write_bram_done = (write_bram_cnt==(real_depth+5))? 1'b1:1'b0;

    assign A_A2B_rd_en = ((write_bram_cnt>0)&&(write_bram_cnt<(real_depth+2)))? 1'b1:1'b0;




    always @(posedge clk ) begin
        if (~rst_n) begin
            A_TX_bram_addrb <= 11'b0;
            A_TX_bram_web <= 1'b0;
            A_TX_bram_dinb <= 32'b0;
        end
        else if (A_A2B_rd_en&&(packet_type==`A2B_CORRECT_PARITY)&&(header_ff[14])&&(write_bram_cnt==(real_depth+1))) begin
            A_TX_bram_addrb <= 0;
            A_TX_bram_web <= 1'b1;
            A_TX_bram_dinb <= A_A2B_rd_dout;
        end
        else if (A_A2B_rd_en) begin
            A_TX_bram_addrb <= write_bram_cnt-1;
            A_TX_bram_web <= 1'b1;
            A_TX_bram_dinb <= A_A2B_rd_dout;
        end
        else begin
            A_TX_bram_addrb <= 11'b0;
            A_TX_bram_web <= 1'b0;
            A_TX_bram_dinb <= 32'b0;
        end
    end
//****************************** write to BRAM ******************************
//****************************** read from BRAM *****************************

//    reg busy_PP2Net_RX_next;
    
//    always @(posedge clkRX_msg or negedge rst_n) begin
//        if (~rst_n) begin
//            busy_PP2Net_RX <= 1'b0;
//        end else begin
//            busy_PP2Net_RX <= busy_PP2Net_RX_next;
//        end
//    end 
    
//        // RX part 
//    reg [2:0] fsm_RX, fsm_RX_next;
//    reg [10:0] sizeRX_msg_stored, sizeRX_msg_stored_next;
//    reg [10:0] addrRX_BRAM_access, addrRX_BRAM_access_next;     // addr used to access the msg stored in BRAMMsg
//    reg [10:0] addrRX_BRAM_jtag, addrRX_BRAM_jtag_next;         // addr used to store Msg to BRAM in JTAG 
//    reg weRX_BRAM_jtag, weRX_BRAM_jtag_next;
    
//    parameter [2:0] IDLE = 3'd0;    // Wait for msg_accessed 
//    parameter [2:0] STORE = 3'd1;   // Transfer to JTAG 
    
//    always @(posedge clkRX_msg or negedge rst_n) begin 
//        if (~rst_n) begin 
//            busy_PP2Net_RX <= 1'b0;
//            fsm_RX <= IDLE;
//            sizeRX_msg_stored <= 11'd0;
//            addrRX_BRAM_access <= 11'd0;
//            addrRX_BRAM_jtag <= 11'd0;
//            weRX_BRAM_jtag <= 1'b0;
//        end else begin 
//            busy_PP2Net_RX <= busy_PP2Net_RX_next;
//            fsm_RX <= fsm_RX_next;
//            sizeRX_msg_stored <= sizeRX_msg_stored_next;
//            addrRX_BRAM_access <= addrRX_BRAM_access_next;
//            addrRX_BRAM_jtag <= addrRX_BRAM_jtag_next;
//            weRX_BRAM_jtag <= weRX_BRAM_jtag_next;
//        end 
//    end 
    
//    always @* begin 
//        fsm_RX_next = fsm_RX; 
//        case (fsm_RX)
//            IDLE: begin 
//                if (msg_accessed) begin 
//                    fsm_RX_next = STORE;
//                end 
//            end                
//            STORE: begin 
//                if (addrRX_BRAM_jtag == sizeRX_msg_stored-1) begin 
//                    fsm_RX_next = IDLE;
//                end 
//            end 
//        endcase
//    end 
    
//    always @* begin 
//        busy_PP2Net_RX_next = busy_PP2Net_RX;
//        if (fsm_RX == IDLE) begin 
//            if (msg_accessed) begin 
//                busy_PP2Net_RX_next = 1'b1;
//            end else begin 
//                busy_PP2Net_RX_next = 1'b0;
//            end 
//        end
//    end 
//    always @* begin 
//        sizeRX_msg_stored_next = sizeRX_msg_stored;
//        if (fsm_RX == IDLE) begin 
//            if (msg_accessed) begin 
//                sizeRX_msg_stored_next = sizeRX_msg;
//            end else begin 
//                sizeRX_msg_stored_next = 11'd0;
//            end 
//        end 

//    end 
//    always @* begin 
//        addrRX_BRAM_access_next = addrRX_BRAM_access;
//        addrRX_BRAM_jtag_next = addrRX_BRAM_jtag;        
//        if (fsm_RX == STORE) begin 
//            if (addrRX_BRAM_access < sizeRX_msg_stored + 2) begin
//                addrRX_BRAM_access_next = addrRX_BRAM_access + 1;
//            end else begin 
//                addrRX_BRAM_access_next = addrRX_BRAM_access;
//            end 
//        end else begin 
//            addrRX_BRAM_access_next = 11'd0;
//        end 
//        if (fsm_RX == STORE) begin 
//            if ((addrRX_BRAM_access > 1) && (addrRX_BRAM_jtag < sizeRX_msg_stored-1)) begin 
//                addrRX_BRAM_jtag_next = addrRX_BRAM_jtag + 11'd1;
//            end else begin 
//                addrRX_BRAM_jtag_next = addrRX_BRAM_jtag;
//            end 
//        end else begin 
//            addrRX_BRAM_jtag_next = 11'd0;
//        end 
//    end 
    
//    always @* begin 
//        weRX_BRAM_jtag_next = 1'b0;
//        if ((fsm_RX == STORE) && (addrRX_BRAM_access >= 1) && (addrRX_BRAM_jtag < sizeRX_msg_stored-1)) begin 
//            weRX_BRAM_jtag_next = 1'b1;
//        end 
//    end 

//    wire [31:0] dataRX_jtag;
    
//    wire [10:0] addrRX_BRAM;
//    assign addrRX_BRAM = (fsm_RX == STORE)? addrRX_BRAM_access: addrRX_msg;
//    A2B_BRAM UBRAMMsgRX(
//        .clka(clkRX_msg),    // input wire clka
//        .ena(1'b1),      // input wire ena
//        .wea(weRX_msg),      // input wire [0 : 0] wea
//        .addra(addrRX_BRAM),  // input wire [10 : 0] addra
//        .dina(dataRX_msg),    // input wire [31 : 0] dina
//        .douta(dataRX_jtag) // output wire [31 : 0] dout
//    );
//****************************** read from BRAM *****************************

endmodule

















module A_packet_fsm (
    input clk,
    input rst_n,

    input busy_Net2PP_TX,
    input gmii_rx_dv,
    
    input A_TX_decoy_rd_valid,
    input A_TX_er_rd_valid,
    input A_TX_pa_rd_valid,

    input write_bram_done,


    output reg msg_stored,
    output reg busy_PP2Net_TX,
    output reg set_parameter_en,
    output reg read_header_en,
    output reg write_bram_en,

    output wire reset_parameter,
    output reg [3:0] A_packet_state

);
    localparam IDLE                 = 4'd0;
    localparam SET_PARAMETER        = 4'd1;
    localparam READ_HEADER          = 4'd2;
    localparam WRITE_BRAM           = 4'd3;
    localparam WAIT_NET2PP_TX_1     = 4'd4;
    localparam WAIT_NET2PP_TX_0     = 4'd5;
    // add local parameter for extra delay;
    localparam DELAY     = 4'd6;

    assign reset_parameter = (A_packet_state==IDLE)? 1'b1:1'b0;

    reg [31:0] delay_count;
    always@(posedge clk) begin
        if(~rst_n) begin
            delay_count <= 32'd0;
        end else begin
            if (A_packet_state == DELAY) begin
                delay_count <= delay_count + 1'd1;
            end else begin
                delay_count <= 32'd0;
            end
        end
    end

    reg [3:0] next_A_packet_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_packet_state <= IDLE;
        end
        else begin
            A_packet_state <= next_A_packet_state;
        end
    end

    always @(*) begin
        case (A_packet_state)
            IDLE: begin
                if (((~busy_Net2PP_TX)) && (A_TX_decoy_rd_valid||A_TX_er_rd_valid||A_TX_pa_rd_valid)) begin
                    next_A_packet_state = SET_PARAMETER;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
                else begin
                    next_A_packet_state = IDLE;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
            end

            DELAY: begin
                if (delay_count == 32'd2000) begin
                    next_A_packet_state = SET_PARAMETER;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
                else begin
                    next_A_packet_state = DELAY;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
            end

            SET_PARAMETER: begin
                next_A_packet_state = READ_HEADER;
                read_header_en = 1'b0;
                set_parameter_en = 1'b1;
                write_bram_en = 1'b0;
                msg_stored = 1'b0;
                busy_PP2Net_TX = 1'b1;
            end

            READ_HEADER: begin
                next_A_packet_state = WRITE_BRAM;
                read_header_en = 1'b1;
                set_parameter_en = 1'b0;
                write_bram_en = 1'b0;
                msg_stored = 1'b0;
                busy_PP2Net_TX = 1'b1;
            end

            WRITE_BRAM : begin
                if (write_bram_done) begin
                    next_A_packet_state = WAIT_NET2PP_TX_1;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b1;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b1;
                end
                else begin
                    next_A_packet_state = WRITE_BRAM;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b1;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b1;
                end
            end


            WAIT_NET2PP_TX_1: begin
                if (busy_Net2PP_TX) begin
//                    next_A_packet_state = WAIT_NET2PP_TX_0;
                    next_A_packet_state = IDLE;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b1;
                    busy_PP2Net_TX = 1'b0;
                end
                else begin
                    next_A_packet_state = WAIT_NET2PP_TX_1;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b1;
                    busy_PP2Net_TX = 1'b0;
                end
            end

            WAIT_NET2PP_TX_0: begin
                if (~busy_Net2PP_TX) begin
                    next_A_packet_state = IDLE;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
                else begin
                    next_A_packet_state = WAIT_NET2PP_TX_0;
                    read_header_en = 1'b0;
                    set_parameter_en = 1'b0;
                    write_bram_en = 1'b0;
                    msg_stored = 1'b0;
                    busy_PP2Net_TX = 1'b0;
                end
            end





            default: begin
                next_A_packet_state = IDLE;
                read_header_en = 1'b0;
                set_parameter_en = 1'b0;
                write_bram_en = 1'b0;
                msg_stored = 1'b0;
                busy_PP2Net_TX = 1'b0;
            end
        endcase
    end



endmodule