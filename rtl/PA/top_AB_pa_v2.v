





`timescale 1ns/100ps


`include "./pa_parameter.v"




module top_AB_pa (
    input clk,
    input rst_n,

    input start_switch,

    input [31:0] secretkey_length,   //secret key length
    input reconciled_key_addr_index,                        //address index
                                                            //0:addr0 ~ addr16383
                                                            //1:addr16384 ~ addr32767


    // Alice secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]A_Secretkey_addrb,   //0~32767
    output wire A_Secretkey_clkb,      
    output wire [63:0]A_Secretkey_dinb,
    output wire A_Secretkey_enb,           //1'b1
    output wire A_Secretkey_rstb,          //1'b0
    output wire [7:0]A_Secretkey_web,  

    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]B_Secretkey_addrb,   //0~32767
    output wire B_Secretkey_clkb,      
    output wire [63:0]B_Secretkey_dinb,
    output wire B_Secretkey_enb,           //1'b1
    output wire B_Secretkey_rstb,          //1'b0
    output wire [7:0]B_Secretkey_web,      


    output A_pa_finish,                     //pa is done
    output A_pa_fail,                       //pa is fail due to error secret key length

    output B_pa_finish,                     //pa is done
    output B_pa_fail,                       //pa is fail due to error secret key length

    output B_reset_pa_parameter               //

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
        .clka(A_key_clk),    // input wire clka
        .ena(A_key_en),      // input wire ena
        .wea(A_key_we),      // input wire [0 : 0] wea
        .addra(A_key_index_and_addr),  // input wire [14 : 0] addra
        .dina(),    // input wire [63 : 0] dina
        .douta(A_key_dout),  // output wire [63 : 0] douta

        .clkb(B_key_clk),    // input wire clkb
        .enb(B_key_en),      // input wire enb
        .web(B_key_we),      // input wire [0 : 0] web
        .addrb(B_key_index_and_addr),  // input wire [14 : 0] addrb
        .dinb(),    // input wire [63 : 0] dinb
        .doutb(B_key_dout)  // output wire [63 : 0] doutb
    );
//****************************** key BRAM instantiation ******************************













//****************************** A random bit BRAM instantiation ******************************
    wire [63:0] A_PArandombit_doutb;
    wire [13:0] A_PArandombit_addrb;    //0~16383
    wire A_PArandombit_clkb;
    wire A_PArandombit_enb;            //1'b1
    wire A_PArandombit_rstb;           //1'b0
    wire [7:0] A_PArandombit_web;       //8'b0


    A_randombit_BRAM A_init_randombit (
        .clka(),    // input wire clka
        .ena(1'b0),      // input wire ena
        .wea(1'b0),      // input wire [0 : 0] wea
        .addra(),  // input wire [13 : 0] addra
        .dina(),    // input wire [63 : 0] dina
        .douta(),  // output wire [63 : 0] douta

        .clkb(A_PArandombit_clkb),    // input wire clkb
        .enb(A_PArandombit_enb),      // input wire enb
        .web((|A_PArandombit_web)),      // input wire [0 : 0] web
        .addrb(A_PArandombit_addrb),  // input wire [13 : 0] addrb
        .dinb(),    // input wire [63 : 0] dinb
        .doutb(A_PArandombit_doutb)  // output wire [63 : 0] doutb
    );
//****************************** A random bit BRAM instantiation ******************************

//****************************** B random bit BRAM instantiation ******************************
    wire [63:0]B_PArandombit_doutb;
    wire [13:0]B_PArandombit_addrb;    //0~16383
    wire B_PArandombit_clkb;
    wire B_PArandombit_enb;            //1'b1
    wire B_PArandombit_rstb;           //1'b0
    wire [7:0]B_PArandombit_web;       //8'b0


    wire [63:0] B_RX_PArandombit_dina;
    //wire [63:0] B_RX_PArandombit_dout;
    wire [13:0] B_RX_PArandombit_addra;    //0~16383
    wire B_RX_PArandombit_clka;
    wire B_RX_PArandombit_ena;            //1'b1
    wire B_RX_PArandombit_wea;       


    B_RX_PArandombit_BRAM B_A2B_randombit_bram (
        .clka(B_RX_PArandombit_clka),    // input wire clka
        .ena(B_RX_PArandombit_ena),      // input wire ena
        .wea(B_RX_PArandombit_wea),      // input wire [0 : 0] wea
        .addra(B_RX_PArandombit_addra),  // input wire [13 : 0] addra
        .dina(B_RX_PArandombit_dina),    // input wire [63 : 0] dina
        .douta(),  // output wire [63 : 0] douta

        .clkb(B_PArandombit_clkb),    // input wire clkb
        .enb(B_PArandombit_enb),      // input wire enb
        .web((|B_PArandombit_web)),      // input wire [0 : 0] web
        .addrb(B_PArandombit_addrb),  // input wire [13 : 0] addrb
        .dinb(),    // input wire [63 : 0] dinb
        .doutb(B_PArandombit_doutb)  // output wire [63 : 0] doutb
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
        .srst(~rst_n),                // input wire srst

        .wr_clk(B_RX_secretkey_length_wr_clk),            // input wire wr_clk
        .din(B_RX_secretkey_length_wr_din),                  // input wire [31 : 0] din
        .wr_en(B_RX_secretkey_length_wr_en),              // input wire wr_en
        .full(B_RX_secretkey_length_full),                // output wire full
        .wr_ack(B_RX_secretkey_length_wr_ack),            // output wire wr_ack

        .rd_clk(B_RX_secretkey_length_rd_clk),            // input wire rd_clk
        .rd_en(B_RX_secretkey_length_rd_en),              // input wire rd_en
        .dout(B_RX_secretkey_length_rd_dout),                // output wire [31 : 0] dout
        .empty(B_RX_secretkey_length_empty),              // output wire empty
        .valid(B_RX_secretkey_length_rd_valid),              // output wire valid

        .wr_rst_busy(B_RX_secretkey_length_wr_rst_busy),  // output wire wr_rst_busy
        .rd_rst_busy(B_RX_secretkey_length_rd_rst_busy)  // output wire rd_rst_busy
    );
//****************************** B RX secretkey length fifo ******************************

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
        .srst(~rst_n),                // input wire srst

        .wr_clk(A_TX_pa_wr_clk),            // input wire wr_clk
        .din(A_TX_pa_wr_din),                  // input wire [31 : 0] din
        .wr_en(A_TX_pa_wr_en),              // input wire wr_en
        .full(A_TX_pa_full),                // output wire full
        .wr_ack(A_TX_pa_wr_ack),            // output wire wr_ack

        .rd_clk(A_TX_pa_rd_clk),            // input wire rd_clk
        .rd_en(A_TX_pa_rd_en),              // input wire rd_en
        .dout(A_TX_pa_rd_dout),                // output wire [31 : 0] dout
        .empty(A_TX_pa_empty),              // output wire empty
        .valid(A_TX_pa_rd_valid),              // output wire valid

        .wr_rst_busy(A_TX_pa_wr_rst_busy),  // output wire wr_rst_busy
        .rd_rst_busy(A_TX_pa_rd_rst_busy)  // output wire rd_rst_busy
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





// //****************************** A2B test instantiation ******************************

//     wire [3:0] A2B_state;

//     A2B_test A2Btest (
//         .clk(clk),
//         .rst_n(rst_n),

//         .reset_pa_parameter(B_reset_pa_parameter),
//         .PArandombit_full(PArandombit_full),

//         .A_TX_pa_rd_clk(A_TX_pa_rd_clk),
//         .A_TX_pa_rd_en(A_TX_pa_rd_en),
//         .A_TX_pa_rd_dout(A_TX_pa_rd_dout),
//         .A_TX_pa_empty(A_TX_pa_empty),
//         .A_TX_pa_rd_valid(A_TX_pa_rd_valid),

//         .B_RX_secretkey_length_wr_clk(B_RX_secretkey_length_wr_clk),
//         .B_RX_secretkey_length_wr_din(B_RX_secretkey_length_wr_din),
//         .B_RX_secretkey_length_wr_en(B_RX_secretkey_length_wr_en),
//         .B_RX_secretkey_length_full(B_RX_secretkey_length_full),
//         .B_RX_secretkey_length_wr_ack(B_RX_secretkey_length_wr_ack),

//         .B_RX_PArandombit_din(B_RX_PArandombit_din),
//         .B_RX_PArandombit_addr(B_RX_PArandombit_addr),
//         .B_RX_PArandombit_clk(B_RX_PArandombit_clk),
//         .B_RX_PArandombit_en(B_RX_PArandombit_en),
//         .B_RX_PArandombit_we(B_RX_PArandombit_we),

//         .A2B_state(A2B_state)
//     );
// //****************************** A2B test instantiation ******************************



//****************************** A packet  ******************************
    // Input 
    // wire clk;
    // wire rst_n;
    wire busy_Net2PP_TX;


    // Output 
    wire busy_PP2Net_TX;
    wire msg_stored;
    wire [10:0] sizeTX_msg; // Assuming this should be a register based on your module definition

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
        .clk(clk),                            // Clock signal
        .rst_n(rst_n),                        // Reset signal

        .busy_Net2PP_TX(busy_Net2PP_TX),      // Input indicating the network to post-processing transmission is busy

        .busy_PP2Net_TX(busy_PP2Net_TX),      // Output indicating post-processing to network transmission is busy
        .msg_stored(msg_stored),              // Output indicating message is stored
        .sizeTX_msg(sizeTX_msg),              // Output register for message size

        .A_packet_state(A_packet_state),      // Output state of the A_packet FSM

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



//****************************** B unpacket  ******************************

    // Input
    // wire clk;
    // wire rst_n;
    wire busy_Net2PP_RX;
    wire msg_accessed;
    wire [10:0] sizeRX_msg;
    wire reset_er_parameter;
    wire reset_pa_parameter;

    // Output
    wire busy_PP2Net_RX;
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
        .clk(clk),                                       // Clock signal
        .rst_n(rst_n),                                   // Reset signal

        .busy_Net2PP_RX(busy_Net2PP_RX),                 // Input indicating the network to post-processing reception is busy
        .msg_accessed(msg_accessed),                     // Input indicating message access
        .sizeRX_msg(sizeRX_msg),                         // Input for size of RX message

        .busy_PP2Net_RX(busy_PP2Net_RX),                 // Output indicating post-processing to network reception is busy

        .reset_er_parameter(reset_er_parameter),         // Input to reset error reconciliation parameter
        .EVrandombit_full(EVrandombit_full),             // Output indicating EV random bit buffer is full

        .reset_pa_parameter(B_reset_pa_parameter),         // Input to reset post-authentication parameter
        .PArandombit_full(PArandombit_full),             // Output indicating PA random bit buffer is full

        .B_unpacket_state(B_unpacket_state),             // Output state of the B_unpacket FSM

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



//****************************** A2B BRAM instantiation ******************************
    
    A2B_BRAM A2Bbram (
        .clka(A_TX_bram_clkb),    // input wire clka
        .ena(A_TX_bram_enb),      // input wire ena
        .wea(A_TX_bram_web),      // input wire [0 : 0] wea
        .addra(A_TX_bram_addrb),  // input wire [10 : 0] addra
        .dina(A_TX_bram_dinb),    // input wire [31 : 0] dina
        .douta(),  // output wire [31 : 0] douta


        .clkb(B_RX_bram_clkb),    // input wire clkb
        .enb(B_RX_bram_enb),      // input wire enb
        .web(B_RX_bram_web),      // input wire [0 : 0] web
        .addrb(B_RX_bram_addrb),  // input wire [10 : 0] addrb
        .dinb(),    // input wire [31 : 0] dinb
        .doutb(B_RX_bram_doutb)  // output wire [31 : 0] doutb
    );

//****************************** A2B BRAM instantiation ******************************



//****************************** A2B model  ******************************
    // Input 
    // wire clk;
    // wire rst_n;
    // wire busy_PP2Net_TX;
    // wire msg_stored;
    // wire [10:0] sizeTX_msg;
    // wire busy_PP2Net_RX;

    // // Output 
    // wire busy_Net2PP_TX;
    // wire busy_Net2PP_RX;
    // wire msg_accessed;
    // wire [10:0] sizeRX_msg; 
    wire [3:0] A2B_state;

    TXRX_model A2Bmodel (
        .clk(clk),                       // Clock signal
        .rst_n(rst_n),                   // Reset signal

        .busy_Net2PP_TX(busy_Net2PP_TX), // Output indicating the network to post-processing transmission is busy

        .busy_PP2Net_TX(busy_PP2Net_TX), // Input indicating post-processing to network transmission is busy
        .msg_stored(msg_stored),         // Input indicating message is stored
        .sizeTX_msg(sizeTX_msg),         // Input for size of TX message

        .busy_PP2Net_RX(busy_PP2Net_RX), // Input indicating post-processing to network reception is busy

        .busy_Net2PP_RX(busy_Net2PP_RX), // Output indicating the network to post-processing reception is busy
        .msg_accessed(msg_accessed),     // Output indicating message access
        .sizeRX_msg(sizeRX_msg),         // Output register for size of RX message

        .state(A2B_state)            // Output state of the A2B model FSM
    );

//****************************** A2B model  ******************************


endmodule