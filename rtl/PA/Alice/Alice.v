





`timescale 1ns/100ps


`include "./pa_parameter.v"



module Alice (
    input clk,
    input rst_n,
    //----------------------------new add signal------------------------------
    //    input clk_100M,
    //    input clk_GMII,
    input gmii_tx_clk,
    input gmii_rx_clk,


    input clk_PP,
    input link_status,

    output A2B_busy_PP2Net_TX,
    output A2B_busy_Net2PP_TX,

    output A2B_busy_PP2Net_RX,
    output A2B_busy_Net2PP_RX,


    output [7:0] gmii_txd, // Transmit data from client MAC.
    output gmii_tx_en, // Transmit control signal from client MAC.
    output gmii_tx_er, // Transmit control signal from client MAC.
    input   [7:0] gmii_rxd, // Received Data to client MAC.
    input   gmii_rx_dv, // Received control signal to client MAC.
    input   gmii_rx_er, // Received control signal to client MAC.

    output clkTX_msg,
    output clkRX_msg,
    //----------------------------new add signal------------------------------
    input start_switch,

    input [31:0] secretkey_length, //secret key length
    input reconciled_key_addr_index, //address index
    //0:addr0 ~ addr16383
    //1:addr16384 ~ addr32767


    // Alice secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]A_Secretkey_addrb, //0~32767
    output wire A_Secretkey_clkb,
    output wire [63:0]A_Secretkey_dinb,
    output wire A_Secretkey_enb, //1'b1
    output wire A_Secretkey_rstb, //1'b0
    output wire [7:0]A_Secretkey_web,

    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
//    output wire [14:0]B_Secretkey_addrb, //0~32767
//    output wire B_Secretkey_clkb,
//    output wire [63:0]B_Secretkey_dinb,
//    output wire B_Secretkey_enb, //1'b1
//    output wire B_Secretkey_rstb, //1'b0
//    output wire [7:0]B_Secretkey_web,


    output A_pa_finish, //pa is done
    output A_pa_fail //pa is fail due to error secret key length

//    output B_pa_finish, //pa is done
//    output B_pa_fail, //pa is fail due to error secret key length

//    output B_reset_pa_parameter //

);



    //****************************** start compute ******************************
    wire start_pa;
    reg [15:0] start_switch_cnt;

    always @(posedge clk ) begin
        if (~rst_n) begin
            start_switch_cnt <= 16'b0;
        end
        else if (start_switch_cnt==16'b0000_0000_1111_1111) begin
            start_switch_cnt <= start_switch_cnt;
        end
        else if (start_switch) begin
            start_switch_cnt <= start_switch_cnt + 1'b1;
        end
        else begin
            start_switch_cnt <= start_switch_cnt;
        end
    end

    assign start_pa = (start_switch_cnt==16'b0000_0000_1000_0000)? 1'b1:1'b0;
    //****************************** start compute ******************************













    //****************************** key BRAM instantiation ******************************
    wire [63:0] A_key_dout;
    wire [14:0] A_key_index_and_addr;
    wire A_key_clk;
    wire A_key_en;
    wire A_key_we;
    wire A_key_rst;

    wire [63:0] B_key_dout;
    wire [14:0] B_key_index_and_addr;
    wire B_key_clk;
    wire B_key_en;
    wire B_key_we;
    wire B_key_rst;

    reconciledkey_BRAM init_key (
        .clka(A_key_clk), // input wire clka
        .ena(A_key_en), // input wire ena
        .wea(A_key_we), // input wire [0 : 0] wea
        .addra(A_key_index_and_addr), // input wire [14 : 0] addra
        .dina(), // input wire [63 : 0] dina
        .douta(A_key_dout), // output wire [63 : 0] douta

        .clkb(B_key_clk), // input wire clkb
        .enb(B_key_en), // input wire enb
        .web(B_key_we), // input wire [0 : 0] web
        .addrb(B_key_index_and_addr), // input wire [14 : 0] addrb
        .dinb(), // input wire [63 : 0] dinb
        .doutb(B_key_dout) // output wire [63 : 0] doutb
    );
    //****************************** key BRAM instantiation ******************************













    //****************************** A random bit BRAM instantiation ******************************
    wire [63:0] A_PArandombit_doutb;
    wire [13:0] A_PArandombit_addrb; //0~16383
    wire A_PArandombit_clkb;
    wire A_PArandombit_enb; //1'b1
    wire A_PArandombit_rstb; //1'b0
    wire [7:0] A_PArandombit_web; //8'b0


    A_randombit_BRAM A_init_randombit (
        .clka(), // input wire clka
        .ena(1'b0), // input wire ena
        .wea(1'b0), // input wire [0 : 0] wea
        .addra(), // input wire [13 : 0] addra
        .dina(), // input wire [63 : 0] dina
        .douta(), // output wire [63 : 0] douta

        .clkb(A_PArandombit_clkb), // input wire clkb
        .enb(A_PArandombit_enb), // input wire enb
        .web((|A_PArandombit_web)), // input wire [0 : 0] web
        .addrb(A_PArandombit_addrb), // input wire [13 : 0] addrb
        .dinb(), // input wire [63 : 0] dinb
        .doutb(A_PArandombit_doutb) // output wire [63 : 0] doutb
    );
    //****************************** A random bit BRAM instantiation ******************************
    //****************************** A TX pa fifo ******************************
    wire A_TX_pa_wr_clk;
    wire [31:0] A_TX_pa_wr_din;
    wire A_TX_pa_wr_en;
    wire A_TX_pa_full;
    wire A_TX_pa_wr_ack;

    wire A_TX_pa_rd_clk;
    wire A_TX_pa_rd_en;
    wire [31:0] A_TX_pa_rd_dout;
    wire A_TX_pa_empty;
    wire A_TX_pa_rd_valid;

    wire A_TX_pa_wr_rst_busy;
    wire A_TX_pa_rd_rst_busy;

    A_TX_PA_FIFO A_A2B_pa_fifo (
        .srst(~rst_n), // input wire srst

        .wr_clk(A_TX_pa_wr_clk), // input wire wr_clk
        .din(A_TX_pa_wr_din), // input wire [31 : 0] din
        .wr_en(A_TX_pa_wr_en), // input wire wr_en
        .full(A_TX_pa_full), // output wire full
        .wr_ack(A_TX_pa_wr_ack), // output wire wr_ack

        .rd_clk(A_TX_pa_rd_clk), // input wire rd_clk
        .rd_en(A_TX_pa_rd_en), // input wire rd_en
        .dout(A_TX_pa_rd_dout), // output wire [31 : 0] dout
        .empty(A_TX_pa_empty), // output wire empty
        .valid(A_TX_pa_rd_valid), // output wire valid

        .wr_rst_busy(A_TX_pa_wr_rst_busy), // output wire wr_rst_busy
        .rd_rst_busy(A_TX_pa_rd_rst_busy) // output wire rd_rst_busy
    );
    //****************************** A TX pa fifo ******************************










    //****************************** A pa ******************************
    top_A_pa top_Apa (
        .clk(clk),
        .rst_n(rst_n),
        .start_A_pa(start_pa),

        .A_pa_finish(A_pa_finish),
        .A_pa_fail(A_pa_fail),

        .secretkey_length(secretkey_length),
        .reconciled_key_addr_index(reconciled_key_addr_index),

        .key_doutb(A_key_dout),
        .key_clkb(A_key_clk),
        .key_enb(A_key_en),
        .key_web(A_key_we),
        .key_rstb(A_key_rst),
        .key_index_and_addrb(A_key_index_and_addr),



        .PArandombit_doutb(A_PArandombit_doutb),
        .PArandombit_addrb(A_PArandombit_addrb),
        .PArandombit_clkb(A_PArandombit_clkb),
        .PArandombit_enb(A_PArandombit_enb),
        .PArandombit_rstb(A_PArandombit_rstb),
        .PArandombit_web(A_PArandombit_web),


        .Secretkey_addrb(A_Secretkey_addrb),
        .Secretkey_clkb(A_Secretkey_clkb),
        .Secretkey_dinb(A_Secretkey_dinb),
        .Secretkey_enb(A_Secretkey_enb),
        .Secretkey_rstb(A_Secretkey_rstb),
        .Secretkey_web(A_Secretkey_web),

        .A_TX_pa_wr_clk(A_TX_pa_wr_clk),
        .A_TX_pa_wr_din(A_TX_pa_wr_din),
        .A_TX_pa_wr_en(A_TX_pa_wr_en),
        .A_TX_pa_full(A_TX_pa_full),
        .A_TX_pa_wr_ack(A_TX_pa_wr_ack),
        .A_TX_pa_empty(A_TX_pa_empty)
    );
    //****************************** A pa ******************************

    //****************************** A packet  ******************************
    // Input 
    // wire clk;
    // wire rst_n;
    wire A2B_busy_Net2PP_TX;


    // Output 
    wire A2B_busy_PP2Net_TX;
    wire A2B_msg_stored;
    wire [10:0] A2B_sizeTX_msg; // Assuming this should be a register based on your module definition

    wire [3:0] A_packet_state;

    // A_A2B decoy fifo connections
    wire A_TX_decoy_rd_clk;
    wire A_TX_decoy_rd_en;
    wire [31:0] A_TX_decoy_rd_dout;
    wire A_TX_decoy_empty;
    wire A_TX_decoy_rd_valid;

    // A_A2B er fifo connections
    wire A_TX_er_rd_clk;
    wire A_TX_er_rd_en;
    wire [31:0] A_TX_er_rd_dout;
    wire A_TX_er_empty;
    wire A_TX_er_rd_valid;

    // // A_A2B pa fifo connections
    // wire A_TX_pa_rd_clk;
    // wire A_TX_pa_rd_en;
    // wire [31:0] A_TX_pa_rd_dout;
    // wire A_TX_pa_empty;
    // wire A_TX_pa_rd_valid;

    // TX BRAM connections
    wire A_TX_bram_clkb;
    wire A_TX_bram_enb;
    wire A_TX_bram_web;
    wire [10:0] A_TX_bram_addrb;
    wire [31:0] A_TX_bram_dinb;

    A_packet Apacket (
        .clk(clkTX_msg), // Clock signal
        .rst_n(rst_n), // Reset signal

        .busy_Net2PP_TX(A2B_busy_Net2PP_TX), // Input indicating the network to post-processing transmission is busy

        .busy_PP2Net_TX(A2B_busy_PP2Net_TX), // Output indicating post-processing to network transmission is busy
        .msg_stored(A2B_msg_stored), // Output indicating message is stored
        .sizeTX_msg(A2B_sizeTX_msg), // Output register for message size

        .A_packet_state(A_packet_state), // Output state of the A_packet FSM

        // A_A2B decoy fifo connections
        .A_TX_decoy_rd_clk(A_TX_decoy_rd_clk),
        .A_TX_decoy_rd_en(A_TX_decoy_rd_en),
        .A_TX_decoy_rd_dout(A_TX_decoy_rd_dout),
        .A_TX_decoy_empty(A_TX_decoy_empty),
        .A_TX_decoy_rd_valid(A_TX_decoy_rd_valid),

        // A_A2B er fifo connections
        .A_TX_er_rd_clk(A_TX_er_rd_clk),
        .A_TX_er_rd_en(A_TX_er_rd_en),
        .A_TX_er_rd_dout(A_TX_er_rd_dout),
        .A_TX_er_empty(A_TX_er_empty),
        .A_TX_er_rd_valid(A_TX_er_rd_valid),

        // A_A2B pa fifo connections
        .A_TX_pa_rd_clk(A_TX_pa_rd_clk),
        .A_TX_pa_rd_en(A_TX_pa_rd_en),
        .A_TX_pa_rd_dout(A_TX_pa_rd_dout),
        .A_TX_pa_empty(A_TX_pa_empty),
        .A_TX_pa_rd_valid(A_TX_pa_rd_valid),

        // TX BRAM connections
        .A_TX_bram_clkb(A_TX_bram_clkb),
        .A_TX_bram_enb(A_TX_bram_enb),
        .A_TX_bram_web(A_TX_bram_web),
        .A_TX_bram_addrb(A_TX_bram_addrb),
        .A_TX_bram_dinb(A_TX_bram_dinb)
    );

    //****************************** A packet  ******************************
    
   

//****************************** A2B BRAM instantiation ******************************
    
    
    A2B_BRAM_TX A2Bbram_TX (
        .clka(clkTX_msg), // input wire clkb
        .ena(1'b1), // input wire enb
        .wea(1'b0), // input wire [0 : 0] web
        .addra(A2B_addrTX_msg), // input wire [10 : 0] addrb
        .dina(), // input wire [31 : 0] dinb
        .douta(A2B_dataTX_msg), // output wire [31 : 0] doutb

        .clkb(A_TX_bram_clkb), // input wire clka
        .enb(A_TX_bram_enb), // input wire ena
        .web(A_TX_bram_web), // input wire [0 : 0] wea
        .addrb(A_TX_bram_addrb), // input wire [10 : 0] addra
        .dinb(A_TX_bram_dinb), // input wire [31 : 0] dina
        .doutb() // output wire [31 : 0] douta
    );

//    ****************************** A2B BRAM instantiation ******************************


    //--------------------------------------------TX module of A--------------------------
    wire clkTX_msg;
    wire clkRX_msg;
    
    wire [31:0] A2B_dataTX_msg;                // message from PP 
    wire [10:0] A2B_addrTX_msg;               // addr for BRAMMsgTX
    wire [10:0] A2B_sizeTX_msg;                // transmitting message size
        
    wire [31:0] A2B_dataRX_msg;               // message pasrsed from Ethernet frame
    wire [10:0] A2B_addrRX_msg;               // addr for BRAMMSGRX
    wire A2B_weRX_msg;                        // write enable for BRAMMsgRX
    wire [10:0] A2B_sizeRX_msg;               // receoved message size
    
    wire [3:0] network_fsm_TCP_A_TX;
    wire [2:0] transfer_fsm_A_TX;
    wire [2:0] network_fsm_TX_A_TX;
    wire [1:0] network_fsm_RX_A_TX;

    wire start_handle_FrameSniffer_A_TX;

    wire received_valid_A_TX;
    wire need_ack_A_TX;
    wire is_handshake_A_TX;
    wire transfer_en_A_TX;
    wire busy_TX2CentCtrl_A_TX;
    wire transfer_finish_A_TX;
    wire [10:0] index_frame_FrameGenerator_A_TX;
    wire [7:0] frame_data_FrameGenerator_A_TX;
    wire [15:0] total_len_TCP_FrameGenerator_A_TX;
    wire [63:0] douta_FrameGenerator_A_TX;
    wire [7:0] keep_crc32_FrameGenerator_A_TX;
    wire crc32_valid_FrameGenerator_A_TX;
    wire ack_received_A_TX;
    wire ack_received_cdc_after_FrameGenerator_A_TX;
    wire [15:0] sizeTX_msg_buf_FrameGenerator_A_TX;
    wire [15:0] base_addr_tmp_FrameGenerator_A_TX;
    wire [10:0] addr_gmii_FrameSniffer_A_TX;
    wire [15:0] tcp_segment_len_FrameSniffer_A_TX;
    wire [63:0] packet_in_crc32_FrameSniffer_A_TX;
    wire [7:0] keep_crc32_FrameSniffer_A_TX;
    wire [31:0] crc32_out_FrameSniffer_A_TX;
    wire [31:0] seq_RX_A_TX;
    wire [31:0] ack_RX_A_TX;
    wire [25:0] lost_A_TX;
    wire [19:0] tcp_chksum_FrameSniffer_A_TX;
    wire [19:0] network_chksum_FrameSniffer_A_TX;
    wire [31:0] FCS_received_FrameSniffer_A_TX;
    wire packet_valid_FrameSniffer_A_TX;
    wire msg_accessed_en_FrameSniffer_A_TX;
    //    wire lost_cnt_en;

    //---------------------------------------------TX module of A-------------------------
    networkCentCtrl #(
    .lost_cycle(26'd30),
    .phy_reset_wait(26'd20)
    ) Unetwork_A2B_TX(
        .reset(~rst_n), // system reset
        //        .clock_100M(clk_100M),            // clock for JTAG module 
        .clk_PP(clk_PP),
        .clkTX_msg(clkTX_msg), // clock for accessing BRAMMsgTX
        .clkRX_msg(clkRX_msg), // clock for accessing BRAMMsgRX

        // Post Processing interface
        //------------------------------------
        .busy_PP2Net_TX(A2B_busy_PP2Net_TX), // BRAMMsgTX is used by PP
        .busy_Net2PP_TX(A2B_busy_Net2PP_TX), // BRAMMsgTX is used by NetworkCentCtrl
        .msg_stored(A2B_msg_stored), // msg is stored in BRAMMsgTX by PP 

        .busy_PP2Net_RX(A2B_busy_PP2Net_RX), // BRAMMsgRX is used by PP
        .busy_Net2PP_RX(A2B_busy_Net2PP_RX), // BRAMMsgRX is used by networkCentCtrl
        .msg_accessed(A2B_msg_accessed), // msg is stored in BRAMMsgTX by networkCentCtrl

        .dataTX_msg(A2B_dataTX_msg), // message from PP 
        .addrTX_msg(A2B_addrTX_msg), // addr for BRAMMsgTX
        .sizeTX_msg(A2B_sizeTX_msg), // transmitting message size

        .dataRX_msg(A2B_dataRX_msg), // message pasrsed from Ethernet frame
        .weRX_msg(A2B_weRX_msg), // write enable for BRAMMsgRX
        .addrRX_msg(A2B_addrRX_msg), // addr for BRAMMSGRX
        .sizeRX_msg(A2B_sizeRX_msg), // receoved message size

        // GMII Interface (client MAC <=> PCS)
        //------------------------------------
        .gmii_tx_clk(gmii_tx_clk), // Transmit clock from client MAC.
        .gmii_rx_clk(gmii_rx_clk), // Receive clock to client MAC.
        .link_status(link_status), // Link status: use status_vector[0]
        .gmii_txd(gmii_txd), // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en), // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er), // Transmit control signal from client MAC.
        .gmii_rxd(gmii_rxd), // Received Data to client MAC.
        .gmii_rx_dv(gmii_rx_dv), // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er) // Received control signal to client MAC.
        // Test signal 
        ,
        .network_fsm_TCP(network_fsm_TCP_A_TX),
        .transfer_fsm(transfer_fsm_A_TX),
        .network_fsm_TX(network_fsm_TX_A_TX),
        .network_fsm_RX(network_fsm_RX_A_TX),
        .start_handle_FrameSniffer(start_handle_FrameSniffer_A_TX),
        .received_valid(received_valid_A_TX),
        .need_ack(need_ack_A_TX),
        .is_handshake(is_handshake_A_TX),
        .transfer_finish(transfer_finish_A_TX),
        .transfer_en(transfer_en_A_TX),
        .busy_TX2CentCtrl(busy_TX2CentCtrl_A_TX),
        .index_frame_FrameGenerator(index_frame_FrameGenerator_A_TX),
        .frame_data_FrameGenerator(frame_data_FrameGenerator_A_TX),
        .total_len_TCP_FrameGenerator(total_len_TCP_FrameGenerator_A_TX),
        .douta_FrameGenerator(douta_FrameGenerator_A_TX),
        .keep_crc32_FrameGenerator(keep_crc32_FrameGenerator_A_TX),
        .crc32_valid_FrameGenerator(crc32_valid_FrameGenerator_A_TX),
        .ack_received_cdc_after_FrameGenerator(ack_received_cdc_after_FrameGenerator_A_TX),
        .ack_received(ack_received_A_TX),
        .sizeTX_msg_buf_FrameGenerator(sizeTX_msg_buf_FrameGenerator_A_TX),
        .base_addr_tmp_FrameGenerator(base_addr_tmp_FrameGenerator_A_TX),
        .addr_gmii_FrameSniffer(addr_gmii_FrameSniffer_A_TX),
        .tcp_segment_len_FrameSniffer(tcp_segment_len_FrameSniffer_A_TX),
        .packet_in_crc32_FrameSniffer(packet_in_crc32_FrameSniffer_A_TX),
        .keep_crc32_FrameSniffer(keep_crc32_FrameSniffer_A_TX),
        .crc32_out_FrameSniffer(crc32_out_FrameSniffer_A_TX),
        .seq_RX(seq_RX_A_TX),
        .ack_RX(ack_RX_A_TX),
        .lost(lost_A_TX),
        .FCS_received_FrameSniffer(FCS_received_FrameSniffer_A_TX),
        .packet_valid_FrameSniffer(packet_valid_FrameSniffer_A_TX),
        .tcp_chksum_FrameSniffer(tcp_chksum_FrameSniffer_A_TX),
        .network_chksum_FrameSniffer(network_chksum_FrameSniffer_A_TX),
        .msg_accessed_en_FrameSniffer(msg_accessed_en_FrameSniffer_A_TX)
        //        .lost_cnt_en(lost_cnt_en)
    );
    //--------------------------------TX module of A------------------------------------


    wire A2B_busy_PP2Net_RX;
    assign A2B_busy_PP2Net_RX = 1'b0;

endmodule