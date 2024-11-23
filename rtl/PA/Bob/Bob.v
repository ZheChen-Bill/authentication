





`timescale 1ns/100ps


`include "./pa_parameter.v"




module Bob (
    input clk,
    input rst_n,
    //----------------------------new add signal------------------------------
    //    input clk_100M,
    //    input clk_GMII,
    input gmii_tx_clk,
    input gmii_rx_clk,

    input clk_PP,
    input link_status,
    //    input output_next_pb_TX,
    //    input output_next_pb_RX,

    output B2A_busy_Net2PP_TX,
    output B2A_busy_PP2Net_TX,

    output B2A_busy_Net2PP_RX,
    output B2A_busy_PP2Net_RX,


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
//    output wire [14:0]A_Secretkey_addrb, //0~32767
//    output wire A_Secretkey_clkb,
//    output wire [63:0]A_Secretkey_dinb,
//    output wire A_Secretkey_enb, //1'b1
//    output wire A_Secretkey_rstb, //1'b0
//    output wire [7:0]A_Secretkey_web,

    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]B_Secretkey_addrb, //0~32767
    output wire B_Secretkey_clkb,
    output wire [63:0]B_Secretkey_dinb,
    output wire B_Secretkey_enb, //1'b1
    output wire B_Secretkey_rstb, //1'b0
    output wire [7:0]B_Secretkey_web,


//    output A_pa_finish, //pa is done
//    output A_pa_fail, //pa is fail due to error secret key length

    output B_pa_finish, //pa is done
    output B_pa_fail, //pa is fail due to error secret key length

    output B_reset_pa_parameter //

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



    //****************************** B random bit BRAM instantiation ******************************
    wire [63:0]B_PArandombit_doutb;
    wire [13:0]B_PArandombit_addrb; //0~16383
    wire B_PArandombit_clkb;
    wire B_PArandombit_enb; //1'b1
    wire B_PArandombit_rstb; //1'b0
    wire [7:0]B_PArandombit_web; //8'b0


    wire [63:0] B_RX_PArandombit_dina;
    //wire [63:0] B_RX_PArandombit_dout;
    wire [13:0] B_RX_PArandombit_addra; //0~16383
    wire B_RX_PArandombit_clka;
    wire B_RX_PArandombit_ena; //1'b1
    wire B_RX_PArandombit_wea;


    B_RX_PArandombit_BRAM B_A2B_randombit_bram (
        .clka(B_RX_PArandombit_clka), // input wire clka
        .ena(B_RX_PArandombit_ena), // input wire ena
        .wea(B_RX_PArandombit_wea), // input wire [0 : 0] wea
        .addra(B_RX_PArandombit_addra), // input wire [13 : 0] addra
        .dina(B_RX_PArandombit_dina), // input wire [63 : 0] dina
        .douta(), // output wire [63 : 0] douta

        .clkb(B_PArandombit_clkb), // input wire clkb
        .enb(B_PArandombit_enb), // input wire enb
        .web((|B_PArandombit_web)), // input wire [0 : 0] web
        .addrb(B_PArandombit_addrb), // input wire [13 : 0] addrb
        .dinb(), // input wire [63 : 0] dinb
        .doutb(B_PArandombit_doutb) // output wire [63 : 0] doutb
    );
    //****************************** B random bit BRAM instantiation ******************************





    //****************************** B RX secretkey length fifo ******************************
    wire B_RX_secretkey_length_wr_clk;
    wire [31:0] B_RX_secretkey_length_wr_din;
    wire B_RX_secretkey_length_wr_en;
    wire B_RX_secretkey_length_full;
    wire B_RX_secretkey_length_wr_ack;

    wire B_RX_secretkey_length_rd_clk;
    wire B_RX_secretkey_length_rd_en;
    wire [31:0] B_RX_secretkey_length_rd_dout;
    wire B_RX_secretkey_length_empty;
    wire B_RX_secretkey_length_rd_valid;

    wire B_RX_secretkey_length_wr_rst_busy;
    wire B_RX_secretkey_length_rd_rst_busy;

    B_RX_secretkey_length_fifo B_A2B_secretkey_length_fifo (
        .srst(~rst_n), // input wire srst

        .wr_clk(B_RX_secretkey_length_wr_clk), // input wire wr_clk
        .din(B_RX_secretkey_length_wr_din), // input wire [31 : 0] din
        .wr_en(B_RX_secretkey_length_wr_en), // input wire wr_en
        .full(B_RX_secretkey_length_full), // output wire full
        .wr_ack(B_RX_secretkey_length_wr_ack), // output wire wr_ack

        .rd_clk(B_RX_secretkey_length_rd_clk), // input wire rd_clk
        .rd_en(B_RX_secretkey_length_rd_en), // input wire rd_en
        .dout(B_RX_secretkey_length_rd_dout), // output wire [31 : 0] dout
        .empty(B_RX_secretkey_length_empty), // output wire empty
        .valid(B_RX_secretkey_length_rd_valid), // output wire valid

        .wr_rst_busy(B_RX_secretkey_length_wr_rst_busy), // output wire wr_rst_busy
        .rd_rst_busy(B_RX_secretkey_length_rd_rst_busy) // output wire rd_rst_busy
    );
    //****************************** B RX secretkey length fifo ******************************

    //****************************** B pa ******************************

    top_B_pa top_Bpa (
        .clk(clk),
        .rst_n(rst_n),
        .start_B_pa(start_pa),

        .PArandombit_full(PArandombit_full),
        .reset_pa_parameter(B_reset_pa_parameter),

        .B_pa_finish(B_pa_finish),
        .B_pa_fail(B_pa_fail),

        .reconciled_key_addr_index(reconciled_key_addr_index),

        .B_RX_secretkey_length_rd_clk(B_RX_secretkey_length_rd_clk),
        .B_RX_secretkey_length_rd_en(B_RX_secretkey_length_rd_en),
        .B_RX_secretkey_length_rd_dout(B_RX_secretkey_length_rd_dout),
        .B_RX_secretkey_length_empty(B_RX_secretkey_length_empty),
        .B_RX_secretkey_length_rd_valid(B_RX_secretkey_length_rd_valid),


        .key_doutb(B_key_dout),
        .key_clkb(B_key_clk),
        .key_enb(B_key_en),
        .key_web(B_key_we),
        .key_rstb(B_key_rst),
        .key_index_and_addrb(B_key_index_and_addr),

        .Secretkey_addrb(B_Secretkey_addrb),
        .Secretkey_clkb(B_Secretkey_clkb),
        .Secretkey_dinb(B_Secretkey_dinb),
        .Secretkey_enb(B_Secretkey_enb),
        .Secretkey_rstb(B_Secretkey_rstb),
        .Secretkey_web(B_Secretkey_web),

        .PArandombit_doutb(B_PArandombit_doutb),
        .PArandombit_addrb(B_PArandombit_addrb),
        .PArandombit_clkb(B_PArandombit_clkb),
        .PArandombit_enb(B_PArandombit_enb),
        .PArandombit_rstb(B_PArandombit_rstb),
        .PArandombit_web(B_PArandombit_web)
    );

    //****************************** B pa ******************************

    //****************************** B unpacket  ******************************

    // Input
    // wire clk;
    // wire rst_n;
    wire B2A_busy_Net2PP_RX;
    wire B2A_msg_accessed;
    wire [10:0] B2A_sizeRX_msg;
    wire reset_er_parameter;
    wire reset_pa_parameter;

    // Output
    wire B2A_busy_PP2Net_RX;
    wire EVrandombit_full;
    wire PArandombit_full;
    wire [3:0] B_unpacket_state;

    // FIFO, BRAM, and other connections
    wire B_RX_Zbasis_decoy_wr_clk;
    wire [31:0] B_RX_Zbasis_decoy_wr_din;
    wire B_RX_Zbasis_decoy_wr_en;
    wire B_RX_Zbasis_decoy_full;
    assign B_RX_Zbasis_decoy_full = 1'b0;
    wire B_RX_Zbasis_decoy_wr_ack;

    wire B_RX_er_wr_clk;
    wire [31:0] B_RX_er_wr_din;
    wire B_RX_er_wr_en;
    wire B_RX_er_full;
    assign B_RX_er_full = 1'b0;
    wire B_RX_er_wr_ack;

    wire [63:0] B_RX_EVrandombit_dina;
    wire [13:0] B_RX_EVrandombit_addra;
    wire B_RX_EVrandombit_clka;
    wire B_RX_EVrandombit_ena;
    wire B_RX_EVrandombit_wea;

    // wire B_RX_secretkey_length_wr_clk;
    // wire [31:0] B_RX_secretkey_length_wr_din;
    // wire B_RX_secretkey_length_wr_en;
    // wire B_RX_secretkey_length_full;
    // wire B_RX_secretkey_length_wr_ack;

    // reg [63:0] B_RX_PArandombit_dina;
    // reg [13:0] B_RX_PArandombit_addra;
    // wire B_RX_PArandombit_clka;
    // wire B_RX_PArandombit_ena;
    // reg B_RX_PArandombit_wea;

    wire B_RX_bram_clkb;
    wire B_RX_bram_enb;
    wire B_RX_bram_web;
    wire [10:0] B_RX_bram_addrb;
    wire [31:0] B_RX_bram_doutb;


    B_unpacket Bunpacket (
        .clk(clkRX_msg), // Clock signal
        .rst_n(rst_n), // Reset signal

        .busy_Net2PP_RX(B2A_busy_Net2PP_RX), // Input indicating the network to post-processing reception is busy
        .msg_accessed(B2A_msg_accessed), // Input indicating message access
        .sizeRX_msg(B2A_sizeRX_msg), // Input for size of RX message

        .busy_PP2Net_RX(B2A_busy_PP2Net_RX), // Output indicating post-processing to network reception is busy

        .reset_er_parameter(reset_er_parameter), // Input to reset error reconciliation parameter
        .EVrandombit_full(EVrandombit_full), // Output indicating EV random bit buffer is full

        .reset_pa_parameter(B_reset_pa_parameter), // Input to reset post-authentication parameter
        .PArandombit_full(PArandombit_full), // Output indicating PA random bit buffer is full

        .B_unpacket_state(B_unpacket_state), // Output state of the B_unpacket FSM

        // B_A2B decoy fifo connections
        .B_RX_Zbasis_decoy_wr_clk(B_RX_Zbasis_decoy_wr_clk),
        .B_RX_Zbasis_decoy_wr_din(B_RX_Zbasis_decoy_wr_din),
        .B_RX_Zbasis_decoy_wr_en(B_RX_Zbasis_decoy_wr_en),
        .B_RX_Zbasis_decoy_full(B_RX_Zbasis_decoy_full),
        .B_RX_Zbasis_decoy_wr_ack(B_RX_Zbasis_decoy_wr_ack),

        // B_A2B ER fifo connections
        .B_RX_er_wr_clk(B_RX_er_wr_clk),
        .B_RX_er_wr_din(B_RX_er_wr_din),
        .B_RX_er_wr_en(B_RX_er_wr_en),
        .B_RX_er_full(B_RX_er_full),
        .B_RX_er_wr_ack(B_RX_er_wr_ack),

        // B_A2B EV random bit bram connections
        .B_RX_EVrandombit_dina(B_RX_EVrandombit_dina),
        .B_RX_EVrandombit_addra(B_RX_EVrandombit_addra),
        .B_RX_EVrandombit_clka(B_RX_EVrandombit_clka),
        .B_RX_EVrandombit_ena(B_RX_EVrandombit_ena),
        .B_RX_EVrandombit_wea(B_RX_EVrandombit_wea),

        // B_A2B secret key length fifo connections
        .B_RX_secretkey_length_wr_clk(B_RX_secretkey_length_wr_clk),
        .B_RX_secretkey_length_wr_din(B_RX_secretkey_length_wr_din),
        .B_RX_secretkey_length_wr_en(B_RX_secretkey_length_wr_en),
        .B_RX_secretkey_length_full(B_RX_secretkey_length_full),
        .B_RX_secretkey_length_wr_ack(B_RX_secretkey_length_wr_ack),

        // B_A2B PA randombit bram connections
        .B_RX_PArandombit_dina(B_RX_PArandombit_dina),
        .B_RX_PArandombit_addra(B_RX_PArandombit_addra),
        .B_RX_PArandombit_clka(B_RX_PArandombit_clka),
        .B_RX_PArandombit_ena(B_RX_PArandombit_ena),
        .B_RX_PArandombit_wea(B_RX_PArandombit_wea),

        // RX BRAM connections
        .B_RX_bram_clkb(B_RX_bram_clkb),
        .B_RX_bram_enb(B_RX_bram_enb),
        .B_RX_bram_web(B_RX_bram_web),
        .B_RX_bram_addrb(B_RX_bram_addrb),
        .B_RX_bram_doutb(B_RX_bram_doutb)
    );

    //****************************** B unpacket  ******************************

//****************************** B2A BRAM instantiation ******************************
    
    B2A_BRAM B2Abram_RX (
        .clka(clkRX_msg), // input wire clka
        .ena(1'b1), // input wire ena
        .wea(B2A_weRX_msg), // input wire [0 : 0] wea
        .addra(B2A_addrRX_msg), // input wire [10 : 0] addra
        .dina(B2A_dataRX_msg), // input wire [31 : 0] dina
        .douta(), // output wire [31 : 0] douta

        .clkb(B_RX_bram_clkb), // input wire clkb
        .enb(B_RX_bram_enb), // input wire enb
        .web(B_RX_bram_web), // input wire [0 : 0] web
        .addrb(B_RX_bram_addrb), // input wire [10 : 0] addrb
        .dinb(), // input wire [31 : 0] dinb
        .doutb(B_RX_bram_doutb) // output wire [31 : 0] doutb
    );
//****************************** B2A BRAM instantiation ******************************
    //------------------------------------Network module of B------------------------
    wire clkTX_msg;
    wire clkRX_msg;

    wire [31:0] B2A_dataTX_msg; // message from PP 
    wire [10:0] B2A_addrTX_msg; // addr for BRAMMsgTX
    wire [10:0] B2A_sizeTX_msg; // transmitting message size

    wire [31:0] B2A_dataRX_msg; // message pasrsed from Ethernet frame
    wire [10:0] B2A_addrRX_msg; // addr for BRAMMSGRX
    wire B2A_weRX_msg; // write enable for BRAMMsgRX
    wire [10:0] B2A_sizeRX_msg; // receoved message size

    wire  [7:0] gmii_txd; // Transmit data from client MAC.
    wire  gmii_tx_en; // Transmit control signal from client MAC.
    wire  gmii_tx_er; // Transmit control signal from client MAC.

    wire [7:0]     gmii_rxd; // Received Data to client MAC.d
    wire           gmii_rx_dv; // Received control signal to client MAC.
    wire           gmii_rx_er;


    // test signal 
    wire [3:0] network_fsm_TCP_B_TX;
    wire [2:0] transfer_fsm_B_TX;
    wire [2:0] network_fsm_TX_B_TX;
    wire [1:0] network_fsm_RX_B_TX;

    wire start_handle_FrameSniffer_B_TX;

    wire received_valid_B_TX;
    wire need_ack_B_TX;
    wire is_handshake_B_TX;
    wire transfer_en_B_TX;
    wire busy_TX2CentCtrl_B_TX;
    wire transfer_finish_B_TX;
    wire [10:0] index_frame_FrameGenerator_B_TX;
    wire [7:0] frame_data_FrameGenerator_B_TX;
    wire [15:0] total_len_TCP_FrameGenerator_B_TX;
    wire [63:0] douta_FrameGenerator_B_TX;
    wire [7:0] keep_crc32_FrameGenerator_B_TX;
    wire crc32_valid_FrameGenerator_B_TX;
    wire ack_received_B_TX;
    wire ack_received_cdc_after_FrameGenerator_B_TX;
    wire [15:0] sizeTX_msg_buf_FrameGenerator_B_TX;
    wire [15:0] base_addr_tmp_FrameGenerator_B_TX;
    wire [10:0] addr_gmii_FrameSniffer_B_TX;
    wire [15:0] tcp_segment_len_FrameSniffer_B_TX;
    wire [63:0] packet_in_crc32_FrameSniffer_B_TX;
    wire [7:0] keep_crc32_FrameSniffer_B_TX;
    wire [31:0] crc32_out_FrameSniffer_B_TX;
    wire [31:0] seq_RX_B_TX;
    wire [31:0] ack_RX_B_TX;
    wire [25:0] lost_B_TX;
    wire [19:0] tcp_chksum_FrameSniffer_B_TX;
    wire [19:0] network_chksum_FrameSniffer_B_TX;
    wire [31:0] FCS_received_FrameSniffer_B_TX;
    wire packet_valid_FrameSniffer_B_TX;
    wire msg_accessed_en_FrameSniffer_B_TX;
    //    wire lost_cnt_en;
    //------------------------------------Network module of B------------------------
    networkCentCtrl_B #(
    .lost_cycle(26'd30),
    .phy_reset_wait(26'd20)
    ) Unetwork_B2A(
        .reset(~rst_n), // system reset
        //        .clock_100M(clk_100M),            // clock for JTAG module 
        .clk_PP(clk_PP),
        .clkTX_msg(clkTX_msg), // clock for accessing BRAMMsgTX
        .clkRX_msg(clkRX_msg), // clock for accessing BRAMMsgRX

        // Post Processing interface
        //------------------------------------
        .busy_PP2Net_TX(B2A_busy_PP2Net_TX), // BRAMMsgTX is used by PP
        .busy_Net2PP_TX(B2A_busy_Net2PP_TX), // BRAMMsgTX is used by NetworkCentCtrl
        .msg_stored(B2A_msg_stored), // msg is stored in BRAMMsgTX by PP 

        .busy_PP2Net_RX(B2A_busy_PP2Net_RX), // BRAMMsgRX is used by PP
        .busy_Net2PP_RX(B2A_busy_Net2PP_RX), // BRAMMsgRX is used by networkCentCtrl
        .msg_accessed(B2A_msg_accessed), // msg is stored in BRAMMsgTX by networkCentCtrl

        .dataTX_msg(B2A_dataTX_msg), // message from PP 
        .addrTX_msg(B2A_addrTX_msg), // addr for BRAMMsgTX
        .sizeTX_msg(B2A_sizeTX_msg), // transmitting message size

        .dataRX_msg(B2A_dataRX_msg), // message pasrsed from Ethernet frame
        .weRX_msg(B2A_weRX_msg), // write enable for BRAMMsgRX
        .addrRX_msg(B2A_addrRX_msg), // addr for BRAMMSGRX
        .sizeRX_msg(B2A_sizeRX_msg), // receoved message size

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
        .network_fsm_TCP(network_fsm_TCP_B_TX),
        .transfer_fsm(transfer_fsm_B_TX),
        .network_fsm_TX(network_fsm_TX_B_TX),
        .network_fsm_RX(network_fsm_RX_B_TX),
        .start_handle_FrameSniffer(start_handle_FrameSniffer_B_TX),
        .received_valid(received_valid_B_TX),
        .need_ack(need_ack_B_TX),
        .is_handshake(is_handshake_B_TX),
        .transfer_finish(transfer_finish_B_TX),
        .transfer_en(transfer_en_B_TX),
        .busy_TX2CentCtrl(busy_TX2CentCtrl_B_TX),
        .index_frame_FrameGenerator(index_frame_FrameGenerator_B_TX),
        .frame_data_FrameGenerator(frame_data_FrameGenerator_B_TX),
        .total_len_TCP_FrameGenerator(total_len_TCP_FrameGenerator_B_TX),
        .douta_FrameGenerator(douta_FrameGenerator_B_TX),
        .keep_crc32_FrameGenerator(keep_crc32_FrameGenerator_B_TX),
        .crc32_valid_FrameGenerator(crc32_valid_FrameGenerator_B_TX),
        .ack_received_cdc_after_FrameGenerator(ack_received_cdc_after_FrameGenerator_B_TX),
        .ack_received(ack_received_B_TX),
        .sizeTX_msg_buf_FrameGenerator(sizeTX_msg_buf_FrameGenerator_B_TX),
        .base_addr_tmp_FrameGenerator(base_addr_tmp_FrameGenerator_B_TX),
        .addr_gmii_FrameSniffer(addr_gmii_FrameSniffer_B_TX),
        .tcp_segment_len_FrameSniffer(tcp_segment_len_FrameSniffer_B_TX),
        .packet_in_crc32_FrameSniffer(packet_in_crc32_FrameSniffer_B_TX),
        .keep_crc32_FrameSniffer(keep_crc32_FrameSniffer_B_TX),
        .crc32_out_FrameSniffer(crc32_out_FrameSniffer_B_TX),
        .seq_RX(seq_RX_B_TX),
        .ack_RX(ack_RX_B_TX),
        .lost(lost_B_TX),
        .FCS_received_FrameSniffer(FCS_received_FrameSniffer_B_TX),
        .packet_valid_FrameSniffer(packet_valid_FrameSniffer_B_TX),
        .tcp_chksum_FrameSniffer(tcp_chksum_FrameSniffer_B_TX),
        .network_chksum_FrameSniffer(network_chksum_FrameSniffer_B_TX),
        .msg_accessed_en_FrameSniffer(msg_accessed_en_FrameSniffer_B_TX)
        //        .lost_cnt_en(lost_cnt_en)
    );
    //------------------------------------Network module of B------------------------

    wire B2A_busy_PP2Net_TX;
    assign B2A_busy_PP2Net_TX = 1'b0;
endmodule