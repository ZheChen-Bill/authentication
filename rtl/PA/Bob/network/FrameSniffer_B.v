module FrameSniffer_B(
    input clk_PP,
    input clk_GMII,
    input reset,
    output clkRX_msg,

    // Post Processing interface
    //------------------------------------    
    input busy_PP2Net_RX, // BRAMMsgRX is used by PP
    output reg busy_Net2PP_RX, // BRAMMsgRX is used by networkCentCtrl
    output reg msg_accessed, // msg is stored in BRAMMsgTX by networkCentCtrl


    output reg [31:0] dataRX_msg, // message pasrsed from Ethernet frame
    output reg weRX_msg, // write enable for BRAMMsgRX
    output reg [10:0] addrRX_msg, // addr for BRAMMSGRX
    output reg [10:0] sizeRX_msg, // receoved message size

    // control signals to networkCentCtrl 
    input [3:0] network_fsm_TCP,
    output reg received_valid,
    output reg is_handshake,
    output reg need_ack, // if it is raising to 1, the other side needs an ack packet. (network_fsm_TCP == TRANSFER_TCP)
    output busy,
    input block_RX,
    
    input busy_TX2CentCtrl,
    // data to networkCentCtrl 
    output reg [31:0] seq_RX,
    output reg [31:0] ack_RX,

    // GMII Interface (client MAC <=> PCS)
    //------------------------------------
    input            link_status, // Link status: use status_vector[0]
    input [7:0]     gmii_rxd, // Received Data to client MAC.d
    input           gmii_rx_dv, // Received control signal to client MAC.
    input           gmii_rx_er // Received control signal to client MAC.

    // Test Signal 
    ,
    output [2:0] network_fsm_RX,
    output start_handle,
    output [10:0] addr_gmii, //
    output received_complete,
    output [47:0] buffer,
    output [19:0] tcp_chksum,
    output [19:0] network_chksum,
    output [15:0] tcp_segment_len, // 
    output [31:0] crc32_out_trans,
    output crc32_valid_delay,
    output [63:0] packet_in_crc32,
    output [7:0] addr_crc32,
    output [7:0] keep_crc32,
    output valid_in_crc32,
    output last_crc32,
    output [31:0] FCS_received,
    output packet_valid,

    output [10:0] addr_cdc,
    output [7:0] dout_cdc,
    output [31:0] cdc_buf,
    output [10:0] base_addr_temp,
    output msg_accessed_en
);
    `include "networkCentCtrlParam_B.vh"
//    wire clk_PP;
//    assign clk_PP = clk_GMII; 
    reg [1:0] cnt_clkRX_msg, cnt_clkRX_msg_next;
    reg [10:0] addr_gmii, addr_gmii_next;
    reg start_handle, start_handle_next;

    (*mark_debug = "TRUE"*) reg [3:0] network_fsm_RX, network_fsm_RX_next;
    reg received_valid_next;

    reg packet_valid, packet_valid_next;
    reg [15:0] tcp_segment_len, tcp_segment_len_next;

    reg [31:0] FCS_received, FCS_received_next;
    reg [31:0] seq_RX_next;
    reg [31:0] ack_RX_next;

    reg [39:0] buffer_ini, buffer_ini_next;
    reg [31:0] crc32_out_trans, crc32_out_trans_next;
    reg crc32_valid_delay, crc32_valid_delay_delay,crc32_valid_delay_delay_delay;
    reg crc32_valid_reg;
    
    reg [10:0] addr_gmii_delay;
    reg [10:0] addrRX_msg;

    wire block_RX_cdc;
    wire IDLE_RX_cdc;
    wire HANDLE_RX_cdc;
    wire COMPUTE_CRC_RX_cdc;
    wire weRX_msg_cdc;

    wire IDLE_RX_state;
    assign IDLE_RX_state = (network_fsm_RX == IDLE_RX) ? 1 : 0;
    
    // CDC for IDLE_RX_state signal
    cdc_delay1 u_IDLE_RX_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src(IDLE_RX_state),
        .pulse_des(IDLE_RX_cdc)
    );
    
    wire gmii_rx_dv_cdc;
    
    // CDC for gmii_rx_dv signal
    cdc_delay1 u_gmii_rx_dv_cdc(
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(gmii_rx_dv),
        .pulse_des(gmii_rx_dv_cdc)
    );
    
    //    assign received_valid = packet_valid && (FCS_received[31:24] == crc32_out[7:0])
    //                                        && (FCS_received[23:16] == crc32_out[15:8])
    //                                        && (FCS_received[15:8] == crc32_out[23:16])
    //                                        && (FCS_received[7:0] == crc32_out[31:24]);

    // Busy signal 
    assign busy = (network_fsm_RX != IDLE_RX);

    always @(posedge clk_PP or posedge reset) begin
//    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            network_fsm_RX <= IDLE_RX;
        end else begin
            network_fsm_RX <= network_fsm_RX_next;
        end
    end

    always @* begin
        network_fsm_RX_next = network_fsm_RX;
        case(network_fsm_RX)
            IDLE_RX: begin
                if ((busy_TX2CentCtrl) && (gmii_rx_dv_cdc)) begin
                     network_fsm_RX_next = WAIT_ACK_RX;
                end
//                if (gmii_rx_dv && ({buffer_ini[31:0], gmii_rxd} == 40'h55_5555_55d5) && (~block_RX)) begin                
//                else if (gmii_rx_dv && ({buffer_ini[39:8], gmii_rxd} == 40'h55_5555_55d5)) begin
                else if (gmii_rx_dv_cdc && ({buffer_ini_clkPP[39:8]} == 32'h5555_5555) && (gmii_rxd_clkPP == 8'hd5)) begin
                    network_fsm_RX_next = HANDLE_RX;
                end else begin
                    network_fsm_RX_next = IDLE_RX;
                end
            end
            HANDLE_RX:begin
                if (received_complete_cdc) begin
                    network_fsm_RX_next = COMPUTE_CRC_RX;
                end else begin
                    if (~start_handle_clkPP && (gmii_rxd_clkPP != 8'hd5)) begin
                        network_fsm_RX_next = IDLE_RX;
                    end else begin
                        network_fsm_RX_next = HANDLE_RX;
                    end
                end
            end
            COMPUTE_CRC_RX:begin
                if (crc32_valid_delay_delay_delay) begin
                    if ((packet_valid) &&
                    (FCS_received[31:24] == crc32_out_trans[7:0])
                    && (FCS_received[23:16] == crc32_out_trans[15:8])
                    && (FCS_received[15:8] == crc32_out_trans[23:16])
                    && (FCS_received[7:0] == crc32_out_trans[31:24])) begin
                        network_fsm_RX_next = WAIT_RX;
                    end else begin
                        network_fsm_RX_next = IDLE_RX;
                    end
                end else begin
                    network_fsm_RX_next = COMPUTE_CRC_RX;
                end
            end
            
            WAIT_RX: begin
                if (received_valid) begin
                    network_fsm_RX_next = IDLE_RX;
                end else begin
                    network_fsm_RX_next = WAIT_RX;
                end 
            end
            
            WAIT_ACK_RX: begin
                if (~gmii_rx_dv_cdc) begin
                    network_fsm_RX_next = TRANSITION_STATE1_RX;
                end else begin
                    network_fsm_RX_next = WAIT_ACK_RX;
                end 
            end
            
            TRANSITION_STATE1_RX: begin
                network_fsm_RX_next = TRANSITION_STATE2_RX;
            end
            
            TRANSITION_STATE2_RX: begin
                network_fsm_RX_next = TRANSITION_STATE3_RX;
            end
            
            TRANSITION_STATE3_RX: begin
                network_fsm_RX_next = TRANSITION_STATE4_RX;
            end
            
            TRANSITION_STATE4_RX: begin
                if (received_valid) begin
                    network_fsm_RX_next = IDLE_RX;
                end else begin
                    network_fsm_RX_next = TRANSITION_STATE4_RX;
                end 
            end
            
        endcase
    end

  
    wire received_complete;
    wire received_complete_cdc;
    assign received_complete = ((addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD+4)) | (addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD+4+1)));
    // CDC for received_complete signal
    cdc_delay1 u_received_complete_cdc(
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(received_complete),
        .pulse_des(received_complete_cdc)
    );

    reg need_ack_next;
    reg is_handshake_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            received_valid <= 1'b0;
            need_ack <= 1'b0;
            is_handshake <= 1'b0;
        end else begin
            received_valid <= received_valid_next;
            need_ack <= need_ack_next;
            is_handshake <= is_handshake_next;
        end
    end

    always @* begin
        received_valid_next = received_valid;
        if (~received_valid) begin
            if ((network_fsm_RX == WAIT_RX)) begin
                if ((network_fsm_TCP != TRANSFER_TCP)) begin
                    received_valid_next = 1'b1;
                end else begin
//                    if (tcp_segment_len > 50) begin
                    if (tcp_segment_len_received_valid) begin
                        if ((addr_cdc == (tcp_segment_len[10:0] - 11'd20 + 11'd2 + 11'd4 + 11'd4 +11'd54 - 11'd1))) begin
                            received_valid_next = 1'b1;
                        end else begin
                            received_valid_next = 1'b0;
                        end
                    end else begin
                        received_valid_next = 1'b1;
                    end
                end
            end else if (network_fsm_RX == TRANSITION_STATE4_RX) begin
                received_valid_next = 1'b1;
            end else begin
                received_valid_next = 1'b0;
            end
        end else begin
            received_valid_next = 1'b0;
        end
    end
    wire tcp_segment_len_received_valid;
     // CDC for IDLE_RX_state signal
    cdc_delay1 u_tcp_segment_len_received_valid_cdc(
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(tcp_segment_len > 50),
        .pulse_des(tcp_segment_len_received_valid)
    );
    
    always @* begin
        need_ack_next= need_ack;
        if (network_fsm_RX == WAIT_RX) begin
            if ((network_fsm_TCP == TRANSFER_TCP)) begin
//                if (tcp_segment_len[10:0] > 11'd50) begin
                if (tcp_segment_len_need_ack) begin
                    need_ack_next = 1'b1;
                end
            end
        end else begin
            need_ack_next = 1'b0;
        end
    end
    
   wire tcp_segment_len_need_ack;
     // CDC for IDLE_RX_state signal
    cdc_delay1 u_tcp_segment_len_need_ack_cdc(
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(tcp_segment_len[10:0] > 11'd50),
        .pulse_des(tcp_segment_len_need_ack)
    );
    
    always @* begin
        is_handshake_next = is_handshake;
        if (network_fsm_RX == WAIT_RX) begin
//            if (tcp_segment_len == 32) begin
            if (tcp_segment_len_is_handshake) begin
                is_handshake_next = 1'b1;
            end
        end else begin
            is_handshake_next = 1'b0;
        end
    end

   wire tcp_segment_len_is_handshake;
     // CDC for IDLE_RX_state signal
    cdc_delay1 u_tcp_segment_len_is_handshake_cdc(
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(tcp_segment_len == 32),
        .pulse_des(tcp_segment_len_is_handshake)
    );

    wire FULL, EMPTY;
    wire [7:0] gmii_rxd_clkPP;
    asynchronous_fifo # (.DWIDTH(8)) u_buffer (
        .arst_n(~reset),
        .wclk(clk_GMII),   
        .wdv(gmii_rx_dv),    
        .wdata(gmii_rxd),  
        .wfull(FULL),  

        .rclk(clk_PP),   
        .rrq(gmii_rx_dv_cdc),    
        .rdata(gmii_rxd_clkPP),  
        .rempty(EMPTY), 
        .rdv()
    );
   always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            start_handle <= 1'b0;
        end else begin
            start_handle <= start_handle_next;
        end
    end

    //     && ((network_fsm_RX == IDLE_RX) || (network_fsm_RX == HANDLE_RX))
    always @* begin
        start_handle_next = start_handle;
//        if ((~block_RX_cdc) && gmii_rx_dv && ({buffer_ini[31:0], gmii_rxd} == 40'h55_5555_55d5)) begin
//        if (gmii_rx_dv && ({buffer_ini[31:0], gmii_rxd} == 40'h55_5555_55d5)||({buffer_ini[39:8], gmii_rxd} == 40'h55_5555_55d5)) begin
        if (gmii_rx_dv && ({buffer_ini[31:0], gmii_rxd} == 40'h55_5555_55d5)) begin
            start_handle_next = 1'b1;
        end
        if (~gmii_rx_dv) begin
            start_handle_next = 1'b0;
        end
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            buffer_ini <= 40'd0;
        end else begin
            buffer_ini <= buffer_ini_next;
        end
    end

    always @* begin
        buffer_ini_next = buffer_ini;
        if (gmii_rx_dv) begin
            buffer_ini_next = {buffer_ini[31:0], gmii_rxd};
        end
    end
    
    reg start_handle_clkPP, start_handle_clkPP_next ;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            start_handle_clkPP <= 1'b0;
        end else begin
            start_handle_clkPP <= start_handle_clkPP_next;
        end
    end

    always @* begin
        start_handle_clkPP_next = start_handle_clkPP;
        if (gmii_rx_dv_cdc && ({buffer_ini_clkPP[31:0], gmii_rxd_clkPP} == 40'h55_5555_55d5)) begin
            start_handle_clkPP_next = 1'b1;
        end
        if (~gmii_rx_dv_cdc) begin
            start_handle_clkPP_next = 1'b0;
        end
    end
    
    reg [39:0] buffer_ini_clkPP, buffer_ini_clkPP_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            buffer_ini_clkPP <= 40'd0;
        end else begin
            buffer_ini_clkPP <= buffer_ini_clkPP_next;
        end
    end

    always @* begin
        buffer_ini_clkPP_next = buffer_ini_clkPP;
        if (gmii_rx_dv_cdc) begin
            buffer_ini_clkPP_next = {buffer_ini_clkPP[31:0], gmii_rxd_clkPP};
        end    
    end
    
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            addr_gmii <= 11'd0;
        end else begin
            addr_gmii <= addr_gmii_next;
        end
    end

    wire TRANSFER_TCP_cdc;
    // CDC for IDLE_RX_state signal
    cdc_delay1 u_TRANSFER_TCP_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src((network_fsm_TCP == TRANSFER_TCP)),
        .pulse_des(TRANSFER_TCP_cdc)
    );

    always @* begin
        addr_gmii_next = addr_gmii;
        if (start_handle) begin
            addr_gmii_next = addr_gmii + 11'd1;
//        end else if ((network_fsm_TCP == TRANSFER_TCP) && (gmii_rx_dv)) begin
        end else if (TRANSFER_TCP_cdc && (gmii_rx_dv)) begin
                addr_gmii_next = 11'd0;
        end else begin
            if (IDLE_RX_cdc) begin
                addr_gmii_next = 11'd0;
            end 
        end
    end
    
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            tcp_segment_len <= 16'd0;
        end else begin
            tcp_segment_len <= tcp_segment_len_next;
        end
    end

    always @* begin
        tcp_segment_len_next = tcp_segment_len;
        if (addr_gmii == (LEN_TOL_LEN - LEN_SFD)) begin
            tcp_segment_len_next = buffer[15:0] - 16'd20;
        end
        else if (IDLE_RX_cdc) begin
            tcp_segment_len_next = 16'd0;
        end
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            FCS_received <= 32'd0;
        end else begin
            FCS_received <= FCS_received_next;
        end
    end

    always @* begin
        FCS_received_next = FCS_received;
        if (addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD+4)) begin
            FCS_received_next = buffer[31:0];
        end
        if (IDLE_RX_cdc) begin
            FCS_received_next = 32'd0;
        end
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            ack_RX <= 32'd0;
        end else begin
            ack_RX <= ack_RX_next;
        end
    end

    always @* begin
        ack_RX_next = ack_RX;
        if (addr_gmii == (LEN_ACK - LEN_SFD)) begin
            ack_RX_next = buffer[31:0];
        end
        //        if (network_fsm_RX == IDLE_RX) begin 
        //            ack_RX_next = 32'd0;
        //        end 
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            seq_RX <= 32'd0;
        end else begin
            seq_RX <= seq_RX_next;
        end
    end

    always @* begin
        seq_RX_next = seq_RX;
        if (addr_gmii == (LEN_SEQ - LEN_SFD)) begin
            seq_RX_next = buffer[31:0];
        end
        //        if (network_fsm_RX == IDLE_RX) begin 
        //            seq_RX_next = 32'd0;
        //        end 
    end

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            packet_valid <= 1'b0;
        end else begin
            packet_valid <= packet_valid_next;
        end
    end

    always @* begin
        packet_valid_next = packet_valid;
        // Begin of Data link layer
        if (addr_gmii == (LEN_DES_MAC_ADDR - LEN_SFD)) begin
            //            packet_valid_next = 1'b1;
            packet_valid_next = (buffer == DES_MAC_RX_B);
        end
        if (addr_gmii == (LEN_SRC_MAC_ADDR - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer == SRC_MAC_RX_B);
        end
        if (addr_gmii == (LEN_TYPE - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[15:0] == TYPE);
        end

        /// Begin of Network layer
        if (addr_gmii == (LEN_SERVICE_TYPE - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[15:0] == {VERSION, HEADER_LEN, SERVICE_TYPE});
        end
        if (addr_gmii == (LEN_PROTOCOL- LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[7:0] == PROTOCOL);
        end
        if (addr_gmii == (LEN_SRC_IP - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[31:0] == SRC_IP_RX_B);
        end
        if (addr_gmii == (LEN_DES_IP - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[31:0] == DES_IP_RX_B);
        end

        if (addr_gmii == (LEN_DES_IP - LEN_SFD) + 1) begin // Check if the network_chksum is correct 
            packet_valid_next = packet_valid & (&(network_chksum[15:0]));
        end

        // Transport Layer  
        if (addr_gmii == (LEN_DES_PORT - LEN_SFD)) begin
            packet_valid_next = packet_valid & (buffer[31:0] == {SRC_PORT_RX_B, DES_PORT_RX_B});
        end
        if (addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD + 1)) begin // 1 is the delay of tcp_chksum result (original) (after cdc design I add another delay to 3 for correct check) 1052+41-7+2 = 
//            packet_valid_next = packet_valid & (&(tcp_chksum[15:0]));
            packet_valid_next = (&(tcp_chksum[15:0]));
        end
        if (addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD + 2)) begin // 1 is the delay of tcp_chksum result (original) (after cdc design I add another delay to 3 for correct check) 1052+41-7+2 = 
//            packet_valid_next = packet_valid & (&(tcp_chksum[15:0]));
            packet_valid_next = (&(tcp_chksum[15:0]));
        end
        if (addr_gmii == (tcp_segment_len + LEN_DES_IP - LEN_SFD + 3)) begin // 1 is the delay of tcp_chksum result (original) (after cdc design I add another delay to 3 for correct check) 1052+41-7+2 = 
//            packet_valid_next = packet_valid & (&(tcp_chksum[15:0]));
            packet_valid_next = (&(tcp_chksum[15:0]));
        end
        if (IDLE_RX_state) begin
            packet_valid_next = 1'b0;
        end
    end

    reg [47:0] buffer;
    wire [47:0] buffer_next;
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            buffer <= 48'd0;
        end else begin
            buffer <= buffer_next;
        end
    end
    assign buffer_next = {buffer[39:0], gmii_rxd};


    reg [19:0] network_chksum, network_chksum_next;
    reg [19:0] tcp_chksum, tcp_chksum_next;
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            network_chksum <= 20'd0;
            tcp_chksum <= 20'd0;
        end else begin
            network_chksum <= network_chksum_next;
            tcp_chksum <= tcp_chksum_next;
        end
    end

    always @* begin
        network_chksum_next = {4'd0, network_chksum[15:0]} + {16'd0, network_chksum[19:16]};
        if (HANDLE_RX_cdc) begin
            if (addr_gmii <= (LEN_DES_IP - LEN_SFD) && addr_gmii >= (LEN_SERVICE_TYPE - LEN_SFD)) begin
                if (~addr_gmii[0])
                    network_chksum_next = network_chksum + {4'd0, buffer[15:0]};
            end
        end else begin
            network_chksum_next = 20'd0;
        end
    end

    always @* begin
        tcp_chksum_next = {4'd0, tcp_chksum[15:0]} + {16'd0, tcp_chksum[19:16]};
        if (HANDLE_RX_cdc) begin
            if ((addr_gmii >= (LEN_SRC_IP - LEN_SFD)-2) && ((addr_gmii) < (tcp_segment_len + LEN_DES_IP - LEN_SFD + 2))) begin
                if (~addr_gmii[0])
                    tcp_chksum_next = tcp_chksum + {4'd0, buffer[15:0]};
            end
            if (addr_gmii == (LEN_PROTOCOL - LEN_SFD)) begin // TCP pseudo header
                tcp_chksum_next = tcp_chksum + {12'd0, buffer[7:0]};
            end
            if (addr_gmii == (LEN_TOL_LEN - LEN_SFD)) begin // TCP pseudo header
                tcp_chksum_next = tcp_chksum + {4'd0, buffer[15:0]} - 20'd20;
            end
        end else begin
            tcp_chksum_next = 20'd0;
        end
    end

    wire HANDLE_RX_state;
    assign HANDLE_RX_state = (network_fsm_RX == HANDLE_RX) ? 1 : 0;

    // CDC for COMPUTE_CRC_TX_state signal
    cdc_delay1 u_HANDLE_RX_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src(HANDLE_RX_state),
        .pulse_des(HANDLE_RX_cdc)
    );

    reg [7:0] addr_crc32, addr_crc32_next;
    reg [7:0] keep_crc32, keep_crc32_next;
    reg valid_in_crc32, valid_in_crc32_next;
    reg last_crc32, last_crc32_next;

    wire [7:0] addr_crc32_next_delay;
    wire last_crc32_next_delay;
    wire [7:0] keep_crc32_next_delay;

    wire valid_out_crc32;
    wire [7:0] control_out_crc32;
    wire last_out_crc32;
    wire [31:0] crc32_out;
    wire crc32_valid;

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            addr_crc32 <= 8'd0;
            valid_in_crc32 <= 1'b0;
            last_crc32 <=1'b0;
            keep_crc32 <= 8'd0;
        end else begin
            addr_crc32 <= addr_crc32_next;
            valid_in_crc32 <= valid_in_crc32_next;
            last_crc32 <= last_crc32_next;
            keep_crc32 <= keep_crc32_next;
        end
    end

    wire terminal_crc32; // equals to 1 as addra has not reached the terminal address

    // total length of Ethernet frame, without Preamable, SFD and FCS 
    wire [10:0] addr_gmii_wo_fcs;

    //    assign addr_gmii_wo_fcs = addr_gmii - 11'd4;
    assign addr_gmii_wo_fcs = addr_gmii_delay - 11'd4;

    assign terminal_crc32 = (addr_crc32 < (addr_gmii_wo_fcs[10:3] + |(addr_gmii_wo_fcs[2:0]) + 1));

    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            addr_gmii_delay <= 11'd0;
        end else begin
            addr_gmii_delay <= addr_gmii;
        end
    end


    always @* begin
        addr_crc32_next = addr_crc32;
        //        if ((network_fsm_RX == COMPUTE_CRC_RX) && (~start_handle) && (~gmii_rx_dv)) begin 
        if ((COMPUTE_CRC_RX_cdc)) begin
            if (terminal_crc32) begin
                addr_crc32_next = addr_crc32 + 8'd1;
            end else begin
                addr_crc32_next = addr_crc32;
            end
        end else if (IDLE_RX_cdc) begin
            addr_crc32_next = 8'd0;
        end
    end

    always @* begin
        valid_in_crc32_next = valid_in_crc32;
        if ((COMPUTE_CRC_RX_cdc) & (terminal_crc32) & (addr_crc32 >= 1)) begin
            valid_in_crc32_next = 1'b1;
        end else begin
            valid_in_crc32_next = 1'b0;
        end
    end
    
    always @* begin
        keep_crc32_next = 8'd0;
        if ((COMPUTE_CRC_RX_cdc) && (terminal_crc32) && (addr_crc32 >= 0)) begin
            if (|addr_gmii_wo_fcs[2:0]) begin
                if (addr_crc32 == 0) begin
                    keep_crc32_next = 8'hfe;
                end else if (addr_crc32 == (addr_gmii_wo_fcs[10:3]+1)) begin
                    keep_crc32_next = (8'd1 << (addr_gmii_wo_fcs[2:0] - 3'd1)) - 8'd1;
                end else begin
                    keep_crc32_next = 8'hff;
                end
            end else begin
                if (addr_crc32 == 1) begin
                    keep_crc32_next = 8'hfe;
                end else begin
                    keep_crc32_next = 8'hff;
                end
            end
        end
    end
    always @* begin
        last_crc32_next = last_crc32;
        if ((COMPUTE_CRC_RX_cdc)) begin
            if (|addr_gmii_wo_fcs[2:0]) begin
                if (addr_crc32 == addr_gmii_wo_fcs[10:3]+1) begin
                    last_crc32_next = 1'b1;
                end else begin
                    last_crc32_next = 1'b0;
                end
            end else begin
                if (addr_crc32 == addr_gmii_wo_fcs[10:3]) begin
                    last_crc32_next = 1'b1;
                end else begin
                    last_crc32_next = 1'b0;
                end
            end
        end
    end

    wire COMPUTE_CRC_RX_state;
    assign COMPUTE_CRC_RX_state = (network_fsm_RX == COMPUTE_CRC_RX) ? 1 : 0;

    // CDC for COMPUTE_CRC_RX_state signal
    cdc_delay1 u_COMPUTE_CRC_RX_cdc(
        .clk_src(clk_PP),
        .clk_des(clk_GMII),
        .reset(reset),
        .pulse_src(COMPUTE_CRC_RX_state),
        .pulse_des(COMPUTE_CRC_RX_cdc)
    );

    reg [63:0] packet_in_crc32;
    wire [63:0] dout_bram_crc;
    always @* begin
        packet_in_crc32 = 64'h0707_0707_0707_0707;
        if (addr_crc32 >= 2) begin
            packet_in_crc32 = dout_bram_crc & {{8{keep_crc32[7]}}, {8{keep_crc32[6]}}, {8{keep_crc32[5]}}, {8{keep_crc32[4]}}, {8{keep_crc32[3]}},
            {8{keep_crc32[2]}}, {8{keep_crc32[1]}}, {8{keep_crc32[0]}}};
        end else if (addr_crc32 == 1) begin
            packet_in_crc32 = 64'hd555_5555_5555_5555;
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
            packet_in_crc32_delay <= packet_in_crc32;
            keep_crc32_delay <= keep_crc32;
            valid_in_crc32_delay <= valid_in_crc32;
            last_crc32_delay <= last_crc32;
        end
    end

//    //packet_in_crc32_delay delay by two for correct crc32
//    reg [63:0] packet_in_crc32_delay_delay;
//    reg [63:0] packet_in_crc32_delay_delay_delay;
//    always @(posedge clk_GMII or posedge reset) begin
//        if (reset) begin
//            packet_in_crc32_delay_delay          <= 64'd0;
//            packet_in_crc32_delay_delay_delay <= 64'd0;
//        end else begin
//            packet_in_crc32_delay_delay          <= packet_in_crc32_delay;
//            packet_in_crc32_delay_delay_delay <= packet_in_crc32_delay_delay;
//        end
//    end

//    //keep_crc32_delay delay by two for correct crc32
//    reg [7:0] keep_crc32_delay_delay;
//    reg [7:0] keep_crc32_delay_delay_delay;
//    always @(posedge clk_GMII or posedge reset) begin
//        if (reset) begin
//            keep_crc32_delay_delay          <= 64'd0;
//            keep_crc32_delay_delay_delay <= 64'd0;
//        end else begin
//            keep_crc32_delay_delay          <= keep_crc32_delay;
//            keep_crc32_delay_delay_delay <= keep_crc32_delay_delay;
//        end
//    end

//    //last_crc32_delay delay by two for correct crc32
//    reg [0:0] last_crc32_delay_delay;
//    reg [0:0] last_crc32_delay_delay_delay;
//    always @(posedge clk_GMII or posedge reset) begin
//        if (reset) begin
//            last_crc32_delay_delay          <= 64'd0;
//            last_crc32_delay_delay_delay <= 64'd0;
//        end else begin
//            last_crc32_delay_delay          <= last_crc32_delay;
//            last_crc32_delay_delay_delay <= last_crc32_delay_delay;
//        end
//    end

    // Output of CRC32 (use clk_GMII as driven clk, therefore we need crc32_valid_delay_delay to check crc32_out is valid)
    always @(posedge clk_GMII or posedge reset) begin
        if (reset) begin
            crc32_valid_reg <= 1'b0;
        end else begin
            crc32_valid_reg <= crc32_valid;
        end
    end 
    
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            crc32_valid_delay <= 1'b0;
        end else begin
            crc32_valid_delay <= crc32_valid_reg;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            crc32_valid_delay_delay <= 1'b0;
        end else begin
            crc32_valid_delay_delay <= crc32_valid_delay;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            crc32_valid_delay_delay_delay <= 1'b0;
        end else begin
            crc32_valid_delay_delay_delay <= crc32_valid_delay_delay;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            crc32_out_trans <= 32'd0;
        end else begin
            crc32_out_trans <= crc32_out_trans_next;
        end
    end
    
    always @* begin
        crc32_out_trans_next = crc32_out_trans;
        if (crc32_valid_delay_delay) begin
            crc32_out_trans_next = crc32_out;
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

    BRAM_wrapper Ubram_crc
    (
        // -- interface to CRC32.v
        .BRAM_PORTA_addr(addr_crc32),
        .BRAM_PORTA_clk(clk_GMII),
        .BRAM_PORTA_din(),
        .BRAM_PORTA_dout(dout_bram_crc),
        .BRAM_PORTA_we(1'b0),

        // -- interface to frame data
        .BRAM_PORTB_addr(addr_gmii),
        .BRAM_PORTB_clk(clk_GMII),
        .BRAM_PORTB_din(gmii_rxd),
        .BRAM_PORTB_dout(),
//        .BRAM_PORTB_en(1'b1),
        .BRAM_PORTB_we(start_handle)
    );



    // To PP interface
    // --------------------------------------------



    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            cnt_clkRX_msg <= 2'd0;
        end else begin
            cnt_clkRX_msg <= cnt_clkRX_msg_next;
        end
    end
    assign clkRX_msg = clk_PP;
    //    BUFGCE_DIV #(
    //        .BUFGCE_DIVIDE(4)
    //    ) UclkRX_msg_buf(
    //        .I(clk_PP),
    //        .CLR(1'b0), 
    //        .CE(1'b1),
    //        .O(clkRX_msg)
    //    );
    always @* begin
        cnt_clkRX_msg_next = cnt_clkRX_msg - 2'd1;
    end


    // ---------------------------------------------------
    //    input busy_PP2Net_RX,                   // BRAMMsgRX is used by PP
    //    output reg busy_Net2PP_RX,                  // BRAMMsgRX is used by networkCentCtrl
    //    output reg msg_accessed,                    // msg is stored in BRAMMsgTX by networkCentCtrl


    //    output reg [31:0] dataRX_msg,               // message pasrsed from Ethernet frame
    //    output reg weRX_msg,                        // write enable for BRAMMsgRX
    //    output reg [10:0] addrRX_msg,               // addr for BRAMMSGRX
    //    output reg [10:0] sizeRX_msg,               // receoved message size
    // ---------------------------------------------------


    reg [10:0] addr_cdc, addr_cdc_next;
    wire [7:0] dout_cdc;
    reg [31:0] cdc_buf;
    wire [31:0] cdc_buf_next;


    reg busy_Net2PP_RX_next;
    reg msg_accessed_en, msg_accessed_en_next;

    reg [31:0] dataRX_msg_next;
    reg weRX_msg_next;
    reg [10:0] addrRX_msg_next;
    reg [10:0] sizeRX_msg_next;

    reg [10:0] base_addr_temp, base_addr_temp_next;

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            addr_cdc <= 11'd54;
            cdc_buf <= 32'd0;
        end else begin
            addr_cdc <= addr_cdc_next;
            cdc_buf <= cdc_buf_next;
        end
    end

    always@* begin
        addr_cdc_next = addr_cdc;
        if ((network_fsm_RX == WAIT_RX) && (~busy_PP2Net_RX)) begin
            // 2 is the delay of BRAM read 
            // 4 is the delay for storing 4 8-bit msg to 32-bit msg
            // 4 is the delay for computing addrRX_msg(base_addr_temp + addrRX_msg_one_frame)
            // 54 is the length from the begin of frame to the end of TCP header
            // addr_cdc is begin from 53 not 54         
            if (addr_cdc < (tcp_segment_len[10:0] - 11'd20 + 11'd2 + 11'd4 + 11'd4 +11'd54 - 11'd1)) begin
                addr_cdc_next = addr_cdc + 11'd1;
            end else begin
                addr_cdc_next = 11'd54;
            end
        end
        if (network_fsm_RX == IDLE_RX) begin
            addr_cdc_next = 11'd54;
        end
    end

    assign cdc_buf_next = {cdc_buf[23:0], dout_cdc};

    reg msg_accessed_next;
    reg [1:0] cnt_msg_accessed, cnt_msg_accessed_next;
    always @(posedge clkRX_msg or posedge reset) begin
        if (reset) begin
            base_addr_temp <= 11'd0;
            sizeRX_msg <= 11'd0;
            busy_Net2PP_RX <= 1'b0;
            msg_accessed_en <= 1'b0;
            msg_accessed <= 1'b0;
            cnt_msg_accessed <= 2'd0;
        end else begin
            base_addr_temp <= base_addr_temp_next;
            sizeRX_msg <= sizeRX_msg_next;
            busy_Net2PP_RX <= busy_Net2PP_RX_next;
            msg_accessed_en <= msg_accessed_en_next;
            msg_accessed <= msg_accessed_next;
            cnt_msg_accessed <= cnt_msg_accessed_next;
        end
    end

    always @* begin
        cnt_msg_accessed_next = cnt_msg_accessed;
        if (msg_accessed_en) begin
            cnt_msg_accessed_next = (cnt_msg_accessed == 2'b11)? cnt_msg_accessed: cnt_msg_accessed + 2'b1;
        end else begin
            cnt_msg_accessed_next = 2'd0;
        end
    end
    always @* begin
        msg_accessed_next = msg_accessed;
        if (msg_accessed_en) begin
            msg_accessed_next = (cnt_msg_accessed == 2'b11)? 1'b1: 1'b0;
        end else begin
            msg_accessed_next = 1'b0;
        end
    end

    //    //dataRX_msg should synchronize with WeRX_msg (CDC) (delay 1 cycle, from test, add 1 register)
    reg [31:0] dataRX_msg;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            dataRX_msg  <= 32'd0;
        end else begin
            dataRX_msg <= dataRX_msg_next;
        end
    end

//    always @(posedge clk_PP or posedge reset) begin
//        if (reset) begin
//            dataRX_msg_cdc  <= 32'd0;
//        end else begin
//            dataRX_msg_cdc <= dataRX_msg;
//        end
//    end

    reg [31:0] dataRX_msg_bram, dataRX_msg_bram_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            dataRX_msg_bram <= 32'd0;
        end else begin
            dataRX_msg_bram <= dataRX_msg_bram_next;
        end
    end

    always @* begin
        busy_Net2PP_RX_next = busy_Net2PP_RX;
        if (busy_Net2PP_RX) begin
            //            if ((sizeRX_msg != 0) && (sizeRX_msg == addrRX_msg) && (msg_accessed)) begin 
            if (msg_accessed) begin
                busy_Net2PP_RX_next = 1'b0;
            end
        end else begin
//            if ((network_fsm_RX == WAIT_RX) && (~busy_PP2Net_RX) && (network_fsm_TCP == TRANSFER_TCP) && (tcp_segment_len > 50)) begin
            if ((network_fsm_RX == WAIT_RX) && (~busy_PP2Net_RX) && (network_fsm_TCP == TRANSFER_TCP) && (tcp_segment_len_received_valid)) begin
                busy_Net2PP_RX_next = 1'b1;
            end
        end
    end
    
    always @* begin
        msg_accessed_en_next = msg_accessed_en;
        if (msg_accessed_en) begin
            if (busy_PP2Net_RX) begin
                msg_accessed_en_next = 1'b0;
            end
        end else begin
            if ((~busy_PP2Net_RX) && (sizeRX_msg == addrRX_msg) && (sizeRX_msg != 0)) begin
                msg_accessed_en_next = 1'b1;
            end
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            weRX_msg <= 1'b0;
        end else begin
            weRX_msg <= weRX_msg_next;
        end
    end

    wire tcp_segment_len_weRX;
    // cdc of tcp_segment len signal for weRX (I think might useless)
    cdc_delay1 u_tcp_segment_len_weRX_cdc (
        .clk_src(clk_GMII),
        .clk_des(clk_PP),
        .reset(reset),
        .pulse_src(tcp_segment_len > 20),
        .pulse_des(tcp_segment_len_weRX)
    );
    
    always @* begin
        weRX_msg_next = weRX_msg;
        // 54 is the begin of tcp body, 
        // 4 is the length of sizeRX and base addr of this segment 
        // 4 is the delay of storing 4 8-bits of msg to 32 -bits
        // 4 is the delay of waiting for addrRX_msg computing (base_addr_temp + addrRX_msg_one_frame)
        // 2 is the delay from BRAM
        // dataTX_msg will pop-out 1 cycle early
        // weRX_msg_next should be synchrounous to dataRX_msg
        if (tcp_segment_len_weRX) begin
            //            if ((addrRX_msg == base_addr_temp + 256) && (addr_cdc[1:0] == 2'b11)) begin
            if ((addrRX_msg == base_addr_temp + 256)) begin
                weRX_msg_next = 1'b0;
            end
            else if (addr_cdc >= (11'd54 + 11'd4 + 11'd4 + 11'd4 + 11'd2 - 11'd1)) begin
                weRX_msg_next = 1'b1;
            end
            else begin
                weRX_msg_next = 1'b0;
            end
        end
    end

    always @* begin
        dataRX_msg_next = dataRX_msg;
        if (addr_cdc[1:0] == 2'b11) begin
            dataRX_msg_next = dataRX_msg_bram;
        end
    end

    always @* begin
        dataRX_msg_bram_next = dataRX_msg_bram;
        if (addr_cdc[1:0] == 2'b11) begin
            dataRX_msg_bram_next = {cdc_buf[23:0], dout_cdc};
        end
    end

    always @* begin
        sizeRX_msg_next = sizeRX_msg;
        base_addr_temp_next = base_addr_temp;
        if ((addr_cdc >= 11'd60) && (addr_cdc < 11'd63)) begin
            sizeRX_msg_next = dataRX_msg_bram[26:16];
            base_addr_temp_next = dataRX_msg_bram[10:0];
        end
        if (busy_PP2Net_RX) begin
            sizeRX_msg_next = 11'd0;
            base_addr_temp_next = 11'd0;
        end
    end

    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            addrRX_msg <= 11'd0;
        end else begin
            addrRX_msg <= addrRX_msg_next;
        end
    end

//    always @(posedge clk_PP or posedge reset) begin
//        if (reset) begin
//            addrRX_msg_cdc  <= 32'd0;
//        end else begin
//            addrRX_msg_cdc <= addrRX_msg;
//        end
//    end

    reg [10:0] addrRX_msg_one_frame, addrRX_msg_one_frame_next;
    always @(posedge clk_PP or posedge reset) begin
        if (reset) begin
            addrRX_msg_one_frame <= 11'd0;
        end else begin
            addrRX_msg_one_frame <= addrRX_msg_one_frame_next;
        end
    end
    always @* begin
        addrRX_msg_one_frame_next = addrRX_msg_one_frame;
        if (addr_cdc[1:0] == 2'b11) begin
            if ((addr_cdc > 11'd63)) begin
                addrRX_msg_one_frame_next = addrRX_msg_one_frame + 1'b1;
            end else begin
                addrRX_msg_one_frame_next = 11'd0;
            end
        end
    end
    always @* begin
        addrRX_msg_next = addrRX_msg;
        if (addr_cdc[1:0] == 2'b11) begin
            if (addr_cdc >= 11'd63) begin
                addrRX_msg_next = base_addr_temp + addrRX_msg_one_frame;
            end else begin
                addrRX_msg_next = 11'd0;
                //                if (~busy_Net2PP_RX) begin 
                //                    addrRX_msg_next = 11'd0;
                //                end else begin
                //                    addrRX_msg_next = addrRX_msg;
                //                end
            end
        end
        if (busy_PP2Net_RX) begin
            addrRX_msg_next = 11'd0;
        end
    end


    CDC_BRAM_wrapper Ucdc_bram
    (.BRAM_PORTA_addr(addr_gmii),
        .BRAM_PORTA_clk(clk_GMII),
        .BRAM_PORTA_din(gmii_rxd),
        .BRAM_PORTA_we(start_handle),

        .BRAM_PORTB_addr(addr_cdc),
        .BRAM_PORTB_clk(clk_PP),
        .BRAM_PORTB_dout(dout_cdc));
endmodule