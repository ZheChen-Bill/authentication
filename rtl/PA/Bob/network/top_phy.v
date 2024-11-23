


module top_phy
(

    input            independent_clock,
    input            io_refclk,
    
    // Tranceiver Interface
    //---------------------
    input            gtrefclk_p,            // Differential +ve of reference clock for MGT: very high quality.
    input            gtrefclk_n,            // Differential -ve of reference clock for MGT: very high quality.
    output           rxuserclk,
    output           rxuserclk2,
    output           userclk,
    output           userclk2,
    output           txp,                   // Differential +ve of serial transmission from PMA to PMD.
    output           txn,                   // Differential -ve of serial transmission from PMA to PMD.
    input            rxp,                   // Differential +ve for serial reception from PMD to PMA.
    input            rxn,                   // Differential -ve for serial reception from PMD to PMA.
    
    // GMII Interface (client MAC <=> PCS)
    //------------------------------------
    output           gmii_tx_clk,           // Transmit clock from client MAC.
    output           gmii_rx_clk,           // Receive clock to client MAC.
    input [7:0]      gmii_txd,              // Transmit data from client MAC.
    input            gmii_tx_en,            // Transmit control signal from client MAC.
    input            gmii_tx_er,            // Transmit control signal from client MAC.
    output [7:0]     gmii_rxd,              // Received Data to client MAC.
    output           gmii_rx_dv,            // Received control signal to client MAC.
    output           gmii_rx_er,            // Received control signal to client MAC.
    // Management: Alternative to MDIO Interface
    //------------------------------------------
    
//    input [4:0]      configuration_vector,  // Alternative to MDIO interface.
    
    output           an_interrupt,          // Interrupt to processor to signal that Auto-Negotiation has completed
//    input [15:0]     an_adv_config_vector,  // Alternate interface to program REG4 (AN ADV)
//    input            an_restart_config,     // Alternate signal to modify AN restart bit in REG0
    
    
    // General IO's
    //-------------
    output  [15:0]   status_vector,         // Core status.
    input            reset                 // Asynchronous reset for entire core.
//    input            signal_detect          // Input from PMD to indicate presence of optical input.

);
    wire [4:0]      configuration_vector;  // Alternative to MDIO interface.
    
//    wire [15:0]     an_adv_config_vector;  // Alternate interface to program REG4 (AN ADV)
//    wire            an_restart_config;     // Alternate signal to modify AN restart bit in REG0
    
    
    assign gmii_tx_clk = userclk2;
    
    // ------------------------------------------------------
    //    Bit value         Description
    //     0    0     Unidirectional Enable: normal operation
    //     1    0     Loopback Control: PMA not to enter loopback mode 
    //     2    0     Power Down
    //     3    0     Isotale: GMII should not be electrically isolated 
    //     4    0     Auto-Negotiation Enable: disable AN feature
    // ------------------------------------------------------
    assign configuration_vector = 5'b00000;
    
    
//    // --------------------------------------------------------
//    reg [1:0] remote_fault, remote_fault_next;
    
//    assign an_adv_config_vector[0] = 1'b1;              // Reserved for 1000Base-X
//    assign an_adv_config_vector[4:1] = 4'b0000;         // Reserved
//    assign an_adv_config_vector[5] = 1'b1;              // Full Duplex Mode is advertised: TX and RX can work simultaneously
//    assign an_adv_config_vector[6] = 1'b0;              // Reserved 
//    assign an_adv_config_vector[8:7] = 2'b00;           // No Pause: RX send a pause frame to TX. TX halts transferring packets for a period of time
//    assign an_adv_config_vector[9] = 1'b0;              // Reserved 
//    assign an_adv_config_vector[11:10] = 2'b00;         // Reserved
//    assign an_adv_config_vector[13:12] = 2'b00;  // Remote Fault Control 
//    assign an_adv_config_vector[14] = 1'b0;             // Reserved 
//    assign an_adv_config_vector[15] = 1'b0;             // Reserved for 1000Base-X
    
//    assign an_restart_config = 1'b0;
    
//    // ---------------------------------------------------------
//    //    AN state
//    //    00 -> No Error 
//    //    01 -> Offline 
//    //    10 -> Link Failure 
//    //    11 -> Auto negotitaion error
//    // ---------------------------------------------------------
//    always @(posedge gmii_tx_clk or posedge reset) begin 
//        if (reset) begin 
//            remote_fault <= 2'b00;
//        end else begin 
//            remote_fault <= remote_fault_next;
//        end 
//    end 
//    always @* begin 
//        remote_fault_next = remote_fault;
//        if (status_vector[13]) begin    // Local fault/ Remote fault is detected 
//            remote_fault_next = status_vector[9:8];      // status_vector[9:8] indicate Link Partner AN state
//        end else begin 
//            remote_fault_next = 2'b00;
//        end
//    end 
    
    phy_wrapper Uphy_wrapper
    (
    
        .independent_clock(independent_clock),
        .io_refclk(io_refclk),
        
        // Tranceiver Interface
        //---------------------
        .gtrefclk_p(gtrefclk_p),            // Differential +ve of reference clock for MGT: very high quality.
        .gtrefclk_n(gtrefclk_n),            // Differential -ve of reference clock for MGT: very high quality.
        .rxuserclk(rxuserclk),
        .rxuserclk2(rxuserclk2),
        .userclk2(userclk2),
        .userclk(userclk),
        .txp(txp),                   // Differential +ve of serial transmission from PMA to PMD.
        .txn(txn),                   // Differential -ve of serial transmission from PMA to PMD.
        .rxp(rxp),                   // Differential +ve for serial reception from PMD to PMA.
        .rxn(rxn),                   // Differential -ve for serial reception from PMD to PMA.

        // GMII Interface (client MAC <=> PCS)
        //------------------------------------
        .gmii_tx_clk(gmii_tx_clk),           // Transmit clock from client MAC.
        .gmii_rx_clk(gmii_rx_clk),           // Receive clock to client MAC.
        .gmii_txd(gmii_txd),              // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en),            // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er),            // Transmit control signal from client MAC.
        .gmii_rxd(gmii_rxd),              // Received Data to client MAC.
        .gmii_rx_dv(gmii_rx_dv),            // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er),            // Received control signal to client MAC.
        // Management: Alternative to MDIO Interface
        //------------------------------------------
        
        .configuration_vector(configuration_vector),  // Alternative to MDIO interface.
        
//        .an_interrupt(an_interrupt),          // Interrupt to processor to signal that Auto-Negotiation has completed
//        .an_adv_config_vector(an_adv_config_vector),  // Alternate interface to program REG4 (AN ADV)
//        .an_restart_config(an_restart_config),     // Alternate signal to modify AN restart bit in REG0
        
        
        // General IO's
        //-------------
        .status_vector(status_vector),         // Core status.
        .reset(reset),                 // Asynchronous reset for entire core.
        .signal_detect(1'b1)          // Input from PMD to indicate presence of optical input.
        
    );

endmodule
