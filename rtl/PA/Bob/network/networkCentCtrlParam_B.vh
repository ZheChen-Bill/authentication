parameter DISTANCE = 2; // The delay cycle from addra to douta

`define IPV4 1 
`define TCP 1 

//parameter ALICE_B = 1'b1;    // If this circuit acts as Alice, set as 1
//`define Alice_B 1;

parameter ALICE_B = 1'b0; // (for Bob)
//`define Alice_B 1; //(for Bob)

//parameter LOST_CYCLE = 26'b00_1111_1111_1111_1111_1111_1111;
//parameter LOST_CYCLE = 26'd20;

// TCP Protocol
// for FSM_TCP
//                          handshake -> transfer                   ->      (If receive handshake from the other side)
// disconnect <                                                             disconnect
//                    handshake0 -> handshake1 -> transfer ->       (If receive message_valid)
parameter DISCONNECT_TCP = 4'b0000;
parameter HANDSHAKE_TCP = 4'b0001;

parameter HANDSHAKE0_TCP = 4'b0010;
parameter HANDSHAKE1_TCP = 4'b0110;

parameter WAIT_TCP = 4'b0100;

parameter TRANSFER_TCP = 4'b0011;
//parameter ACK_R_TCP = 4'b0111;
parameter ACK_T_TCP = 4'b0101;


// for FSM_TX
parameter IDLE_TX = 4'b0000;
parameter PRE_COMP_TX = 4'b0001;  
parameter LOAD_HEAD_TX = 4'b0011;
parameter COMPUTE_CRC_TX = 4'b0010;
parameter SEND_TX = 4'b0110;
parameter WAIT_LAST_TX = 4'b0111;
parameter TRANSITION_STATE1_TX = 4'b1111;
parameter TRANSITION_STATE2_TX = 4'b1110;
parameter TRANSITION_STATE3_TX = 4'b1100;
parameter TRANSITION_STATE4_TX = 4'b1000;
parameter DELAY_TX = 4'b0101;
parameter RESET_TX = 4'b0100;

// for FSM_RX 
parameter IDLE_RX = 4'b0000;
//    parameter WAIT_RX = 2'd3;
//parameter LOAD_RX = 2'd1;
parameter HANDLE_RX = 4'b0001;
parameter COMPUTE_CRC_RX = 4'b0011;
parameter WAIT_RX = 4'b0010;
parameter STORE_RX = 4'b0110;
parameter WAIT_ACK_RX = 4'b0111;
parameter TRANSITION_STATE1_RX = 4'b1111;
parameter TRANSITION_STATE2_RX = 4'b1110;
parameter TRANSITION_STATE3_RX = 4'b1100;
parameter TRANSITION_STATE4_RX = 4'b1000;

parameter INTER_PERIOD = 4'd9;

///// Ethernet frame settings
parameter LEN_PREAMABLE = 16'd6;            // = 6
parameter LEN_SFD = LEN_PREAMABLE + 1'b1;   // = 7

parameter [7:0] PREAMABLE = 8'h55;
parameter [7:0] START_FRAME_DELIMITER = 8'hd5;


///// Data link layer settings
parameter LEN_DES_MAC_ADDR = LEN_SFD + 16'd6;   // = 13
parameter LEN_SRC_MAC_ADDR = LEN_DES_MAC_ADDR + 16'd6;    // = 19
parameter LEN_TYPE = LEN_SRC_MAC_ADDR + 16'd2;         // = 21


//parameter SRC_MAC = 48'h04_42_1a_bc_d3_78;
//parameter DES_MAC = 48'h94_08_53_74_c6_6f;

`ifndef Alice_B 
    parameter [47:0] DES_MAC_TX_B = 48'hbc_22_28_3c_2a_2d;
    parameter [47:0] SRC_MAC_TX_B = 48'h94_08_53_74_c6_6f;
    
    parameter [47:0] DES_MAC_RX_B =  SRC_MAC_TX_B;     
    parameter [47:0] SRC_MAC_RX_B =  DES_MAC_TX_B;
`else 
    parameter [47:0] DES_MAC_TX_B = 48'h94_08_53_74_c6_6f;
    parameter [47:0] SRC_MAC_TX_B = 48'hbc_22_28_3c_2a_2d;
    
    parameter [47:0] DES_MAC_RX_B =  SRC_MAC_TX_B;     
    parameter [47:0] SRC_MAC_RX_B =  DES_MAC_TX_B;
`endif

`ifdef IPV4
parameter [15:0] TYPE = 16'h0800;
`elsif IPV6
parameter [15:0] TYPE = 16'h86dd;
`else
parameter [15:0] TYPE = 16'h0000;
`endif


///// Network layer settings
parameter LEN_VER_HEAD_LEN = LEN_TYPE + 16'd1; // including version and header length    // = 22
parameter LEN_SERVICE_TYPE = LEN_VER_HEAD_LEN + 16'd1; // = 23
parameter LEN_TOL_LEN = LEN_SERVICE_TYPE + 16'd2;   // = 25
parameter LEN_ID = LEN_TOL_LEN + 16'd2;     // = 27
parameter LEN_FLAG_OFFSET = LEN_ID + 16'd2;    // including flags and fragment offset       // = 29
parameter LEN_TTL = LEN_FLAG_OFFSET + 16'd1;   // time to live length       // = 30
parameter LEN_PROTOCOL = LEN_TTL + 1'b1;    // = 31
parameter LEN_HEADER_CHECK = LEN_PROTOCOL + 16'd2;  // = 33
parameter LEN_SRC_IP = LEN_HEADER_CHECK + 16'd4;    // = 37
parameter LEN_DES_IP = LEN_SRC_IP + 16'd4;  // = 41

`ifdef IPV4
parameter [3:0] VERSION = 4'b0100;
`else
parameter [3:0] VERSION = 4'b0000;
`endif
parameter [3:0] HEADER_LEN = 4'd5;    // header length = 5 indicates the network header is 5 * 32 = 160 bits = 20 bytes long. 
parameter [7:0] SERVICE_TYPE = 8'd0;

`ifndef Alice_B
    parameter [7:0] TIME_TO_LIVE_TX_B = 8'd128;     // The live time of this packet
`else
    parameter [7:0] TIME_TO_LIVE_TX_B = 8'd58;     // The live time of this packet: from 140.114.14.135 to 192.168.0.230 <-- consist with golden data
`endif

`ifdef TCP
parameter [7:0] PROTOCOL = 8'h06;
`else
parameter [7:0] PROTOCOL = 8'd0;
`endif

//parameter SRC_IP = 32'hc0_a8_32_fd;      // 192.168.50.253 transfer to hex --> c0_a8_32_fd
//parameter DES_IP = 32'hca_a9_ac_8a;     // 202.169.172.138 transfer to hex -> ca_a9_ac_8a
`ifndef Alice_B
    parameter [31:0] DES_IP_RX_B = 32'hc0_a8_00_e6;      // 192.168.50.253 transfer to hex --> c0_a8_32_fd
    parameter [31:0] SRC_IP_RX_B = 32'h8c_72_0e_87;     // 202.169.172.138 transfer to hex -> ca_a9_ac_8a
    parameter [31:0] DES_IP_TX_B = SRC_IP_RX_B; 
    parameter [31:0] SRC_IP_TX_B = DES_IP_RX_B; 
    parameter [15:0] ID_TX_B = 16'h3c88;
`else
    parameter [31:0] DES_IP_RX_B = 32'h8c_72_0e_87;      // 192.168.50.253 transfer to hex --> c0_a8_32_fd
    parameter [31:0] SRC_IP_RX_B = 32'hc0_a8_00_e6;     // 202.169.172.138 transfer to hex -> ca_a9_ac_8a
    parameter [31:0] DES_IP_TX_B = SRC_IP_RX_B; 
    parameter [31:0] SRC_IP_TX_B = DES_IP_RX_B; 
    parameter [15:0] ID_TX_B = 16'h6e37;
`endif
/////// transport layer settings

parameter LEN_SRC_PORT = LEN_DES_IP + 16'd2;  // = 43
parameter LEN_DES_PORT = LEN_SRC_PORT + 16'd2;  // = 45
parameter LEN_SEQ = LEN_DES_PORT + 16'd4;  // = 49
parameter LEN_ACK = LEN_SEQ + 16'd4;  // = 53
parameter LEN_HEAD_CTR =  LEN_ACK + 16'd2;     // including header length, reserved, and control flag   // = 55
parameter LEN_WIN_SIZE = LEN_HEAD_CTR + 16'd2;   // = 57
parameter LEN_TCP_CHECK = LEN_WIN_SIZE + 16'd2;   // = 59
parameter LEN_URGENT_PTR = LEN_TCP_CHECK + 16'd2;   // = 61


parameter PAYLOAD_SIZE = 11680;     //  1460bytes  = 11680 bits maximum
                                // 8 bytes = 40 bits minimum (due to the tcp_checksum module)
                                // 1024 bytes = 8192 bits is what we are using
`ifndef Alice_B
    parameter [15:0] DES_PORT_RX_B = 16'hff08;
    parameter [15:0] SRC_PORT_RX_B = 16'h089a;
    parameter [15:0] DES_PORT_TX_B = SRC_PORT_RX_B;
    parameter [15:0] SRC_PORT_TX_B = DES_PORT_RX_B;
    parameter [31:0] CLIENT_ISN_B = 32'hec_aa_f8_b3;
    parameter [31:0] SERVER_ISN_B = 32'h2b_00_a9_9d;
`else 
    parameter [15:0] DES_PORT_RX_B = 16'h089a;
    parameter [15:0] SRC_PORT_RX_B = 16'hff08;
    parameter [15:0] DES_PORT_TX_B = SRC_PORT_RX_B;
    parameter [15:0] SRC_PORT_TX_B = DES_PORT_RX_B;
    parameter [31:0] CLIENT_ISN_B = 32'h2b_00_a9_9d;
    parameter [31:0] SERVER_ISN_B = 32'hec_aa_f8_b3;
`endif
parameter [3:0] TRANS_HEADER_LEN_TX = 4'd5;
parameter [2:0] RESERVED_TX = 3'd0;
parameter [15:0] WIN_SIZE_TX = 16'd1024; 
parameter [15:0] URGENT_PTR_TX = 16'd0; 

//parameter [31:0] OPTION_MSS_TX = 31'h02_04_04_00;   // Set Max segment size as 1024 bytes: | Kind = 2(MSS) | Length = 4 bytes | Value = 0x0400 = 1024 | 
//parameter [23:0] OPTION_WIN_SCALE_TX = 24'h03_03_00;    // Set window scalse as 0: | Kind = 3(Window scale) | Length = 3 bytes | Value = 0x00 = 2^0 |


