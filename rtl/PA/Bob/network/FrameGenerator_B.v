//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 2023/10/28 16:59:02
//// Design Name: 
//// Module Name: FrameGenerator
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


module FrameGenerator_B #(
    parameter DELAY_COUNT = 16'd5000,
    parameter RESET_COUNT = 16'd1000
)
(
    input clk_PP, // clock for storing 8-bit frame data to BRAM
    output clkTX_msg, // clock for accessing BRAMMsgTX
    input clk_GMII, // clock from GMII TX path
    input reset, // system reset

    // Post Processing interface
    //------------------------------------
    input busy_PP2Net_TX, // BRAMMsgTX is used by PP
    output reg busy_Net2PP_TX, // BRAMMsgTX is used by NetworkCentCtrl
    input msg_stored, // msg is stored in BRAMMsgTX by PP 

    input [31:0] dataTX_msg, // message from PP 
    output [10:0] addrTX_msg, // addr for BRAMMsgTX
    input [10:0] sizeTX_msg, // transmitting message size

    // control signals from networkCentCtrl 
    input [3:0] network_fsm_TCP,
    input  ack_received, // If the msg packet is recieved by the other side, ack_received raised to 1 for one cycle of clkTX_msg
    output ack_received_ack,
    input received_valid, // If we received an ack packet, terminate our transmitting process
    input transfer_en,
    (*mark_debug = "TRUE"*) output reg transfer_complete, // if a frame is transmitted, raise to 1 
    output busy,
    output reg busy_TX2CentCtrl,
    input block_TX,
    // data signal from RX path 
    input [31:0] seq_RX,
    input [31:0] ack_RX,


    // GMII Interface (client MAC <=> PCS)
    //------------------------------------
    input            link_status, // Link status: use status_vector[0]
    output reg [7:0]      gmii_txd, // Transmit data from client MAC.
    output reg             gmii_tx_en, // Transmit control signal from client MAC.
    output wire             gmii_tx_er // Transmit control signal from client MAC.

    // Test signal 
    ,
    output [2:0] network_fsm_TX,
    output [7:0] frame_data,
    output [10:0] index_frame,
    output we_frame,

    output [13:0] index_chktcp,
    output [15:0] total_len_TCP,
    output [31:0] data_chktcp,
    output data_chktcp_vld,
    output [15:0]chksum_tcp,
    output data_chktcp_last,
    output chktcp_vld,

    output [2:0] index_chkip,
    output [31:0] data_chkip,
    output data_chkip_vld,
    output [15:0]chksum_ip,
    output data_chkip_last,
    output chkip_vld,

    output [7:0] addra,
    output [63:0] packet_in_crc32_delay,
    output [7:0] keep_crc32_delay,
    output valid_in_crc32_delay,
    output last_crc32_delay,

    output [31:0] crc32_out,
    output crc32_valid,

    output clkb,
    output [10:0] addrb,
    output [7:0] dinb,
    output [7:0] doutb,
    output web,

    output [10:0] addr_cdc,
    output we_cdc,
    output [11:0] index_gmii,
    output tcp_psum_complete,
    (*mark_debug = "TRUE"*) output [15:0] sizeTX_msg_buf,
    (*mark_debug = "TRUE"*) output [15:0] base_addr_tmp,

    output ack_received_cdc_after
);
    `include "networkCentCtrlParam_B.vh"
    reg [4:0] BRAM_PORTA_addr, BRAM_PORTA_addr_next;
    wire BRAM_PORTA_clk;
    wire [31:0]BRAM_PORTA_dout;
    wire [4:0] BASE_ADDR_HEAD;

    assign    BASE_ADDR_HEAD = (ALICE_B == 1)? 5'd0: 5'd14;

    reg [1:0] cnt_clkTX_msg;
    wire [1:0] cnt_clkTX_msg_next;

    reg [11:0] frame_gmii_length;
    reg [7:0] frame_data, frame_data_next;

    reg [10:0] index_frame, index_frame_next; // index  for loading frame data
    reg we_frame_next, we_frame;

    reg [11:0] index_gmii, index_gmii_next;
    wire gmii_tx_en_next;
    assign gmii_tx_er = 1'b0;

    reg [7:0] index_crc, index_crc_next; // index  for transferring gmii_txd
    //    reg [11:0] index_frame, index_frame_next; 
    reg [11:0] frame_data_length; // length of frame data --- unit: byte
    //    wire [10:0] frame_data_length;
    wire [15:0] total_len_IP; // IP datagram length
    wire [15:0] total_len_TCP; // TCP segment length
    reg [15:0] id_next;
    wire [15:0] id;

    reg   [31:0] seq, seq_next;
    reg   [31:0] ack, ack_next;

    //    wire [31:0] seq;
    //    wire [31:0] ack;
    //    reg   [31:0] seq_next;
    //    reg   [31:0] ack_next;

    reg [3:0] trans_head_len;
    reg [11:0] flag;
    reg [15:0] win_size;

    (*mark_debug = "TRUE"*) reg transfer_complete_next;

    reg [31:0] head_bram;
    wire [7:0] dout_cdc;

    (*mark_debug = "TRUE"*) reg [3:0] network_fsm_TX, network_fsm_TX_next;

    // Interface of BRAMFrameTX
    //    assign dina = frame_data;
    // Interface to CRC32
    reg  [7:0] addra;
    wire clka;
    wire [63:0] dina;
    wire [63:0] douta;
    reg  wea;

    // interface to frame data
    wire [10:0] addrb;
    wire clkb;
    wire [7:0] dinb;
    wire [7:0] doutb;
    wire web;

    wire PRE_COMP_TX_cdc;
    wire HANDSHAKE_TCP_cdc;
    wire TRANSFER_TCP_cdc;
    wire LOAD_HEAD_TX_cdc;
    wire HANDSHAKE0_TCP_cdc;
    wire COMPUTE_CRC_TX_cdc;
    wire SEND_TX_cdc;

    reg [15:0] cycle_count; //for TX cycle 
    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            cycle_count <= 16'd0;
        end else if (network_fsm_TX == RESET_TX) begin
            cycle_count <= 16'd0;
        end else if (busy_Net2PP_TX) begin
            cycle_count <= cycle_count + 16'd1;
        end else begin
            cycle_count <= 16'd0;
        end
    end
    reg [15:0] TIMEOUT_COUNT;
    reg [15:0] TIMEOUT_COUNT_NEXT;
    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            TIMEOUT_COUNT <= 16'd0;
        end else begin
            TIMEOUT_COUNT <= TIMEOUT_COUNT_NEXT;
        end
    end

    always@* begin
        TIMEOUT_COUNT_NEXT = TIMEOUT_COUNT;
        case (sizeTX_msg_buf)
            16'd257: begin
                TIMEOUT_COUNT_NEXT = 16'd15000;
            end
            16'd514: begin
                TIMEOUT_COUNT_NEXT = 16'd30000;
            end
            16'd771: begin
                TIMEOUT_COUNT_NEXT = 16'd45000;
            end
            16'd1028: begin
                TIMEOUT_COUNT_NEXT = 16'd60000;
            end
            default: begin
                TIMEOUT_COUNT_NEXT = 16'd60000;
            end
        endcase
    end

    reg [15:0] PACKET_COUNT;
    reg [15:0] PACKET_COUNT_NEXT;
    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            PACKET_COUNT <= 16'd0;
        end else begin
            PACKET_COUNT <= PACKET_COUNT_NEXT;
        end
    end

    always@* begin
        PACKET_COUNT_NEXT = PACKET_COUNT;
        if(network_fsm_TCP == TRANSFER_TCP) begin
            case (network_fsm_TX)
                IDLE_TX: begin
                    PACKET_COUNT_NEXT = 16'd0;
                end
                
                DELAY_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                PRE_COMP_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                LOAD_HEAD_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                COMPUTE_CRC_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                SEND_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                WAIT_LAST_TX: begin
                    PACKET_COUNT_NEXT = PACKET_COUNT + 16'd1;
                end

                RESET_TX: begin
                    PACKET_COUNT_NEXT = 16'd0;
                end
            endcase
        end
    end

    //    assign frame_data_length = frame_gmii_length[11:2] + 1'b1 + |{frame_gmii_length[1:0]};

    // IP datagram length ---- unit: byte
    assign total_len_IP = {4'd0, frame_gmii_length} - 16'd7 - 16'd1 - 16'd14;
    // TCP segment length  ---- unit: byte
    assign total_len_TCP = {4'd0, frame_gmii_length} - 16'd7 - 16'd1 - 16'd14 - 16'd20;

    // Busy signal 
    assign busy = (network_fsm_TX != IDLE_TX);

    //    assign clkTX_msg = cnt_clkTX_msg[1];
    BUFGCE_DIV #(
    .BUFGCE_DIVIDE(4)
    )UclkTX_msg_buf
    (
        .I(clk_PP),
        .CLR(1'b0),
        .CE(1'b1),
        .O(clkTX_msg)
    );

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            cnt_clkTX_msg <= 2'd0;
        end else begin
            cnt_clkTX_msg <= cnt_clkTX_msg_next;
        end
    end

    assign cnt_clkTX_msg_next = cnt_clkTX_msg + 2'd1;
    always @* begin
        frame_gmii_length = 12'd0;
        flag = 12'h018;
        case(network_fsm_TCP)
            HANDSHAKE_TCP: begin
                frame_gmii_length = 12'd66 + 12'd7 + 12'd1;
                flag = 12'h012;
            end
            HANDSHAKE0_TCP: begin
                frame_gmii_length = 12'd66 + 12'd7 + 12'd1;
                flag = 12'h002;
            end
            HANDSHAKE1_TCP: begin
                frame_gmii_length = 12'd54 + 12'd7 + 12'd1;
                flag = 12'h010;
            end
            TRANSFER_TCP: begin
                frame_gmii_length = 12'd54 + 12'd1032 + 12'd7 + 12'd1;
                flag = 12'h018;
            end
            //            ACK_R_TCP: begin // Prepared receiving ACK packet
            //                frame_gmii_length = 12'd54 + 12'd7 + 12'd1;   
            //                flag = 12'h010;
            //            end 
            ACK_T_TCP: begin // Transfer out an ACK packet
                frame_gmii_length = 12'd54 + 12'd7 + 12'd1;
                flag = 12'h010;
            end
        endcase
    end

    always @* begin
        trans_head_len = 4'd5;
        if (network_fsm_TCP == HANDSHAKE0_TCP) begin
            trans_head_len = 16'd8;
        end else if (network_fsm_TCP == HANDSHAKE_TCP) begin
            trans_head_len = 16'd8;
        end
    end
    wire [11:0] index_frame_tcp_body;
    assign index_frame_tcp_body = index_frame - (11'd54 + 11'd8);

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin // Preamable + SFD + Link Header + IP Header + TCP Header
        //            index_frame <= 11'd7 + 11'd1 + 11'd14 + 11'd20+ 11'd20;
            index_frame <= 11'd54;
        end else begin
            index_frame <= index_frame_next;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            we_frame <= 1'b0;
        end else begin
            we_frame <= we_frame_next;
        end
    end

    always @* begin
        we_frame_next = we_frame;
        if (network_fsm_TX == PRE_COMP_TX) begin
            if (data_chktcp_vld) begin
                if (total_len_TCP[10:0] > 11'd20) begin
                    // index_frame - 54 - 8
                    if ((index_frame < (total_len_TCP[10:0]-11'd20 - 1'b1 + 11'd54 + 11'd8)) &&
                    (index_frame >= (11'd54 + 11'd8))) begin
                        we_frame_next = 1'b1;
                    end else begin
                        we_frame_next = 1'b0;
                    end
                end else begin
                    we_frame_next = 1'b0;
                end
            end
        end else if (network_fsm_TX == LOAD_HEAD_TX) begin
            if (index_frame < (11'd54 + 11'd8 - 1)) begin
                we_frame_next = 1'b1;
            end else begin
                we_frame_next = 1'b0;
            end
        end else begin
            we_frame_next = 1'b0;
        end
    end

    //    always @* begin 
    //        we_frame_next = we_frame;
    //        if (network_fsm_TX == PRE_COMP_TX) begin 
    //            if (index_frame < 74) begin 
    //                    we_frame_next = 1;
    //                end else begin 
    //                    we_frame_next = 0;
    //                end 
    //        end else if (network_fsm_TX == LOAD_HEAD_TX) begin 
    //            if (index_frame < 53) begin 
    //                    we_frame_next = 1;
    //                end else begin 
    //                    we_frame_next = 0;
    //                end 
    //        end else begin 
    //            we_frame_next = 0;
    //        end 
    //    end 

    //    always @* begin
    //        index_frame_next = index_frame;
    //        if (network_fsm_TX == PRE_COMP_TX) begin
    //            if (we_frame) begin 
    //                if (index_frame < 74) begin 
    //                    index_frame_next = index_frame + 1;
    //                end else begin 
    //                    index_frame_next = 0;
    //                end 
    //            end 
    //        end else if (network_fsm_TX == LOAD_HEAD_TX) begin 
    //            if (we_frame) begin 
    //                if (index_frame < 53) begin 
    //                    index_frame_next = index_frame + 1;
    //                end else begin 
    //                    index_frame_next = 0;
    //                end 
    //            end 
    //        end else begin 
    //            index_frame_next = 54;
    //        end 
    //    end 

    always @* begin
        index_frame_next = index_frame;
        if (network_fsm_TX == PRE_COMP_TX) begin
            if (we_frame) begin
                if (index_frame < (total_len_TCP[10:0]-11'd20 - 11'd1 + 11'd54 + 11'd8) &&
                (index_frame) >= (11'd54 + 11'd8)) begin
                    index_frame_next = index_frame + 1;
                end else begin
                    index_frame_next = 11'd0;
                end
            end else begin
                if (total_len_TCP[10:0] == 11'd20) begin
                    index_frame_next = 11'd0;
                end
            end
        end else if (network_fsm_TX == LOAD_HEAD_TX) begin
            if (we_frame) begin
                if (index_frame < (11'd54 + 11'd8)) begin
                    index_frame_next = index_frame + 11'd1;
                end else begin
                    index_frame_next = index_frame;
                end
            end
        end else begin
            index_frame_next = (11'd54 + 11'd8);
        end
    end

    reg [15:0] id_act;
    always @(posedge clkTX_msg or posedge reset) begin
        if (reset) begin
            id_act <= ID_TX_B;
        end else begin
            id_act <= id_next;
        end
    end
    always @* begin
        id_next = id_act;
        if ((PRE_COMP_TX_cdc) && (index_chkip == 0)) begin
            id_next = id_act + 1;
        end
    end
    assign    id = (network_fsm_TCP == HANDSHAKE_TCP)? 16'd0: id_act;

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            seq <= 32'd0;
            ack <= 32'd0;
        end else begin
            seq <= seq_next;
            ack <= ack_next;
        end
    end

    always @* begin
        seq_next = seq;
        case (network_fsm_TCP)
            DISCONNECT_TCP: begin
                seq_next = 32'd0;
            end
            HANDSHAKE0_TCP: begin
                seq_next = CLIENT_ISN_B;
            end
            HANDSHAKE_TCP: begin
                seq_next = CLIENT_ISN_B;
            end
            HANDSHAKE1_TCP: begin
                seq_next = ack_RX;
            end
            TRANSFER_TCP: begin
                seq_next = ack_RX;
            end
        endcase
    end

    always @* begin
        ack_next = ack;
        case(network_fsm_TCP)
            DISCONNECT_TCP: begin
                ack_next = 32'd0;
            end
            HANDSHAKE0_TCP: begin
                ack_next = 32'd0;
            end
            HANDSHAKE_TCP: begin
                ack_next = seq_RX + 1;
            end
            HANDSHAKE1_TCP: begin
                ack_next = seq_RX + 1;
            end
            TRANSFER_TCP: begin
                ack_next = seq_RX;
            end
            ACK_T_TCP: begin
                ack_next = seq_RX+1032;
            end
        endcase
    end

    always @* begin
        win_size = 16'h0201;
        if (network_fsm_TCP == HANDSHAKE0_TCP) begin
            win_size = 16'hfaf0;
        end else if (network_fsm_TCP == HANDSHAKE_TCP) begin
            win_size = 16'hfaf0;
        end else if (network_fsm_TCP == TRANSFER_TCP) begin
            win_size = 16'h01f6;
        end
    end

    reg [4:0] header_addr, header_addr_next;

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            header_addr <= 5'd0;
        end else begin
            header_addr <= header_addr_next;
        end
    end

    always @* begin
        header_addr_next = header_addr;
        if (network_fsm_TX != LOAD_HEAD_TX) begin
            header_addr_next = (ALICE_B == 1)? 5'd0: 5'd9;
        end else begin
            if (index_frame[1:0] == LEN_PREAMABLE[1:0]) begin

            end
        end
    end

    reg [31:0] frame_data_buf, frame_data_buf_next;

    reg [31:0] head_other, head_other_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            head_other <= 32'd0;
        end else begin
            head_other <= head_other_next;
        end
    end
    always @* begin
        head_other_next = head_other;
        if ((index_frame[1:0] == (LEN_SFD[1:0] - 2'd2)) && (index_frame > LEN_SFD)) begin
            case(BRAM_PORTA_addr - BASE_ADDR_HEAD)
                5'd4: head_other_next = {total_len_IP, id};
                5'd6: head_other_next = {chksum_ip, 16'd0};
                5'd9: head_other_next = {16'd0, seq[31:16]};
                5'd10: head_other_next = {seq[15:0], ack[31:16]};
                5'd11: head_other_next = {ack[15:0], trans_head_len, flag};
                5'd12: head_other_next = {win_size, chksum_tcp};
                default: head_other_next = 32'd0;
            endcase
        end
    end
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            frame_data_buf <= 32'd0;
        end else begin
            frame_data_buf <= frame_data_buf_next;
        end
    end
    always @* begin
        frame_data_buf_next = {frame_data_buf[23:0], 8'd0};
        if (network_fsm_TX == LOAD_HEAD_TX) begin
            if (index_frame[1:0] == LEN_SFD[1:0]) begin
                //                frame_data_buf_next = {3'd0, BRAM_PORTA_addr, 24'd0};
                //                case(BRAM_PORTA_addr - BASE_ADDR_HEAD)
                //                    5'd4: frame_data_buf_next = {total_len_IP, id};
                //                    5'd6: frame_data_buf_next = BRAM_PORTA_dout | {chksum_ip, 16'd0}; 
                //                    5'd9: frame_data_buf_next = BRAM_PORTA_dout | {16'd0, seq[31:16]}; 
                //                    5'd10: frame_data_buf_next = {seq[15:0], ack[31:16]};
                //                    5'd11: frame_data_buf_next = {ack[15:0], trans_head_len, flag};
                //                    5'd12: frame_data_buf_next = {win_size, chksum_tcp};
                //                    default: frame_data_buf_next = BRAM_PORTA_dout;
                //                endcase  
                frame_data_buf_next = head_bram | head_other;
            end
            //            case(index_frame) 
            //                LEN_SFD: frame_data_buf_next = DES_MAC_TX; // 0 1
            //                LEN_DES_MAC_ADDR: frame_data_buf_next = SRC_MAC_TX; // 12
            //                LEN_SRC_MAC_ADDR: frame_data_buf_next = {TYPE, VERSION, HEADER_LEN, SERVICE_TYPE, total_len_IP};
            //                LEN_TOL_LEN: frame_data_buf_next = (network_fsm_TCP == HANDSHAKE_TCP)? {16'd0, 16'h4000, TIME_TO_LIVE_TX, PROTOCOL}:{id, 16'h4000, TIME_TO_LIVE_TX, PROTOCOL};
            //                LEN_PROTOCOL: frame_data_buf_next = {chksum_ip, SRC_IP_TX};
            //                LEN_SRC_IP:  frame_data_buf_next = {DES_IP_TX, SRC_PORT_TX};
            //                LEN_SRC_PORT: frame_data_buf_next = {DES_PORT_TX, seq};
            //                LEN_SEQ: frame_data_buf_next = {ack, trans_head_len, flag};
            //                LEN_HEAD_CTR: frame_data_buf_next = {win_size, chksum_tcp, URGENT_PTR_TX};
            //            endcase
            //            if (index_frame == LEN_SFD) begin 
            //                frame_data_buf_next = DES_MAC_TX;
            //            end else if (index_frame == LEN_DES_MAC_ADDR) begin 
            //                frame_data_buf_next = SRC_MAC_TX;
            //            end else if (index_frame == LEN_SRC_MAC_ADDR) begin 
            //                frame_data_buf_next = {TYPE, VERSION, HEADER_LEN, SERVICE_TYPE, total_len_IP};
            //            end else if (index_frame == LEN_TOL_LEN) begin 
            //                if (network_fsm_TCP == HANDSHAKE_TCP) begin 
            //                    frame_data_buf_next = {16'd0, 16'h4000, TIME_TO_LIVE_TX, PROTOCOL};
            //                end else begin 
            //                    frame_data_buf_next = {id, 16'h4000, TIME_TO_LIVE_TX, PROTOCOL};
            //                end
            //            end else if (index_frame == LEN_PROTOCOL) begin 
            //                frame_data_buf_next = {chksum_ip, SRC_IP_TX};
            //            end else if (index_frame == LEN_SRC_IP) begin 
            //                frame_data_buf_next = {DES_IP_TX, SRC_PORT_TX};
            //            end else if (index_frame == LEN_SRC_PORT) begin 
            ////                frame_data_buf_next = {DES_PORT_TX, seq};
            //                frame_data_buf_next = {DES_PORT_TX, seq};
            //            end else if (index_frame == LEN_SEQ) begin 
            //                frame_data_buf_next = {ack, trans_head_len, flag};
            //            end else if (index_frame == LEN_HEAD_CTR) begin 
            //                frame_data_buf_next = {win_size, chksum_tcp, URGENT_PTR_TX};
            //            end 
        end else if (network_fsm_TX == PRE_COMP_TX) begin
            if ((index_frame_next[1:0] == 2'b10)) begin
                frame_data_buf_next = data_chktcp;
            end
        end
    end

    //    always @(posedge clk_PP or posedge reset) begin 
    //        if (reset) begin 
    //            frame_data <= 8'h0;
    //        end else begin
    //            frame_data <= frame_data_next;
    //        end 
    //    end 

    always @* begin
        frame_data = 8'h55;
        //        frame_data = index_frame[7:0];
        if (network_fsm_TX == PRE_COMP_TX) begin
            frame_data = frame_data_buf[31:24];
        end
        if (network_fsm_TX == LOAD_HEAD_TX) begin
            if (index_frame <= LEN_PREAMABLE) begin
                frame_data = PREAMABLE;
            end else if (index_frame <= LEN_SFD) begin
                frame_data = START_FRAME_DELIMITER;
            end else if (index_frame > LEN_SFD) begin
                frame_data = frame_data_buf[31:24];
            end
        end
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            index_gmii <= 12'd0;
        end else begin
            index_gmii <= index_gmii_next;
        end
    end

    always @* begin
        index_gmii_next = index_gmii;
        if (SEND_TX_cdc) begin
            if (index_gmii < frame_gmii_length + 3'd6) begin
                index_gmii_next = index_gmii + 1'b1;
            end else begin
                index_gmii_next = index_gmii;
            end
        end else begin
            index_gmii_next = 12'd0;
        end
    end

    reg [7:0] gmii_txd_next;
    reg gmii_tx_en_obuf, gmii_tx_en_obuf_next;
    reg gmii_tx_en_obuf_delay;
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            gmii_tx_en <= 1'b0;
            gmii_txd <= 8'd0;
        end else begin
            gmii_tx_en <= gmii_tx_en_next;
            gmii_txd <= gmii_txd_next;
        end
    end

    assign gmii_tx_en_next = gmii_tx_en_obuf_delay;

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            gmii_tx_en_obuf_delay <= 1'b0;
        end else begin
            gmii_tx_en_obuf_delay <= gmii_tx_en_obuf;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            gmii_tx_en_obuf <= 1'b0;
        end else begin
            gmii_tx_en_obuf <= gmii_tx_en_obuf_next;
        end
    end

    always @* begin
        gmii_tx_en_obuf_next = gmii_tx_en_obuf;
        if (SEND_TX_STATE) begin
            if ((index_gmii >= 1) && (index_gmii < (frame_gmii_length + 3'd5))) begin
                gmii_tx_en_obuf_next = 1'b1;
            end else begin
                gmii_tx_en_obuf_next = 1'b0;
            end
        end else begin
            gmii_tx_en_obuf_next = 1'b0;
        end
    end

    reg [31:0] crc32_out_trans, crc32_out_trans_next;
    always @* begin
        gmii_txd_next = 8'h55;
        if (SEND_TX_STATE) begin
            if ((index_gmii >= 12'd0) && (index_gmii < frame_gmii_length+2)) begin
                //            if ((index_gmii >= 12'd0)) begin 
                gmii_txd_next = dout_cdc;
                //                if (index_gmii == 12'd2) begin 
                //                    gmii_txd_next = frame_gmii_length[7:0] +5;
                //                end else begin 
                //                    gmii_txd_next = index_gmii[7:0];
                //                end
            end
            else if (index_gmii >= frame_gmii_length+2) begin
                case (index_gmii)
                    frame_gmii_length+2: gmii_txd_next = crc32_out_trans[7:0];
                    frame_gmii_length+3: gmii_txd_next = crc32_out_trans[15:8];
                    frame_gmii_length+4: gmii_txd_next = crc32_out_trans[23:16];
                    frame_gmii_length+5: gmii_txd_next = crc32_out_trans[31:24];
                    //                    frame_gmii_length+2: gmii_txd_next = crc32_out[7:0];
                    //                    frame_gmii_length+3: gmii_txd_next = crc32_out[15:8];
                    //                    frame_gmii_length+4: gmii_txd_next = crc32_out[23:16];
                    //                    frame_gmii_length+5: gmii_txd_next = crc32_out[31:24];
                    //                    default: gmii_txd_next = 8'hff;
                endcase

                ////                case(index_gmii - frame_gmii_length - 2)
                ////                    11'd0:
                ////                        gmii_txd_next = crc32_out[7:0];
                ////                    11'd1:
                ////                        gmii_txd_next = crc32_out[15:8];
                ////                    11'd2:
                ////                        gmii_txd_next = crc32_out[23:16];
                ////                    11'd3:
                ////                        gmii_txd_next = crc32_out[31:24];
                ////                    default:
                ////                        gmii_txd_next = 8'hff;
                ////                endcase
            end
        end
    end

    wire SEND_TX_STATE;
    assign SEND_TX_STATE = (network_fsm_TX == SEND_TX) ? 1 : 0;

    // CDC for SEND_TX  signal
    cdc_delay1 u_SEND_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src(SEND_TX_STATE),
        .pulse_des(SEND_TX_cdc)
    );

    reg crc32_valid_delay;

    reg [15:0] delay_cycle;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            delay_cycle <= 16'd0;
        end else begin
            if (network_fsm_TX == DELAY_TX) begin
                delay_cycle <= delay_cycle + 16'd1;
            end else if (network_fsm_TX == RESET_TX) begin
                delay_cycle <= delay_cycle + 16'd1;
            end else begin
                delay_cycle <= 16'd0;
            end
        end
    end
    reg first_packet;
    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            first_packet <= 1'b1;
        end else if (!busy_Net2PP_TX) begin
            first_packet <= 1'b1;
        end else if (network_fsm_TX == RESET_TX) begin
            first_packet <= 1'b1;
        end else if (gmii_tx_en) begin
            first_packet <= 1'b0;
        end else begin
            first_packet <= first_packet;
        end
    end 
    // have been received ack signal
    reg received_ack;
    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            received_ack <= 1'b1;
        end else if (network_fsm_TX == RESET_TX) begin
            received_ack <= 1'b1;
        end else if (ack_received_ack) begin
            received_ack <= 1'b1;
        end else if (gmii_tx_en) begin
            received_ack <= 1'b0;
        end else begin
            received_ack <= received_ack;
        end
    end 
    // FSM for TX path 
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            network_fsm_TX <= IDLE_TX;
        end else begin
            network_fsm_TX <= network_fsm_TX_next;
        end
    end

    always @* begin
        network_fsm_TX_next = network_fsm_TX;
        //        if (network_fsm_TCP != DISCONNECT_TCP && (~block_TX)) begin
        if (network_fsm_TCP != DISCONNECT_TCP) begin
            case (network_fsm_TX)
                IDLE_TX: begin
                   if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                   end else if (transfer_en && ~transfer_complete) begin
                        if (busy_TX2CentCtrl) begin
                            network_fsm_TX_next = DELAY_TX;
                        end else if (network_fsm_TCP == TRANSFER_TCP) begin
                            network_fsm_TX_next = IDLE_TX;
                        end else begin
                            network_fsm_TX_next = PRE_COMP_TX;
                        end
                    end
                end

                DELAY_TX: begin
                    if (first_packet) begin
                        if (base_addr_tmp == sizeTX_msg_buf) begin
                            network_fsm_TX_next = IDLE_TX;
                        end else if (delay_cycle == DELAY_COUNT) begin
                            network_fsm_TX_next = PRE_COMP_TX;
                        end 
                    end else if (received_ack) begin
                        if (delay_cycle == DELAY_COUNT) begin
                            network_fsm_TX_next = PRE_COMP_TX;
                        end else if (base_addr_tmp == sizeTX_msg_buf) begin
                            network_fsm_TX_next = IDLE_TX;
                        end else begin
                            network_fsm_TX_next = DELAY_TX;
                        end
                    end else if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end
                end

                PRE_COMP_TX: begin
                    if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end else if ((base_addr_tmp == sizeTX_msg_buf) && (network_fsm_TCP == TRANSFER_TCP)) begin
                        network_fsm_TX_next = IDLE_TX;
                    end else if (received_valid) begin
                        //                    network_fsm_TX_next = IDLE_TX;
                    end else if (chkip_vld && tcp_psum_complete) begin
                        network_fsm_TX_next = LOAD_HEAD_TX;
                    end
                end

                LOAD_HEAD_TX: begin
                    if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end else if (received_valid) begin
                        //                    network_fsm_TX_next = IDLE_TX;
                    end else if (index_frame == (11'd54 + 11'd8)) begin
                        network_fsm_TX_next = COMPUTE_CRC_TX;
                    end
                end

                COMPUTE_CRC_TX: begin
                    if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end else if (received_valid) begin
                        //                    network_fsm_TX_next = IDLE_TX;
                    end else if (crc32_valid_delay) begin
                        network_fsm_TX_next = SEND_TX;
                    end
                end

                SEND_TX: begin
                    if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end else if (received_valid) begin
                        //                    network_fsm_TX_next = IDLE_TX;
                    end else if (transfer_complete) begin
                        network_fsm_TX_next = WAIT_LAST_TX;
                    end
                    //                if ((index_gmii == frame_gmii_length + 3'd6) && ~transfer_complete) begin
                    //                    network_fsm_TX_next = IDLE_TX;
                    //                end
                end
                
                WAIT_LAST_TX: begin
                    if (cycle_count > TIMEOUT_COUNT) begin
                        network_fsm_TX_next = RESET_TX;
                    end else if (~gmii_tx_en) begin
                        network_fsm_TX_next = TRANSITION_STATE1_TX;
                    end
                end
                
                TRANSITION_STATE1_TX: begin
                    network_fsm_TX_next = TRANSITION_STATE2_TX;
                end
            
                TRANSITION_STATE2_TX: begin
                    network_fsm_TX_next = TRANSITION_STATE3_TX;
                end
            
                TRANSITION_STATE3_TX: begin
                    network_fsm_TX_next = TRANSITION_STATE4_TX;
                end
            
                TRANSITION_STATE4_TX: begin
                    network_fsm_TX_next = IDLE_TX;
                end
                
                RESET_TX: begin
                    if (delay_cycle == RESET_COUNT) begin
                        network_fsm_TX_next = IDLE_TX;
                    end
                end
            endcase

        end else begin
            network_fsm_TX_next = IDLE_TX;
        end
    end

    // control signal
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            transfer_complete <= 1'b0;
        end else begin
            transfer_complete <= transfer_complete_next;
//            transfer_complete <= transfer_complete_delay;
        end
    end

    always @* begin
        transfer_complete_next = transfer_complete;
        if (~transfer_complete) begin
//            if (network_fsm_TX == SEND_TX) begin
            if (SEND_TX_cdc) begin
                if ((index_gmii == frame_gmii_length + 3'd6)) begin
                    transfer_complete_next = 1'b1;
                end
            end
        end else begin
            transfer_complete_next = 1'b0;
        end
        //        if (network_fsm_TX == SEND_TX) begin 
        //            if (index_gmii == frame_gmii_length + 3'd6) begin
        //                transfer_complete_next = 1'b1;
        //            end 
        //        end else if (~transfer_en && ~chkip_vld && ~chktcp_vld)begin 
        //            transfer_complete_next = 1'b0;
        //        end 
    end
    
    reg [2:0] index_chkip, index_chkip_next;
    reg [31:0] data_chkip, data_chkip_next;
    reg data_chkip_vld, data_chkip_vld_next;
    wire [15:0]chksum_ip;
    reg data_chkip_last, data_chkip_last_next;
    wire chkip_vld;
    wire data_chkip_last_next_delay;

    always @(posedge clkTX_msg or posedge reset) begin
        if (reset) begin
            index_chkip <= 3'd0;
            data_chkip <= 32'd0;
            data_chkip_vld <= 1'b0;
            data_chkip_last <= 1'b0;
        end else begin
            index_chkip <= index_chkip_next;
            data_chkip <= data_chkip_next;
            data_chkip_vld <= data_chkip_vld_next;
            data_chkip_last <= data_chkip_last_next;
//            data_chkip_last <= data_chkip_last_next_delay;
        end
    end

    // delay for data_chkip_last cdc
    clock_domain_crossing u_data_chkip_last_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(data_chkip_last_next),
        .pulse_des(data_chkip_last_next_delay)
    );

    always @* begin
        index_chkip_next = index_chkip;
        if (PRE_COMP_TX_cdc) begin
            if (index_chkip < 3'd6) begin
                index_chkip_next = index_chkip + 1;
            end
        end else begin
            index_chkip_next = 3'd0;
        end
    end

    always @* begin
        data_chkip_next = 32'd0;
        if (index_chkip == 3'd0) begin
            data_chkip_next = {VERSION, HEADER_LEN, 8'd0, total_len_IP};
        end else if (index_chkip == 3'd1) begin
            if (HANDSHAKE_TCP_cdc) begin
                data_chkip_next = {16'd0, 16'h4000};
            end else begin
                data_chkip_next = {id, 16'h4000};
            end
        end else if (index_chkip == 3'd2) begin
            data_chkip_next = {TIME_TO_LIVE_TX_B, PROTOCOL, 16'd0};
        end else if (index_chkip == 3'd3) begin
            data_chkip_next = SRC_IP_TX_B;
        end else if (index_chkip == 3'd4) begin
            data_chkip_next = DES_IP_TX_B;
        end
    end

    always @* begin
        data_chkip_vld_next = data_chkip_vld;
        if (PRE_COMP_TX_cdc) begin
            if (index_chkip < 3'd5) begin
                data_chkip_vld_next = 1'b1;
            end else begin
                data_chkip_vld_next = 1'b0;
            end
        end else begin
            data_chkip_vld_next = 1'b0;
        end
    end

    always @* begin
        data_chkip_last_next = data_chkip_last;
        if (PRE_COMP_TX_cdc) begin
            if (index_chkip == 3'd4) begin
                data_chkip_last_next = 1'b1;
            end else begin
                data_chkip_last_next = 1'b0;
            end
        end else begin
            data_chkip_last_next = 1'b0;
        end
    end

    wire PRE_COMP_TX_STATE;
    assign PRE_COMP_TX_STATE = (network_fsm_TX == PRE_COMP_TX) ? 1 : 0;

    // CDC for PRE_COMP_TX  signal
    cdc_delay1 u_PRE_COMP_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(PRE_COMP_TX_STATE),
        .pulse_des(PRE_COMP_TX_cdc)
    );

    ChksumTCPIP UchksumTCP(
        .clk(clkTX_msg),
        .reset(reset),

        .data(data_chkip),
        .data_vld(data_chkip_vld),
        .data_last(data_chkip_last),
        .chksum(chksum_ip),
        .chksum_vld(chkip_vld),
        .chksum_ready(IDLE_TX_cdc)
    );

    wire chkip_vld_cdc;
    // CDC for chkip_vld signal
    cdc_delay1 u_chkip_vld_cdc(
        .clk_src(clkTX_msg),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(chkip_vld),
        .pulse_des(chkip_vld_cdc)
    );

    reg [13:0] index_chktcp, index_chktcp_next;
    reg [31:0] data_chktcp, data_chktcp_next;
    reg data_chktcp_vld, data_chktcp_vld_next;
    wire [15:0]chksum_tcp;
    reg data_chktcp_last, data_chktcp_last_next;
    wire chktcp_vld;

    // reg tcp_psum_complete, tcp_psum_complete_next;
    // ADD CDC interface for tcp_psum_complete (clkPP and clkTX)
    reg tcp_psum_complete;
    wire tcp_psum_complete_cdc;
    reg tcp_psum_complete_next;

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            tcp_psum_complete <= 1'b0;
        end else begin
            tcp_psum_complete <= tcp_psum_complete_cdc;
        end
    end

    cdc_delay1 u_tcp_psum_complete_cdc(
        .clk_src(clkTX_msg),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(tcp_psum_complete_next),
        .pulse_des(tcp_psum_complete_cdc)
    );

    always @* begin
        tcp_psum_complete_next = tcp_psum_complete_cdc;
        if (PRE_COMP_TX_cdc) begin
            if (!TRANSFER_TCP_cdc) begin
                if (total_len_TCP != 20) begin
                    if ((index_chktcp == (total_len_TCP[15:2]-14'd5)) && (index_frame_tcp_body == total_len_TCP[10:0] - 11'd20 - 11'd2)) begin
                        tcp_psum_complete_next = 1'b1;
                    end
                end else begin
                    tcp_psum_complete_next = 1'b1;
                end
            end else begin
                if ((index_chktcp == 0) && (index_frame == 0)) begin
                    tcp_psum_complete_next = 1'b1;
                end
            end
        end else begin
            tcp_psum_complete_next = 1'b0;
        end
    end


    always @(posedge clkTX_msg or posedge reset) begin
        if (reset) begin
            index_chktcp <= 14'd0;
            data_chktcp <= 32'd0;
            data_chktcp_vld <= 1'b0;
            data_chktcp_last <= 1'b0;
        end else begin
            index_chktcp <= index_chktcp_next;
            data_chktcp <= data_chktcp_next;
            data_chktcp_vld <= data_chktcp_vld_next;
            data_chktcp_last <= data_chktcp_last_next;
        end
    end

    always @* begin
        index_chktcp_next = index_chktcp;
        if ((PRE_COMP_TX_cdc) && (~tcp_psum_complete)) begin
            // TCP body  ---- unit: 4bytes        
            // all the msg block should be 32 bits long --> No remainder
            if (!TRANSFER_TCP_cdc) begin
                if (index_chktcp < (total_len_TCP[15:2]-14'd5)) begin
                    index_chktcp_next = index_chktcp + 1;
                end else begin
                    index_chktcp_next = 14'd0;
                end
            end else begin // 2 is the delay of read cycle from BRAMMsgTX
                if (index_chktcp < (total_len_TCP[15:2]-14'd5+14'd2-14'd1)) begin
                    index_chktcp_next = index_chktcp + 1;
                end else begin
                    index_chktcp_next = 14'd0;
                end
            end
        end else if (LOAD_HEAD_TX_cdc) begin
            if (index_chktcp < 14'd9) begin
                index_chktcp_next = index_chktcp + 1;
            end else begin
                index_chktcp_next = index_chktcp;
            end
        end else begin
            index_chktcp_next = 14'd0;
        end
    end

    always @* begin
        data_chktcp_next = 32'd0;
        if (PRE_COMP_TX_cdc) begin
            if(HANDSHAKE0_TCP_cdc) begin
                if (index_chktcp == 14'd0) begin
                    data_chktcp_next = 32'h020405b4;
                end else if (index_chktcp == 14'd1) begin
                    data_chktcp_next = 32'h01030308;
                end else if (index_chktcp == 14'd2) begin
                    data_chktcp_next = 32'h01010402;
                end
            end else if (HANDSHAKE_TCP_cdc) begin
                if (index_chktcp == 14'd0) begin
                    data_chktcp_next = 32'h020405b4;
                end else if (index_chktcp == 14'd1) begin
                    data_chktcp_next = 32'h01010402;
                end else if (index_chktcp == 14'd2) begin
                    data_chktcp_next = 32'h01030307;
                end
            end else if (TRANSFER_TCP_cdc) begin
                if (index_chktcp == 0) begin
                    data_chktcp_next = 32'd0;
                end else if (index_chktcp == 1) begin
                    data_chktcp_next = {sizeTX_msg_buf, base_addr_tmp};
                end else begin
                    data_chktcp_next = dataTX_msg;
                end
            end
        end else if (LOAD_HEAD_TX_cdc) begin
            if (index_chktcp == 14'd0) begin // TCP header
                data_chktcp_next = {SRC_PORT_TX_B, DES_PORT_TX_B};
            end else if (index_chktcp == 14'd1) begin
                data_chktcp_next = {seq};
            end else if (index_chktcp == 14'd2) begin
                data_chktcp_next = {ack};
            end else if (index_chktcp == 14'd3) begin
                data_chktcp_next = {trans_head_len, flag, win_size};
            end else if (index_chktcp == 14'd4) begin
                data_chktcp_next = 0;
            end else if (index_chktcp == 14'd5) begin // Pseudo IP header
                data_chktcp_next = SRC_IP_TX_B;
            end else if (index_chktcp == 14'd6) begin
                data_chktcp_next = DES_IP_TX_B;
            end else if (index_chktcp == 14'd7) begin
                data_chktcp_next = {8'd0, PROTOCOL, total_len_TCP[15:0]};
            end
        end
    end

    always @* begin
        data_chktcp_vld_next = data_chktcp_vld;
        if (PRE_COMP_TX_cdc) begin
            if (!TRANSFER_TCP_cdc) begin
                if ((index_chktcp < (total_len_TCP[15:2]-14'd5)) && (~tcp_psum_complete)) begin
                    data_chktcp_vld_next = 1'b1;
                end else begin
                    data_chktcp_vld_next = 1'b0;
                end
            end else begin
                if (index_chktcp < 14'd1) begin
                    data_chktcp_vld_next = 1'b0;
                end else if ((index_chktcp < (total_len_TCP[15:2]-14'd5+14'd2-14'd1))) begin
                    data_chktcp_vld_next = 1'b1;
                end else begin
                    data_chktcp_vld_next = 1'b0;
                end
            end
        end else if (LOAD_HEAD_TX_cdc) begin
            if (index_chktcp < 14'd8) begin
                data_chktcp_vld_next = 1'b1;
            end else begin
                data_chktcp_vld_next = 1'b0;
            end
        end else begin
            data_chktcp_vld_next = 1'b0;
        end
    end

    always @* begin
        data_chktcp_last_next = data_chktcp_last;
        if (LOAD_HEAD_TX_cdc) begin
            if (index_chktcp == 14'd7) begin
                data_chktcp_last_next = 1'b1;
            end else begin
                data_chktcp_last_next = 1'b0;
            end
        end else begin
            data_chktcp_last_next = 1'b0;
        end
    end

    wire TRANSFER_TCP_STATE;
    assign TRANSFER_TCP_STATE = (network_fsm_TCP == TRANSFER_TCP) ? 1 : 0;

    // CDC for TRANSFER_TCP  signal
    cdc_delay1 u_TRANSFER_TCP_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(TRANSFER_TCP_STATE),
        .pulse_des(TRANSFER_TCP_cdc)
    );

    wire HANDSHAKE0_TCP_STATE;
    assign HANDSHAKE0_TCP_STATE = (network_fsm_TCP == HANDSHAKE0_TCP) ? 1 : 0;

    // CDC for HANDSHAKE0_TCP  signal
    cdc_delay1 u_HANDSHAKE0_TCP_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(HANDSHAKE0_TCP_STATE),
        .pulse_des(HANDSHAKE0_TCP_cdc)
    );

    wire HANDSHAKE_TCP_STATE;
    assign HANDSHAKE_TCP_STATE = (network_fsm_TCP == HANDSHAKE_TCP) ? 1 : 0;

    // CDC for HANDSHAKE_TCP signal
    cdc_delay1 u_HANDSHAKE_TCP_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(HANDSHAKE_TCP_STATE),
        .pulse_des(HANDSHAKE_TCP_cdc)
    );

    wire LOAD_HEAD_TX_STATE;
    assign LOAD_HEAD_TX_STATE = (network_fsm_TX == LOAD_HEAD_TX) ? 1 : 0;

    // CDC for LOAD_HEAD_TX  signal
    cdc_delay1 u_LOAD_HEAD_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(LOAD_HEAD_TX_STATE),
        .pulse_des(LOAD_HEAD_TX_cdc)
    );

    ChksumTCPIP Uchktcp(
        .clk(clkTX_msg),
        .reset(reset),

        .data(data_chktcp),
        //        .data_vld(data_chktcp_vld),
        .data_vld(tcp_vld),

        .data_last(data_chktcp_last),
        .chksum(chksum_tcp),
        .chksum_vld(chktcp_vld),
        .chksum_ready(IDLE_TX_cdc)
    );

    wire IDLE_TX_cdc;
    wire IDLE_TX_state;
    assign IDLE_TX_state = (network_fsm_TX == IDLE_TX) ? 1 : 0;

    // CDC for IDLE_TX_state (chksum_ready) signal
    cdc_delay1 u_IDLE_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(IDLE_TX_state),
        .pulse_des(IDLE_TX_cdc)
    );

    wire DELAY_TX_cdc;
    wire DELAY_TX_state;
    assign DELAY_TX_state = (network_fsm_TX == DELAY_TX) ? 1 : 0;

    // CDC for IDLE_TX_state (chksum_ready) signal
    cdc_delay1 u_DELAY_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(DELAY_TX_state),
        .pulse_des(DELAY_TX_cdc)
    );

    // add control singal and condition for ChksumTCPIP(TCP) module
    reg data_chktcp_vld_odd;
    reg data_chktcp_vld_first; // first data transmit (not for handshake)
    reg first_data;
    wire tcp_vld;
    assign tcp_vld = data_chktcp_vld_odd && data_chktcp_vld;

    always@(posedge clkTX_msg or posedge reset) begin
        if (reset) begin
            data_chktcp_vld_odd <= 1'b1;
        end else begin
            if (IDLE_TX_cdc) begin
                data_chktcp_vld_odd <= 1'b1;
            end else if (DELAY_TX_cdc) begin
                data_chktcp_vld_odd <= 1'b0;
            end else if(data_chktcp_vld_first) begin
                if (PRE_COMP_TX_cdc && index_chktcp == 14'd1) begin
                    data_chktcp_vld_odd <= !data_chktcp_vld_odd;
                end else if (!PRE_COMP_TX_cdc && (index_chktcp == 14'd0)) begin
                    data_chktcp_vld_odd <= 1'b1;
                end else begin
                    data_chktcp_vld_odd <= data_chktcp_vld_odd;
                end
            end else begin
                data_chktcp_vld_odd <= data_chktcp_vld_odd;
            end
        end
    end

    always@(posedge clk_PP or posedge reset) begin
        if (reset) begin
            first_data <= 1'b0;
        end else begin
            if (msg_stored) begin
                first_data <= 1'b1;
            end else begin
                first_data <= first_data;
            end
        end
    end

    always@(*) begin
        if (reset) begin
            data_chktcp_vld_first = 1'b0;
        end else begin
            if(first_data) begin
                if (index_chktcp == 14'd0) begin
                    data_chktcp_vld_first = 1'b1;
                end else begin
                    data_chktcp_vld_first = data_chktcp_vld_first;
                end
            end else begin
                data_chktcp_vld_first = data_chktcp_vld_first;
            end
        end
    end

    assign web = we_frame;
    assign addrb = index_frame;
    assign dinb = frame_data;
    assign clkb = clk_PP;
    assign clka = clk_PP;
    BRAM_wrapper UBRAMFrameTX
    (
        // -- interface to CRC32.v
        .BRAM_PORTA_addr(addra),
        .BRAM_PORTA_clk(clk_GMII),
        .BRAM_PORTA_din(dina),
        .BRAM_PORTA_dout(douta),
        .BRAM_PORTA_we(1'b0),

        // -- interface to frame data
        .BRAM_PORTB_addr(addrb),
        .BRAM_PORTB_clk(clk_PP),
        .BRAM_PORTB_din(dinb),
        .BRAM_PORTB_dout(doutb),
//        .BRAM_PORTB_en(1'b1),
        .BRAM_PORTB_we(web));

    reg [10:0]addr_cdc, addr_cdc_next;
    reg we_cdc, we_cdc_next;

    //    always @(posedge clk_PP or posedge reset) begin 
    //        if (reset) begin 
    //            addr_cdc <= 11'd0;
    //            we_cdc <= 1'b0;
    //        end else begin 
    //            addr_cdc <= addr_cdc_next;
    //            we_cdc <= we_cdc_next;
    //        end 
    //    end 

    //    always @* begin 
    //        addr_cdc_next = addr_cdc;
    //        if (network_fsm_TX == STORE_CDC_TX) begin 
    //            if (addr_cdc < frame_gmii_length + 11'd4 + 11'd10) begin 
    //                addr_cdc_next = addr_cdc + 1'b1;
    //            end else begin 
    //                addr_cdc_next = addr_cdc;
    //            end 
    //        end else begin 
    //            addr_cdc_next = 11'd0;
    //        end 
    //    end 

    //    always @* begin 
    //        we_cdc_next = we_cdc;
    //        if (network_fsm_TX == STORE_CDC_TX) begin 
    //            if ((addr_cdc < frame_gmii_length+2-1) &&
    //            (addr_cdc >= 11'd1)) begin 
    //                we_cdc_next =  1'b1;
    //            end else begin 
    //                we_cdc_next = 1'b0;
    //            end 
    //        end else begin 
    //            we_cdc_next = 1'd0;
    //        end 
    //    end 



    CDC_BRAM_wrapper Ucdc_bram // bram for clock domain crossing 
    (.BRAM_PORTA_addr(addrb),
        .BRAM_PORTA_clk(clk_PP),
        .BRAM_PORTA_din(dinb),
        .BRAM_PORTA_we(web),

        .BRAM_PORTB_addr(index_gmii[10:0]),
        .BRAM_PORTB_clk(clk_GMII),
        .BRAM_PORTB_dout(dout_cdc));

    reg [7:0] addra_next;
    reg [7:0] keep_crc32, keep_crc32_next;
    reg valid_in_crc32, valid_in_crc32_next;
    reg last_crc32, last_crc32_next;

    wire valid_out_crc32;
    wire [7:0] control_out_crc32;
    wire last_out_crc32;
    wire [31:0] crc32_out;
    wire crc32_valid;

    reg [7:0] addra_clkPP;
    reg [7:0] keep_crc32_clkPP;
    reg valid_in_crc32_clkPP;
    reg last_crc32_clkPP;

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            addra <= 8'd0;
            valid_in_crc32 <= 1'b0;
            last_crc32 <=1'b0;
            keep_crc32 <= 8'd0;
        end else begin
//            addra <= addra_clkPP;
//            valid_in_crc32 <= valid_in_crc32_clkPP;
//            last_crc32 <= last_crc32_clkPP;
//            keep_crc32 <= keep_crc32_clkPP;
            addra <= addra_next;
            valid_in_crc32 <= valid_in_crc32_next;
            last_crc32 <= last_crc32_next;
            keep_crc32 <= keep_crc32_next;            
        end
    end

//    always @(posedge clk_PP or posedge reset) begin
//        if (reset) begin
//            addra_clkPP <= 8'd0;
//            valid_in_crc32_clkPP <= 1'b0;
//            last_crc32_clkPP <=1'b0;
//            keep_crc32_clkPP <= 8'd0;
//        end else begin
//            addra_clkPP <= addra_next;
//            valid_in_crc32_clkPP <= valid_in_crc32_next;
//            last_crc32_clkPP <= last_crc32_next;
//            keep_crc32_clkPP <= keep_crc32_next;
//        end
//    end

    wire terminal_crc32; // equals to 1 as addra has not reached the terminal address
    assign terminal_crc32 = (addra < (frame_gmii_length[10:3] + |{frame_gmii_length[2:0]} + 1));
    always @* begin
        addra_next = addra;
        if (COMPUTE_CRC_TX_cdc) begin
            if (terminal_crc32) begin
                addra_next = addra + 8'd1;
            end else begin
                addra_next = addra;
            end
        end else begin
            addra_next = 8'd0;
        end
    end

    always @* begin
        valid_in_crc32_next = valid_in_crc32;
        if ((COMPUTE_CRC_TX_cdc) && (terminal_crc32) && (addra >= 2)) begin
            valid_in_crc32_next = 1'b1;
        end else begin
            valid_in_crc32_next = 1'b0;
        end
    end

    always @* begin
        keep_crc32_next = 8'd0;
        if ((COMPUTE_CRC_TX_cdc) && (terminal_crc32) && (addra >= 1)) begin
            if (|frame_gmii_length[2:0]) begin
                if (addra == 1) begin
                    keep_crc32_next = 8'hfe;
                end else if (addra == (frame_gmii_length[10:3] + 1)) begin
                    keep_crc32_next = (8'd1 << (frame_gmii_length[2:0])) - 8'd1;
                end else begin
                    keep_crc32_next = 8'hff;
                end
            end else begin
                if (addra == 1) begin
                    keep_crc32_next = 8'hfe;
                end else begin
                    keep_crc32_next = 8'hff;
                end
            end
        end
    end

    always @* begin
        last_crc32_next = last_crc32;
        if ((COMPUTE_CRC_TX_cdc)) begin
            if (|frame_gmii_length[2:0]) begin
                if (addra == frame_gmii_length[10:3]+1) begin
                    last_crc32_next = 1'b1;
                end else begin
                    last_crc32_next = 1'b0;
                end
            end else begin
                if (addra == frame_gmii_length[10:3]) begin
                    last_crc32_next = 1'b1;
                end else begin
                    last_crc32_next = 1'b0;
                end
            end
        end
    end

    wire COMPUTE_CRC_TX_state;
    assign COMPUTE_CRC_TX_state = (network_fsm_TX == COMPUTE_CRC_TX) ? 1 : 0;

    // CDC for COMPUTE_CRC_TX_state signal
    cdc_delay1 u_COMPUTE_CRC_TX_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src(COMPUTE_CRC_TX_state),
        .pulse_des(COMPUTE_CRC_TX_cdc)
    );


    reg [63:0] packet_in_crc32;
    //    reg [63:0] douta_in;
    //    always @* begin
    //        douta_in = 64'h 
    //    end 
    //    assign packet_in_crc32 = douta & {{8{keep_crc32[7]}}, {8{keep_crc32[6]}}, {8{keep_crc32[5]}}, {8{keep_crc32[4]}}, {8{keep_crc32[3]}}, 
    //    {8{keep_crc32[2]}}, {8{keep_crc32[1]}}, {8{keep_crc32[0]}}};
    always @* begin
        packet_in_crc32 = 64'h0707_0707_0707_0707;
        if (|{frame_gmii_length[2:0]}) begin
            if (addra >= 2 && (addra <= frame_gmii_length[10:3] + 2)) begin
                packet_in_crc32 = douta & {{8{keep_crc32[7]}}, {8{keep_crc32[6]}}, {8{keep_crc32[5]}}, {8{keep_crc32[4]}}, {8{keep_crc32[3]}},
                {8{keep_crc32[2]}}, {8{keep_crc32[1]}}, {8{keep_crc32[0]}}};
            end
        end else begin
            if (addra >= 2 && (addra <= frame_gmii_length[10:3] + 1)) begin
                packet_in_crc32 = douta & {{8{keep_crc32[7]}}, {8{keep_crc32[6]}}, {8{keep_crc32[5]}}, {8{keep_crc32[4]}}, {8{keep_crc32[3]}},
                {8{keep_crc32[2]}}, {8{keep_crc32[1]}}, {8{keep_crc32[0]}}};
            end
        end
    end

    reg [63:0] packet_in_crc32_delay;
    reg [7:0] keep_crc32_delay;
    reg valid_in_crc32_delay;
    reg last_crc32_delay;
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            packet_in_crc32_delay <= 64'd0;
            keep_crc32_delay <= 8'd0;
            valid_in_crc32_delay <= 1'b0;
            last_crc32_delay <= 1'b0;
        end else begin
            packet_in_crc32_delay <= packet_in_crc32 & 64'hffff_ffff_ffff_ffff;
            keep_crc32_delay <= keep_crc32 & 64'hff;
            valid_in_crc32_delay <= valid_in_crc32 & 1'b1;
            last_crc32_delay <= last_crc32 & 1'b1;
        end
    end

    CRC32 UCRC32(
        .tx_clk(clk_GMII),
        .tx_rstb(~reset),
        .packet_in(packet_in_crc32_delay),
        .keep(keep_crc32_delay),
        .valid_in(valid_in_crc32_delay),
        //input start,
        .last(last_crc32_delay),
        .valid_out(),
        .packet_out(),
        .control_out(),
        .last_out(),
        .crc32_out(crc32_out),
        .crc32_valid(crc32_valid)
    );

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            crc32_valid_delay <= 1'b0;
        end else begin
            crc32_valid_delay <= crc32_valid;
        end
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            crc32_out_trans <= 32'd0;
        end else begin
            crc32_out_trans <= crc32_out_trans_next;
        end
    end
    always @* begin
        crc32_out_trans_next = crc32_out_trans;
        if (crc32_valid_delay) begin
            crc32_out_trans_next = crc32_out;
        end
    end

    // Post Processing interface
    //------------------------------------
    //    input busy_PP2Net_TX,                   // BRAMMsgTX is used by PP
    //    output busy_Net2PP_TX,                  // BRAMMsgTX is used by NetworkCentCtrl
    //    input msg_stored,                       // msg is stored in BRAMMsgTX by PP 

    //    input [31:0] dataTX_msg,                // message from PP 
    //    output [10:0] addrTX_msg,               // addr for BRAMMsgTX
    //    input [10:0] sizeTX_msg,                // transmitting message size
    // --------------------------------------
    reg busy_Net2PP_TX_next;
    //    reg [10:0] addrTX_msg_next; 
    reg [15:0] base_addr_tmp, base_addr_tmp_next;
    reg [15:0] sizeTX_msg_buf, sizeTX_msg_buf_next;

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            //            addrTX_msg <= 11'd0;
            busy_Net2PP_TX <= 1'b0;
            sizeTX_msg_buf <= 16'd0;
//            base_addr_tmp <= 16'd0;
        end else begin
            //            addrTX_msg <= addrTX_msg_next;
            busy_Net2PP_TX <= busy_Net2PP_TX_next;
            sizeTX_msg_buf <= sizeTX_msg_buf_next;
//            base_addr_tmp <= base_addr_tmp_next;
        end
    end

        always @(posedge clk_GMII or posedge reset) begin 
            if (reset) begin 
                base_addr_tmp <= 16'd0;
            end else begin 
                base_addr_tmp <= base_addr_tmp_next;
            end  
        end 

    always @* begin
        busy_Net2PP_TX_next = busy_Net2PP_TX;
        if (~busy_Net2PP_TX) begin
            if (msg_stored && (network_fsm_TCP == TRANSFER_TCP)) begin // msg_store(msg_stored_clkPP)
                busy_Net2PP_TX_next = 1'b1;
            end else if (sizeTX_msg_buf == base_addr_tmp)  begin
                busy_Net2PP_TX_next = 1'b0;
            end
        end
        else if (sizeTX_msg_buf == base_addr_tmp) begin
            busy_Net2PP_TX_next = 1'b0;
        end
    end

    always @* begin
        sizeTX_msg_buf_next = sizeTX_msg_buf;
        if (msg_stored & ~busy_Net2PP_TX) begin // msg_store(msg_stored_clkPP)
            sizeTX_msg_buf_next = {5'd0, sizeTX_msg};
        end
    end
    //    ack_received_cdc_after

    always @* begin
        base_addr_tmp_next = base_addr_tmp;
        if (ack_received) begin //simulation can work but only last for one cycle delay
            base_addr_tmp_next = base_addr_tmp + 257;
        end
        if (network_fsm_TX == RESET_TX) begin
            base_addr_tmp_next = 16'd0;
        end
        if (~busy_Net2PP_TX) begin
            base_addr_tmp_next = 16'd0;
        end
    end

    assign addrTX_msg = index_chktcp[10:0] + base_addr_tmp;

    reg busy_TX2CentCtrl_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            busy_TX2CentCtrl <= 16'd0;
        end else begin
            busy_TX2CentCtrl <= busy_TX2CentCtrl_next;
        end
    end

    always @* begin
        busy_TX2CentCtrl_next = busy_TX2CentCtrl;
        if (~busy_TX2CentCtrl) begin
            if (msg_stored && (network_fsm_TCP == TRANSFER_TCP)) begin // msg_store(msg_stored_clkPP)
                busy_TX2CentCtrl_next = 1'b1;
            end
        end else begin
//            if (ack_received && (sizeTX_msg_buf == base_addr_tmp+257)) begin
            if (sizeTX_msg_buf == base_addr_tmp) begin
                busy_TX2CentCtrl_next = 1'b0;
            end
        end
    end
    //    always @* begin 
    //        addrTX_msg_next = addrTX_msg;
    //        if (busy_Net2PP_TX && (network_fsm_TX == PRE_COMP_TX)) begin 
    //            if (addrTX_msg < (base_addr_tmp+257)) begin
    //                addrTX_msg_next = addrTX_msg + 11'd1;
    //            end else begin 
    //                addrTX_msg_next = addrTX_msg;
    //            end 
    //        end 
    //    end 

    wire ack_received_cdc_after;

    clock_domain_crossing Ucdc_ack_received(
        .clk_src(clk_GMII),
        .clk_des(clkTX_msg),
        .reset(reset),
        .pulse_src(ack_received),
        .pulse_des(ack_received_cdc_after)
    );

    clock_domain_crossing Ucdc_ack_received_cdc_after(
        .clk_src(clkTX_msg),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(ack_received_cdc_after),
        .pulse_des(ack_received_ack)
    );

    assign BRAM_PORTA_clk = clk_PP;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            BRAM_PORTA_addr <= 5'd0;
        end else begin
            BRAM_PORTA_addr <= BRAM_PORTA_addr_next;
        end
    end
    always @* begin
        BRAM_PORTA_addr_next = BRAM_PORTA_addr;
        if (network_fsm_TX != LOAD_HEAD_TX) begin
            BRAM_PORTA_addr_next = BASE_ADDR_HEAD;
        end else begin
            if ((index_frame[1:0] == (LEN_SFD[1:0] - 2'd3)) && (index_frame > LEN_SFD)) begin
                BRAM_PORTA_addr_next = BRAM_PORTA_addr + 2'd1;
            end else begin
                BRAM_PORTA_addr_next = BRAM_PORTA_addr;
            end
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            head_bram <= 32'd0;
        end else begin
            head_bram <= BRAM_PORTA_dout;
        end
    end

    BRAM_FrameHead_wrapper UHeaderROM
    (.BRAM_PORTA_addr(BRAM_PORTA_addr),
        .BRAM_PORTA_clk(BRAM_PORTA_clk),
        .BRAM_PORTA_dout(BRAM_PORTA_dout));

endmodule
