//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 2023/10/24 15:12:08
//// Design Name: 
//// Module Name: test_packet_generator
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


module networkCentCtrl_B #(
    parameter lost_cycle = 28'b0111_1111_1111_1111_1111_1111_1111,
    parameter phy_reset_wait = 26'b11_1111_1111_1111_1111_1111_1111,
    parameter msg_stored_wait = 26'd1000,
    parameter lost_cycle_len = 28
)
(
    input            reset, // system reset
    input            clock_100M, // clock for JTAG module 
    output            clkTX_msg, // clock for accessing BRAMMsgTX
    output            clkRX_msg, // clock for accessing BRAMMsgRX
    input           clk_PP, // clock for processing frame data

    // Post Processing interface
    //------------------------------------
    input busy_PP2Net_TX, // BRAMMsgTX is used by PP
    output busy_Net2PP_TX, // BRAMMsgTX is used by NetworkCentCtrl
    input msg_stored, // msg is stored in BRAMMsgTX by PP 

    input busy_PP2Net_RX, // BRAMMsgRX is used by PP
    output busy_Net2PP_RX, // BRAMMsgRX is used by networkCentCtrl
    output msg_accessed, // msg is stored in BRAMMsgTX by networkCentCtrl

    input [31:0] dataTX_msg, // message from PP 
    output [10:0] addrTX_msg, // addr for BRAMMsgTX
    input [10:0] sizeTX_msg, // transmitting message size

    output [31:0] dataRX_msg, // message pasrsed from Ethernet frame
    output weRX_msg, // write enable for BRAMMsgRX
    output [10:0] addrRX_msg, // addr for BRAMMSGRX
    output [10:0] sizeRX_msg, // receoved message size

    // GMII Interface (client MAC <=> PCS)
    //------------------------------------
    input            gmii_tx_clk, // Transmit clock from client MAC.
    input            gmii_rx_clk, // Receive clock to client MAC.
    input            link_status, // Link status: use status_vector[0]
    output [7:0]      gmii_txd, // Transmit data from client MAC.
    output             gmii_tx_en, // Transmit control signal from client MAC.
    output             gmii_tx_er, // Transmit control signal from client MAC.
    input [7:0]     gmii_rxd, // Received Data to client MAC.
    input           gmii_rx_dv, // Received control signal to client MAC.
    input           gmii_rx_er // Received control signal to client MAC.

    // test signal 
    ,
    (*mark_debug = "TRUE"*) output [3:0] network_fsm_TCP,
    (*mark_debug = "TRUE"*) output [2:0] transfer_fsm,
    output [2:0] network_fsm_TX,
    output [2:0] network_fsm_RX,
    output start_handle_FrameSniffer,
    output received_valid,
    output need_ack,
    output is_handshake,
    output transfer_finish,
    output transfer_en,
    output busy_TX2CentCtrl,
    output [10:0] index_frame_FrameGenerator,
    output [7:0] frame_data_FrameGenerator,
    output [15:0] total_len_TCP_FrameGenerator,
    output [63:0] douta_FrameGenerator,
    output [7:0] keep_crc32_FrameGenerator,
    output crc32_valid_FrameGenerator,
    output ack_received,

    output [15:0] sizeTX_msg_buf_FrameGenerator,
    output [15:0] base_addr_tmp_FrameGenerator,
    output ack_received_cdc_after_FrameGenerator,
    output [10:0] addr_gmii_FrameSniffer,
    output [15:0] tcp_segment_len_FrameSniffer,
    output [63:0] packet_in_crc32_FrameSniffer,
    output [7:0] keep_crc32_FrameSniffer,
    output [31:0] crc32_out_FrameSniffer,
    output [31:0] seq_RX,
    output [31:0] ack_RX,
    output [lost_cycle_len-1:0] lost,
    output [31:0] FCS_received_FrameSniffer,
    output packet_valid_FrameSniffer,
    output [19:0] tcp_chksum_FrameSniffer,
    output [19:0] network_chksum_FrameSniffer,
    output msg_accessed_en_FrameSniffer
);
    `include "networkCentCtrlParam_B.vh"

    // FSM & control singal
    reg [3:0] network_fsm_TCP, network_fsm_TCP_next;
    wire transfer_finish;
    (*mark_debug = "TRUE"*) wire received_valid;
    wire need_ack;
    wire is_handshake;
    wire busy_TX2CentCtrl;
//    reg ack_received;
    (*mark_debug = "TRUE"*) wire ack_received;
    wire ack_received_ack;
    wire ack_received_next;
    wire busy_network_TX;
    wire busy_network_RX;

//    always @(posedge clk_PP or posedge reset) begin
//        if (reset) begin
//            ack_received <= 1'b0;
//        end else begin
//            ack_received <= ack_received_next;
//        end
//    end

    clock_domain_crossing u_ack_received_cdc(
        .clk_src(clk_PP),
        .clk_des(gmii_tx_clk),
        .reset(reset),
        .pulse_src(ack_received_next),
        .pulse_des(ack_received));
        
//    assign ack_received_next = received_valid && (network_fsm_TCP == TRANSFER_TCP);
    assign ack_received_next = received_valid;

    // data exchanging between RX and TX 
    wire [31:0] seq_RX;
    wire [31:0] ack_RX;

    // link_status 
    reg link_en, link_en_next;
    reg [25:0] link_cnt, link_cnt_next;
    always @(posedge gmii_rx_clk or posedge reset) begin
        if (reset) begin
            link_cnt <= 26'd0;
            link_en <= 1'b0;
        end else begin
            link_cnt <= link_cnt_next;
            link_en <= link_en_next;
        end
    end
    always @* begin
        link_cnt_next = link_cnt;
        if (link_status) begin
            if (link_cnt < phy_reset_wait) begin
                link_cnt_next = link_cnt + 1;
            end else begin
                link_cnt_next = link_cnt;
            end
        end else begin
            link_cnt_next = 0;
        end
    end
    always @* begin
        link_en_next = link_en;
        if (link_cnt == phy_reset_wait) begin
            link_en_next = 1'b1;
        end else begin
            link_en_next = 1'b0;
        end
    end
    // CDC interface for link en
    wire link_en_cdc;
    cdc_delay1 u_link_en_cdc(
        .clk_src(gmii_rx_clk),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(link_en),
        .pulse_des(link_en_cdc)
    );

    // msg_stored
    reg msg_stored_en, msg_stored_en_next;
    reg [25:0] msg_stored_cnt, msg_stored_cnt_next;
    always @(posedge gmii_tx_clk or posedge reset) begin
        if (reset) begin
            msg_stored_cnt <= 26'd0;
            msg_stored_en <= 1'b0;
        end else begin
            msg_stored_cnt <= msg_stored_cnt_next;
            msg_stored_en <= msg_stored_en_next;
        end
    end
    always @* begin
        msg_stored_cnt_next = msg_stored_cnt;
        if (msg_stored) begin
            if (msg_stored_cnt < msg_stored_wait) begin
                msg_stored_cnt_next = msg_stored_cnt + 1;
            end else begin
                msg_stored_cnt_next = msg_stored_cnt;
            end
        end else begin
            msg_stored_cnt_next = 0;
        end
    end
    always @* begin
        msg_stored_en_next = msg_stored_en;
        if (msg_stored_cnt == msg_stored_wait) begin
            msg_stored_en_next = 1'b1;
        end else begin
            msg_stored_en_next = 1'b0;
        end
    end

    // CDC interface for msg_stored_en (gmii_tx_clk to clkTX)
    wire msg_stored_en_clkPP;
    clock_domain_crossing u_msg_stored_en_clkPP(
        .clk_src(gmii_tx_clk),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(msg_stored_en),
        .pulse_des(msg_stored_en_clkPP)
    );

    // TCP controller 
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            network_fsm_TCP <= DISCONNECT_TCP;
        end else begin
            network_fsm_TCP <= network_fsm_TCP_next;
        end
    end



    always @* begin
        network_fsm_TCP_next = network_fsm_TCP;
        case(network_fsm_TCP)
            DISCONNECT_TCP: begin
                if (link_en_cdc) begin
                    if (ALICE_B == 1'b0) begin // Need modify
                        network_fsm_TCP_next = HANDSHAKE0_TCP;
                    end else begin
                        if (received_valid && is_handshake) begin
                            network_fsm_TCP_next = HANDSHAKE_TCP;
                        end
                    end
                end
            end
            HANDSHAKE_TCP: begin
                if (lost == lost_cycle) begin
                    //                    network_fsm_TCP_next = DISCONNECT_TCP;
                end else begin
                    if (received_valid && ~is_handshake) begin // Need modify
                        network_fsm_TCP_next = TRANSFER_TCP;
                    end
                end
            end

            HANDSHAKE0_TCP: begin
                if (received_valid && is_handshake) begin
                    network_fsm_TCP_next = HANDSHAKE1_TCP;
                end
            end
            HANDSHAKE1_TCP: begin
                //                if (received_valid) begin 
                //                    network_fsm_TCP_next = TRANSFER_TCP;
                //                end 
                if ((~busy_network_TX) && (transfer_fsm == WAITTX_TRANS)) begin
                    network_fsm_TCP_next = TRANSFER_TCP;
                end
            end

            TRANSFER_TCP: begin // If receiving a packet or transfer out a packet, go to ACK state.
            // Prepared reveiving or transfer out an ACK packet
            //                if (received_valid) begin 
            //                    network_fsm_TCP_next = ACK_T_TCP;
            //                end
                if (received_valid) begin
                    if (is_handshake) begin
                        network_fsm_TCP_next = (ALICE_B == 1)? HANDSHAKE_TCP: HANDSHAKE1_TCP;
                    end else begin
                        if (need_ack) begin // Need modify
                            network_fsm_TCP_next = ACK_T_TCP;
                        end
                    end
                end
                //                    if (transfer_finish) begin 
                //                        network_fsm_TCP_next = ACK_R_TCP;
                //                    end 


            end
            //            ACK_R_TCP: begin // Prepared receiving ACK packet
            //                if (link_status) begin 
            //                    if (received_valid | (lost == lost_cycle)) begin  // Need modify 
            //                        network_fsm_TCP_next = TRANSFER_TCP;
            //                    end 
            //                end else begin 
            //                    network_fsm_TCP_next = DISCONNECT_TCP;
            //                end 
            //            end 
            ACK_T_TCP: begin // Transfer out an ACK packet                   
                if ((~busy_network_TX) && (transfer_fsm == WAITTX_TRANS)) begin
                    network_fsm_TCP_next = TRANSFER_TCP;
                end
            end
        endcase

    end

    // FSM of transfer state
    reg [2:0] transfer_fsm, transfer_fsm_next;
    parameter [2:0] IDLE_TRANS = 3'b000;
    parameter [2:0] TRANS_TRANS = 3'b001;
    parameter [2:0] WAITTX_TRANS = 3'b011;
    parameter [2:0] WAITRX_TRANS = 3'b010;
    parameter [2:0] WAITNEXT_TRANS = 3'b110;
    parameter [2:0] WAITTX_ACKCHK_TRANS = 3'b111;
    parameter [2:0] WAITRX_LAST_TRANS = 3'b101;
    parameter [2:0] WAITTX_ACK_TRANS = 3'b100;

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            transfer_fsm <= IDLE_TRANS;
        end else begin
            transfer_fsm <= transfer_fsm_next;
        end
    end


    always @* begin
        transfer_fsm_next = transfer_fsm;
        if (network_fsm_TCP != DISCONNECT_TCP) begin
            case (transfer_fsm)
                IDLE_TRANS: begin
                    if (~busy_network_TX) begin
                        case (network_fsm_TCP)
                            HANDSHAKE0_TCP, HANDSHAKE1_TCP, HANDSHAKE_TCP, ACK_T_TCP: transfer_fsm_next = TRANS_TRANS;
                            TRANSFER_TCP: transfer_fsm_next = (busy_TX2CentCtrl)? TRANS_TRANS: IDLE_TRANS;
                            default: transfer_fsm_next = transfer_fsm;
                        endcase
                    end else begin
                        transfer_fsm_next = transfer_fsm;
                    end
                end
                TRANS_TRANS: begin
                    if ((network_fsm_TCP == TRANSFER_TCP && busy_TX2CentCtrl) || network_fsm_TCP != TRANSFER_TCP) begin
                        if (busy_network_TX) begin
                            transfer_fsm_next = WAITTX_TRANS;
                        end else begin
                            transfer_fsm_next = transfer_fsm;
                        end
                    end else begin
                        transfer_fsm_next = IDLE_TRANS;
                    end
                end
                WAITTX_TRANS: begin
                    if (~busy_network_TX) begin
                        case(network_fsm_TCP)
                            HANDSHAKE0_TCP, TRANSFER_TCP, HANDSHAKE_TCP: transfer_fsm_next = WAITRX_TRANS;
                            //                            HANDSHAKE_TCP: transfer_fsm_next = WAITNEXT_TRANS;
                            ACK_T_TCP, HANDSHAKE1_TCP: transfer_fsm_next = IDLE_TRANS;
                            default: transfer_fsm_next = transfer_fsm;
                        endcase
                    end else begin
                        transfer_fsm_next = transfer_fsm;
                    end
                end
                WAITNEXT_TRANS: begin
                    if (received_valid) begin
                        transfer_fsm_next = IDLE_TRANS;
                    end else begin
                        transfer_fsm_next = transfer_fsm;
                    end
                end
                WAITRX_TRANS: begin
                    if (busy_network_RX) begin
                        transfer_fsm_next = WAITTX_ACKCHK_TRANS;
                    end else begin
                        if (lost >= lost_cycle) begin
                            transfer_fsm_next = TRANS_TRANS;
                        end else begin
                            transfer_fsm_next = transfer_fsm;
                        end
                    end
                end
                WAITTX_ACKCHK_TRANS: begin
                    if (received_valid) begin
                        if (is_handshake) begin
                            transfer_fsm_next = WAITRX_LAST_TRANS;
                        end else if (need_ack) begin
                            transfer_fsm_next = WAITRX_LAST_TRANS;
                        end else begin
                            transfer_fsm_next = (busy_TX2CentCtrl)? WAITTX_ACK_TRANS: WAITRX_LAST_TRANS;
                        end
                    end else begin
                        if (~busy_network_RX) begin
                            transfer_fsm_next = IDLE_TRANS;
                        end
                    end
                end
                WAITTX_ACK_TRANS: begin
                    if (ack_received_ack) begin
                        transfer_fsm_next = WAITRX_LAST_TRANS;
                    end
                end
                WAITRX_LAST_TRANS: begin
                    if (~busy_network_RX) begin
                        transfer_fsm_next = IDLE_TRANS;
                    end else begin
                        transfer_fsm_next = transfer_fsm;
                    end
                end
            endcase
        end else begin
            transfer_fsm_next = IDLE_TRANS;
        end
    end


    (*mark_debug = "TRUE"*) reg transfer_en;
    (*mark_debug = "TRUE"*) wire transfer_en_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            transfer_en <= 1'b0;
        end else begin
            transfer_en <= transfer_en_next;
        end
    end
    assign transfer_en_next = (transfer_fsm==TRANS_TRANS);
    wire block_TX, block_RX;

    assign block_TX = ((transfer_fsm == WAITRX_TRANS) || (transfer_fsm == WAITRX_LAST_TRANS) || (transfer_fsm == WAITNEXT_TRANS) || (transfer_fsm == IDLE_TRANS));
    assign block_RX = ((transfer_fsm == TRANS_TRANS) || (transfer_fsm == WAITTX_TRANS));
    //    assign transfer_en_next = 1'b1;
    //    always @* begin 
    //        transfer_en_next = transfer_en;
    //        if (~transfer_en) begin
    //            if (network_fsm_TCP != network_fsm_TCP_next) begin 
    //                if ((network_fsm_TCP == DISCONNECT_TCP) ||
    //                   (network_fsm_TCP == HANDSHAKE0_TCP) ||
    //                   (network_fsm_TCP == TRANSFER_TCP && ALICE==1)) begin 
    //                   transfer_en_next = 1'b1;
    //                end
    //            end else begin 
    ////                if ((network_fsm_TCP == HANDSHAKE0_TCP) || (network_fsm_TCP == TRANSFER_TCP && busy_network_TX)) begin 
    ////                    if (lost == lost_cycle) begin 
    ////                        transfer_en_next = 1'b1;
    ////                    end 
    ////                end 
    //            end 
    //        end else begin
    //            if (busy_network_TX) begin 
    //                transfer_en_next = 1'b0;
    //            end 
    //        end


    //        if (((transfer_finish == 0) && (network_fsm_TCP != network_fsm_TCP_next) && 
    //        (network_fsm_TCP_next != WAIT_TCP) && (network_fsm_TCP != ACK_R_TCP)) 
    //        || (lost == lost_cycle)) begin 
    //            transfer_en_next = 1'b1;
    //        end 
    //        if (transfer_finish) begin 
    //            transfer_en_next = 1'b0;
    //        end 
    //    end 

    reg [lost_cycle_len-1:0] lost, lost_next;
    //    reg lost_cnt_en, lost_cnt_en_next;

    //    always @(posedge clk_PP or posedge reset) begin
    //        if (reset) begin 
    //            lost_cnt_en <= 1'b0;
    //        end else begin 
    //            lost_cnt_en <= lost_cnt_en_next;
    //        end  
    //    end 

    wire [(lost_cycle_len-1):0] lost_delay;
    always @(posedge gmii_rx_clk or posedge reset) begin
        if (reset) begin
            lost <= {lost_cycle_len{1'b0}};
        end else begin
            //            lost <= lost_next;
            lost <= lost_delay;
        end
    end

    // cdc for lost signal
    cdc_delay1 #(.DATA_BITS(lost_cycle_len)) u_lost_cdc(
        .clk_src(clk_PP),
        .clk_des(gmii_rx_clk),
        .reset(reset),
        .pulse_src(lost_next),
        .pulse_des(lost_delay)
    );

    //    always @* begin 
    //        lost_cnt_en_next = lost_cnt_en;
    //        if (~lost_cnt_en) begin
    //            if ((transfer_finish) &&
    //            ((network_fsm_TCP == HANDSHAKE0_TCP) || ((network_fsm_TCP == TRANSFER_TCP) && (busy_Net2PP_TX)))) begin 
    //                lost_cnt_en_next = 1'b1;
    //            end
    //        end else begin 
    //            if (received_valid || busy_network_TX || busy_network_RX || transfer_en || ((network_fsm_TCP == TRANSFER_TCP) && (~busy_Net2PP_TX))) begin 
    //                lost_cnt_en_next = 1'b0;
    //            end 
    //        end
    //    end 

    always @* begin
        lost_next = lost;
        if (transfer_fsm == WAITRX_TRANS) begin
            if (lost < lost_cycle) begin
                lost_next = lost + 1;
            end else begin
                lost_next = lost;
            end
        end else begin
            lost_next = {lost_cycle_len{1'b0}};
        end
    end

    FrameGenerator_B UframeGen
    (
        .clk_PP(clk_PP),
        .clk_GMII(gmii_tx_clk),
        .clkTX_msg(clkTX_msg),
        .reset(reset),

        // Post Processing interface
        //------------------------------------
        .busy_PP2Net_TX(busy_PP2Net_TX), // BRAMMsgTX is used by PP
        .busy_Net2PP_TX(busy_Net2PP_TX), // BRAMMsgTX is used by NetworkCentCtrl
        .msg_stored(msg_stored_en_clkPP), // msg is stored in BRAMMsgTX by PP 


        .dataTX_msg(dataTX_msg), // message from PP 
        .addrTX_msg(addrTX_msg), // addr for BRAMMsgTX
        .sizeTX_msg(sizeTX_msg), // transmitting message size

        // control signals from networkCentCtrl 
        .network_fsm_TCP(network_fsm_TCP),
        .ack_received(ack_received),
        .ack_received_ack(ack_received_ack),
        .received_valid(received_valid),
        .transfer_en(transfer_en),
        .transfer_complete(transfer_finish),
        .busy(busy_network_TX),
        .block_TX(block_TX),
        .busy_TX2CentCtrl(busy_TX2CentCtrl),
        // data signal from RX path 
        .seq_RX(seq_RX),
        .ack_RX(ack_RX),


        // GMII Interface (client MAC <=> PCS)
        //------------------------------------
        .link_status(1'b1), // Link status: use status_vector[0]
        .gmii_txd(gmii_txd), // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en), // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er) // Transmit control signal from client MAC.


        // test signal 
        ,
        .network_fsm_TX(network_fsm_TX),
        .index_frame(index_frame_FrameGenerator),
        .frame_data(frame_data_FrameGenerator),
        .sizeTX_msg_buf(sizeTX_msg_buf_FrameGenerator),
        .base_addr_tmp(base_addr_tmp_FrameGenerator),
        .total_len_TCP(total_len_TCP_FrameGenerator),
        .packet_in_crc32_delay(douta_FrameGenerator),
        .keep_crc32_delay(keep_crc32_FrameGenerator),
        .crc32_valid(crc32_valid_FrameGenerator),
        .ack_received_cdc_after(ack_received_cdc_after_FrameGenerator)
    );
    //    assign received_valid = 1'b0;
    FrameSniffer_B UframeSniffer(
        .clk_PP(clk_PP),
        .clk_GMII(gmii_rx_clk),
        .reset(reset),
        .clkRX_msg(clkRX_msg),
        // Post Processing interface
        //------------------------------------    
        .busy_PP2Net_RX(busy_PP2Net_RX), // BRAMMsgRX is used by PP
        .busy_Net2PP_RX(busy_Net2PP_RX), // BRAMMsgRX is used by networkCentCtrl
        .msg_accessed(msg_accessed), // msg is stored in BRAMMsgTX by networkCentCtrl


        .dataRX_msg(dataRX_msg), // message pasrsed from Ethernet frame
        .weRX_msg(weRX_msg), // write enable for BRAMMsgRX
        .addrRX_msg(addrRX_msg), // addr for BRAMMSGRX
        .sizeRX_msg(sizeRX_msg), // receoved message size

        // control signals to networkCentCtrl 
        .network_fsm_TCP(network_fsm_TCP),
        .received_valid(received_valid),
        .is_handshake(is_handshake),
        .need_ack(need_ack), // if it is raising to 1, the other side needs an ack packet. (network_fsm_TCP == TRANSFER_TCP)
        .busy(busy_network_RX),
        .block_RX(block_RX),
        
//        .last_signal_specifier(last_signal_specifier),
        .busy_TX2CentCtrl(busy_TX2CentCtrl),

        // data signal from RX path 
        .seq_RX(seq_RX),
        .ack_RX(ack_RX),

        // GMII Interface (client MAC <=> PCS)
        //------------------------------------
        .link_status(1'b1), // Link status: use status_vector[0]
        .gmii_rxd(gmii_rxd), // Received Data to client MAC.d
        .gmii_rx_dv(gmii_rx_dv), // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er) // Received control signal to client MAC.

        // Test Signal 
        ,
        .network_fsm_RX(network_fsm_RX),
        .start_handle(start_handle_FrameSniffer),
        .packet_in_crc32(packet_in_crc32_FrameSniffer),
        .keep_crc32(keep_crc32_FrameSniffer),
        .crc32_out_trans(crc32_out_FrameSniffer),
        .tcp_chksum(tcp_chksum_FrameSniffer),
        .network_chksum(network_chksum_FrameSniffer),
        .addr_gmii(addr_gmii_FrameSniffer),
        .tcp_segment_len(tcp_segment_len_FrameSniffer),
        .FCS_received(FCS_received_FrameSniffer),
        .packet_valid(packet_valid_FrameSniffer),
        .msg_accessed_en(msg_accessed_en_FrameSniffer)
    );





endmodule
