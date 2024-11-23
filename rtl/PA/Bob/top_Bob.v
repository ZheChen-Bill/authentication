`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/17 21:28:48
// Design Name: 
// Module Name: top_Bob
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_Bob(

    // global reset 
    input reset,

    // system clock -- 300M Hz
    input clk_300M_n,
    input clk_300M_p,

    // GT reference clock for PHY module
    input gtrefclk_p,
    input gtrefclk_n,
    // TX and RX port for connecting SFP
    output txp,
    output txn,
    input rxp,
    input rxn,
    // TX enable signal connecting to SFP module 
    output tx_disable,

    input start_switch,

    input start_TX,

    //    input start_RX,

    output reg output_clk,
    input independent_clk_en,
    input io_refclk_en,
    input gmii_rx_clk_en,
    output [7:0] tcp_status

);

    always @* begin
        output_clk = 1'b0;
        if (independent_clk_en) begin
            output_clk = independent_clk;
        end else if (io_refclk_en) begin
            output_clk = io_refclk;
        end else if (gmii_rx_clk_en) begin
            output_clk = gmii_rx_clk;
        end
    end
    wire independent_clk;
    wire io_refclk;

    wire txn, txp, rxn, rxp;
    wire gmii_rx_clk, gmii_tx_clk;
    wire clock_100M;
    //    wire clock_80M;
    wire clock_125M;

    (*mark_debug = "TRUE"*) wire [7:0]gmii_txd; // Transmit data from client MAC.
    (*mark_debug = "TRUE"*) wire gmii_tx_en; // Transmit control signal from client MAC.
    (*mark_debug = "TRUE"*) wire gmii_tx_er; // Transmit control signal from client MAC.
    (*mark_debug = "TRUE"*) wire [7:0]gmii_rxd; // Received Data to client MAC.
    (*mark_debug = "TRUE"*) wire gmii_rx_dv; // Received control signal to client MAC.
    (*mark_debug = "TRUE"*) wire gmii_rx_er; // Received control signal to client MAC.

//    wire [7:0]gmii_txd; // Transmit data from client MAC.
//    wire gmii_tx_en; // Transmit control signal from client MAC.
//    wire gmii_tx_er; // Transmit control signal from client MAC.
//    wire [7:0]gmii_rxd; // Received Data to client MAC.
//    wire gmii_rx_dv; // Received control signal to client MAC.
//    wire gmii_rx_er; // Received control signal to client MAC.

    wire [15:0] status_vector;
    wire B_pa_finish;
    reg B_pa_finish_reg;
    wire B_pa_fail;
    reg B_pa_fail_reg;

    //    assign link_status = status_vector[0] & status_vector[1];
    assign link_status = status_vector[0];
    //    assign link_status = 1'b1;
    wire [3:0] network_fsm_TCP_TX;
    assign achieve = (network_fsm_TCP_TX == 4'd3)  ? 1'b1 : 1'b0; // network_fsm_TCP has reached TRANSFER_TCP state
    assign disconnect = (network_fsm_TCP_TX == 4'd0)  ? 1'b1 : 1'b0;
    assign handshake0 = (network_fsm_TCP_TX == 4'd2)  ? 1'b1 : 1'b0;
    assign handshake1 = (network_fsm_TCP_TX == 4'd4)  ? 1'b1 : 1'b0;
    assign handshake = (network_fsm_TCP_TX == 4'd1)  ? 1'b1 : 1'b0;
    assign ack_t = (network_fsm_TCP_TX == 4'd6)  ? 1'b1 : 1'b0;
    assign ack_r = (network_fsm_TCP_TX == 4'd5)  ? 1'b1 : 1'b0;

    //                                          LED7      LED6               LED5          LED4                LED3    LED2        LED1                                 LED0
    //    assign tcp_status = {link_status, handshake0, handshake, handshake1, achieve, ack_t, B2A_busy_Net2PP_RX, B2A_busy_Net2PP_TX};

    //                               LED7      LED6               LED5                             LED4               LED3          LED2        LED1              LED0
    assign tcp_status = {link_status, achieve, B2A_busy_Net2PP_RX, B2A_busy_Net2PP_TX, start_switch,  1'b0 ,  B_pa_fail_reg, B_pa_finish_reg};

    //                                          LED7      LED6               LED5                             LED4                             LED3                LED2              LED1          LED0
    //    assign tcp_status = {link_status, achieve, B2A_busy_Net2PP_RX, B2A_busy_Net2PP_TX, start_switch, sift_state_4, sift_state_5, sift_state_6};

    wire [3:0] B_sift_state;
    //    assign sift_state_4 = (B_sift_state == 4'd4)  ? 1'b1 : 1'b0;
    //    assign sift_state_5 = (B_sift_state == 4'd5)  ? 1'b1 : 1'b0;
    //    assign sift_state_6 = (B_sift_state == 4'd6)  ? 1'b1 : 1'b0;

    assign tx_disable = 1'b1;

    clock_generator Uclk_gen
    (.clk_in1_n(clk_300M_n), // input
        .clk_in1_p(clk_300M_p), // input
        .clk_out1_62_5M(independent_clk), // output
        .clk_out2_100M(clock_100M), // output
        .clk_out3_300M(io_refclk), // output
        .clk_out4_375M(clk_fast), // output
        //        .clk_out5_125M(clock_125M), // output

        .reset(reset) // input
    );

    top_phy Utop_phy //for Bob is TX, for Alice is RX
    (

        .independent_clock(independent_clk),
        .io_refclk(io_refclk),

        // Tranceiver Interface
        //---------------------
        .gtrefclk_p(gtrefclk_p), // Differential +ve of reference clock for MGT: very high quality.
        .gtrefclk_n(gtrefclk_n), // Differential -ve of reference clock for MGT: very high quality.
        .txp(txp), // Differential +ve of serial transmission from PMA to PMD.
        .txn(txn), // Differential -ve of serial transmission from PMA to PMD.
        .rxp(rxp), // Differential +ve for serial reception from PMD to PMA.
        .rxn(rxn), // Differential -ve for serial reception from PMD to PMA.

        // GMII Interface (client MAC <=> PCS)
        //------------------------------------
        .gmii_tx_clk(gmii_tx_clk), // Transmit clock from client MAC.
        .gmii_rx_clk(gmii_rx_clk), // Receive clock to client MAC.
        .gmii_txd(gmii_txd), // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en), // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er), // Transmit control signal from client MAC.
        .gmii_rxd(gmii_rxd), // Received Data to client MAC.
        .gmii_rx_dv(gmii_rx_dv), // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er), // Received control signal to client MAC.
        // Management: Alternative to MDIO Interface
        //------------------------------------------

        //    input [4:0]      configuration_vector,  // Alternative to MDIO interface.

        //    .an_interrupt(an_interrupt),          // Interrupt to processor to signal that Auto-Negotiation has completed
        //    input [15:0]     an_adv_config_vector,  // Alternate interface to program REG4 (AN ADV)
        //    input            an_restart_config,     // Alternate signal to modify AN restart bit in REG0


        // General IO's
        //-------------
        .status_vector(status_vector), // Core status.
        .reset(reset) // Asynchronous reset for entire core.
        //    input            signal_detect          // Input from PMD to indicate presence of optical input.
    );
    
    wire [14:0]B_Secretkey_addrb; //0~32767
    wire B_Secretkey_clkb;
    wire [63:0]B_Secretkey_dinb;
    wire B_Secretkey_enb; //1'b1
    wire B_Secretkey_rstb; //1'b0
    (*mark_debug = "TRUE"*) wire [7:0] B_Secretkey_web;

    Bob u_Bob(
    .clk(clock_100M),
    .rst_n(~reset),
    //----------------------------new add signal------------------------------
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_rx_clk(gmii_rx_clk),

    .clk_PP(clk_fast),
    .link_status(link_status),

    .B2A_busy_Net2PP_TX(B2A_busy_Net2PP_TX),
    .B2A_busy_Net2PP_RX(B2A_busy_Net2PP_RX),

    .gmii_txd(gmii_txd), // Transmit data from client MAC.
    .gmii_tx_en(gmii_tx_en), // Transmit control signal from client MAC.
    .gmii_tx_er(gmii_tx_er), // Transmit control signal from client MAC.
    .gmii_rxd(gmii_rxd), // Received Data to client MAC.
    .gmii_rx_dv(gmii_rx_dv), // Received control signal to client MAC.
    .gmii_rx_er(gmii_rx_er), // Received control signal to client MAC.

    .clkTX_msg(clkTX_msg),
    .clkRX_msg(clkRX_msg),
    
    .network_fsm_TCP_B_TX(network_fsm_TCP_TX),
    //----------------------------new add signal------------------------------
    .start_switch(start_switch),

    .secretkey_length(32'd4096), //secret key length
    .reconciled_key_addr_index(1'b0), //address index
    //0:addr0 ~ addr16383
    //1:addr16384 ~ addr32767

    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    .B_Secretkey_addrb(B_Secretkey_addrb), //0~32767
    .B_Secretkey_clkb(B_Secretkey_clkb),
    .B_Secretkey_dinb(B_Secretkey_dinb),
    .B_Secretkey_enb(B_Secretkey_enb), //1'b1
    .B_Secretkey_rstb(B_Secretkey_rstb), //1'b0
    .B_Secretkey_web(B_Secretkey_web),

    .B_pa_finish(B_pa_finish), //pa is done
    .B_pa_fail(B_pa_fail), //pa is fail due to error secret key length

    .B_reset_pa_parameter(B_reset_pa_parameter) //
    );

    always@(posedge clock_100M or posedge reset) begin
        if(reset) begin
            B_pa_finish_reg <= 1'b0;
        end else if (B_pa_finish) begin
            B_pa_finish_reg <= 1'b1;
        end else begin
            B_pa_finish_reg <= B_pa_finish_reg;
        end
    end
    always@(posedge clock_100M or posedge reset) begin
        if(reset) begin
            B_pa_fail_reg <= 1'b0;
        end else if (B_pa_fail) begin
            B_pa_fail_reg <= 1'b1;
        end else begin
            B_pa_fail_reg <= B_pa_fail_reg;
        end
    end
    //    //************************ Jtag for B siftkey bram***********************
JTAG_wrapper U_KEY (
    .BRAM_PORTB_0_addr({15'b0, B_Secretkey_addrb, 2'b0}),
    .BRAM_PORTB_0_clk(B_Secretkey_clkb),
    .BRAM_PORTB_0_din(B_Secretkey_dinb[63:32]),
    .BRAM_PORTB_0_dout(),
    .BRAM_PORTB_0_en(B_Secretkey_enb),
    .BRAM_PORTB_0_rst(reset),
    .BRAM_PORTB_0_we(B_Secretkey_web[7:4]),
    
    .BRAM_PORTB_1_addr({15'b0, B_Secretkey_addrb, 2'b0}),
    .BRAM_PORTB_1_clk(B_Secretkey_clkb),
    .BRAM_PORTB_1_din(B_Secretkey_dinb[31:0]),
    .BRAM_PORTB_1_dout(),
    .BRAM_PORTB_1_en(B_Secretkey_enb),
    .BRAM_PORTB_1_rst(reset),
    .BRAM_PORTB_1_we(B_Secretkey_web[3:0]),
    
    .clk_in_100M(clock_100M),
    .reset(reset)
);
    wire [7:0] ss_tdata_B2A;
    wire ss_tvalid_B2A;
    wire ss_tready_B2A;
    wire  awvalid_B2A;
    wire  awready_B2A;
    wire  [31:0] awaddr_B2A;
    
    wire  wvalid_B2A;
    wire  wready_B2A;
    wire  [63:0] wdata_B2A;

    wire   arvalid_B2A;
    wire  arready_B2A;
    wire  [31:0] araddr_B2A;
    
    wire rvalid_B2A;
    wire  rready_B2A;
    wire [63:0] rdata_B2A;
    
    (*mark_debug = "TRUE"*) wire [39:0] tag_B2A;    
    wire sm_tvalid_B2A;
    wire sm_tready_B2A;
    wire start_B2A;
    reg in_valid_B2A;
    always@* begin
        if ((gmii_tx_en) && (gmii_txd == 8'hd5)) begin
            in_valid_B2A = 1;
        end else if (gmii_tx_en) begin
            in_valid_B2A = in_valid_B2A;
        end else begin
            in_valid_B2A = 0;
        end
    end
    clock_domain_crossing start_signal_B2A(
        .clk_src(clock_100M), 
        .clk_des(gmii_tx_clk),
        .reset(reset),
        .pulse_src(B_pa_finish),
        .pulse_des(start_B2A)
    );
    top authentication_B2A(
        .clk(gmii_tx_clk),
        .rst_n(~reset),
        .start(start_B2A),
    
        .ss_tdata(gmii_txd),
        .ss_tvalid(in_valid_B2A),
        .ss_tready(ss_tready_B2A), 

        .awvalid(1'b0),    
        .awready(awready_B2A),
        .awaddr(32'h0000_0000),

        .wvalid(1'b0),
        .wready(wready_B2A),
        .wdata(32'h0000_0000),
        
        .arvalid(1'b0),
        .arready(arready_B2A),
        .araddr(32'h0000_0000),
        
        .rvalid(rvalid_B2A),
        .rready(1'b1),
        .rdata(rdata_B2A),   
    
        .sm_tdata(tag_B2A),
        .sm_tvalid(sm_tvalid_B2A),
        .sm_tready(1'b1)
    );

    wire [7:0] ss_tdata_A2B;
    wire ss_tvalid_A2B;
    wire ss_tready_A2B;
    wire  awvalid_A2B;
    wire  awready_A2B;
    wire  [31:0] awaddr_A2B;
    
    wire  wvalid_A2B;
    wire  wready_A2B;
    wire  [63:0] wdata_A2B;

    wire   arvalid_A2B;
    wire  arready_A2B;
    wire  [31:0] araddr_A2B;
    
    wire rvalid_A2B;
    wire  rready_A2B;
    wire [63:0] rdata_A2B;
    
    (*mark_debug = "TRUE"*) wire [39:0] tag_A2B;    
    wire sm_tvalid_A2B;
    wire sm_tready_A2B;
    
    wire start_A2B;
    reg in_valid_A2B;
    always@* begin
        if ((gmii_rx_dv) && (gmii_rxd == 8'hd5)) begin
            in_valid_A2B = 1;
        end else if (gmii_rx_dv) begin
            in_valid_A2B = in_valid_A2B;
        end else begin
            in_valid_A2B = 0;
        end
    end
    clock_domain_crossing start_signal_A2B(
        .clk_src(clock_100M), 
        .clk_des(gmii_rx_clk),
        .reset(reset),
        .pulse_src(B_pa_finish),
        .pulse_des(start_A2B)
    );
    top authentication_A2B(
        .clk(gmii_rx_clk),
        .rst_n(~reset),
        .start(start_A2B),
    
        .ss_tdata(gmii_rxd),
        .ss_tvalid(in_valid_A2B),
        .ss_tready(ss_tready_A2B), 

        .awvalid(1'b0),    
        .awready(awready),
        .awaddr(32'h0000_0000),

        .wvalid(1'b0),
        .wready(wready_A2B),
        .wdata(32'h0000_0000),
        
        .arvalid(1'b0),
        .arready(arready_A2B),
        .araddr(32'h0000_0000),
        
        .rvalid(rvalid_A2B),
        .rready(1'b1),
        .rdata(rdata_A2B),   
    
        .sm_tdata(tag_A2B),
        .sm_tvalid(sm_tvalid_A2B),
        .sm_tready(1'b1)
    );
    //    //************************ Jtag for B siftkey bram***********************
endmodule
