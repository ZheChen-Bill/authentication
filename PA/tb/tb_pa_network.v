



`timescale 1ns/100ps

//`include "./pa_parameter.v"




module tb_pa_network ();


    wire [31:0] secretkey_length;
    wire reconciled_key_addr_index;

    assign secretkey_length = 32'd4096;
    assign reconciled_key_addr_index = 0;

    parameter CLK_PERIOD = 8;

    reg clk;
    reg rst_n;
    reg start_switch;
    
    //----------------------------new add signal------------------------------
    reg clk_100M;
    reg clk_GMII;

    reg gmii_tx_clk;
    reg gmii_rx_clk;

    reg clk_PP;

    wire [7:0]   gmii_rxd_TX; // Received Data to client MAC
    wire           gmii_rx_dv_TX; // Received control signal to client MAC.
    wire           gmii_rx_er_TX;

    wire [7:0]   gmii_txd_TX;
    wire           gmii_tx_en_TX;
    wire           gmii_tx_er_TX;

    wire A2B_busy_PP2Net_TX;
    wire A2B_busy_Net2PP_TX;
    
    wire A2B_busy_Net2PP_RX;
    wire A2B_busy_PP2Net_RX;

    wire B2A_busy_PP2Net_TX;
    wire B2A_busy_Net2PP_TX;
    
    wire B2A_busy_Net2PP_RX;
    wire B2A_busy_PP2Net_RX;
    reg   link_status;
    
    //----------------------------new add signal------------------------------
    // ===== Clk fliping ===== //
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    initial begin
        clk_PP = 1'b0;
        forever begin
            //            #1.315 clk_PP = 1'b1;
            //            #1.315 clk_PP = 1'b0;
            #1.3334 clk_PP = 1'b1;
            #1.3334 clk_PP = 1'b0;
        end
    end

    initial begin
        clk_100M = 1'b0;
        forever begin
            #5 clk_100M = 1'b1;
            #5 clk_100M = 1'b0;
        end
    end
    // clk_GMII = 125MHz
    initial begin
        clk_GMII = 1'b0;
        forever begin
            #4 clk_GMII = 1'b1;
            #4 clk_GMII = 1'b0;
        end
    end

    initial begin
        gmii_tx_clk = 1'b0;
        gmii_rx_clk = 1'b0;
        forever begin
            #4 gmii_tx_clk = 1'b1; gmii_rx_clk = 1'b1;
            #4 gmii_tx_clk = 1'b0; gmii_rx_clk = 1'b0;
        end
    end

	initial begin
        rst_n = 1;
        #(CLK_PERIOD*1000) rst_n = 0;
        #(CLK_PERIOD*1000) rst_n = 1;  
	end


    initial begin
        start_switch = 0;
		wait (rst_n == 0);
		wait (rst_n == 1);
        #(CLK_PERIOD*1000);
        start_switch = 1;
    end


    initial begin
        link_status = 1'b1;
    end









//****************************** AB_pa test ******************************



    // Alice secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    wire [63:0] Asecretkey_dinb;     //Alice secret key 
    wire [14:0] Asecretkey_addrb;    //0~32767
    wire Asecretkey_clkb;
    wire Asecretkey_enb;                    //1'b1
    wire Asecretkey_web;              //
    wire Asecretkey_rstb;


    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    wire [63:0] Bsecretkey_dinb;     //Bob secret key 
    wire [14:0] Bsecretkey_addrb;    //0~32767
    wire Bsecretkey_clkb;
    wire Bsecretkey_enb;                    //1'b1
    wire Bsecretkey_web;              //
    wire Bsecretkey_rstb;



    wire A_pa_finish;
    wire A_pa_fail;
    
    wire B_pa_finish;
    wire B_pa_fail;

    wire B_reset_pa_parameter;

//****************************** AB_pa test ******************************
    Alice u_Alice(
        .clk(clk),
        .rst_n(rst_n),

//        .clk_100M(clk_100M),
//        .clk_GMII(clk_GMII),
        .gmii_tx_clk(gmii_tx_clk),
        .gmii_rx_clk(gmii_rx_clk),
        
        .clk_PP(clk_PP),
        .link_status(link_status),
        
        .A2B_busy_PP2Net_TX(A2B_busy_PP2Net_TX),
        .A2B_busy_Net2PP_TX(A2B_busy_Net2PP_TX),
        
        .A2B_busy_Net2PP_RX(A2B_busy_Net2PP_RX),
        .A2B_busy_PP2Net_RX(A2B_busy_PP2Net_RX),
        
        .gmii_txd(gmii_txd_TX),              // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en_TX),                             // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er_TX),           // Transmit control signal from client MAC.
        .gmii_rxd(gmii_rxd_TX),                // Received Data to client MAC.
        .gmii_rx_dv(gmii_rx_dv_TX),          // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er_TX),           // Received control signal to client MAC.
        .start_switch(start_switch),


        .secretkey_length(secretkey_length),   //secret key length
        .reconciled_key_addr_index(reconciled_key_addr_index),  //address index
                                                                //0:addr0 ~ addr16383
                                                                //1:addr16384 ~ addr32767


        // Alice secret key BRAM (output)
        // width = 64 , depth = 32768
        // port B
        .A_Secretkey_addrb(Asecretkey_addrb),   //0~32767
        .A_Secretkey_clkb(Asecretkey_clkb),      
        .A_Secretkey_dinb(Asecretkey_dinb),
        .A_Secretkey_enb(Asecretkey_enb),           //1'b1
        .A_Secretkey_rstb(Asecretkey_rstb),          //1'b0
        .A_Secretkey_web(Asecretkey_web),  

        // Bob secret key BRAM (output)
        // width = 64 , depth = 32768
        // port B
//        .B_Secretkey_addrb(Bsecretkey_addrb),   //0~32767
//        .B_Secretkey_clkb(Bsecretkey_clkb),      
//        .B_Secretkey_dinb(Bsecretkey_dinb),
//        .B_Secretkey_enb(Bsecretkey_enb),           //1'b1
//        .B_Secretkey_rstb(Bsecretkey_rstb),          //1'b0
//        .B_Secretkey_web(Bsecretkey_web),      


        .A_pa_finish(A_pa_finish),                     //pa is done
        .A_pa_fail(A_pa_fail)                       //pa is fail due to error secret key length

//        .B_pa_finish(B_pa_finish),                     //pa is done
//        .B_pa_fail(B_pa_fail),                       //pa is fail due to error secret key length

//        .B_reset_pa_parameter(B_reset_pa_parameter)               //

    );

    Bob u_Bob(
        .clk(clk),
        .rst_n(rst_n),

        //        .clk_100M(clk_100M),
        //        .clk_GMII(clk_GMII),
        .gmii_tx_clk(gmii_tx_clk),
        .gmii_rx_clk(gmii_rx_clk),
        .clk_PP(clk_PP),
        .link_status(link_status),

        .B2A_busy_PP2Net_TX(B2A_busy_PP2Net_TX),
        .B2A_busy_Net2PP_TX(B2A_busy_Net2PP_TX),

        .B2A_busy_Net2PP_RX(B2A_busy_Net2PP_RX),
        .B2A_busy_PP2Net_RX(B2A_busy_PP2Net_RX),

        .gmii_txd(gmii_rxd_TX), // Transmit data from client MAC.
        .gmii_tx_en(gmii_rx_dv_TX), // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_rx_er_TX), // Transmit control signal from client MAC.
        .gmii_rxd(gmii_txd_TX), // Received Data to client MAC.
        .gmii_rx_dv(gmii_tx_en_TX), // Received control signal to client MAC.
        .gmii_rx_er(gmii_tx_er_TX), // Received control signal to client MAC.

        .start_switch(start_switch),

        .secretkey_length(secretkey_length), //secret key length
        .reconciled_key_addr_index(reconciled_key_addr_index), //address index
        //0:addr0 ~ addr16383
        //1:addr16384 ~ addr32767


        // Alice secret key BRAM (output)
        // width = 64 , depth = 32768
        // port B
        //        .A_Secretkey_addrb(Asecretkey_addrb), //0~32767
        //        .A_Secretkey_clkb(Asecretkey_clkb),
        //        .A_Secretkey_dinb(Asecretkey_dinb),
        //        .A_Secretkey_enb(Asecretkey_enb), //1'b1
        //        .A_Secretkey_rstb(Asecretkey_rstb), //1'b0
        //        .A_Secretkey_web(Asecretkey_web),

        // Bob secret key BRAM (output)
        // width = 64 , depth = 32768
        // port B
        .B_Secretkey_addrb(Bsecretkey_addrb), //0~32767
        .B_Secretkey_clkb(Bsecretkey_clkb),
        .B_Secretkey_dinb(Bsecretkey_dinb),
        .B_Secretkey_enb(Bsecretkey_enb), //1'b1
        .B_Secretkey_rstb(Bsecretkey_rstb), //1'b0
        .B_Secretkey_web(Bsecretkey_web),


        //        .A_pa_finish(A_pa_finish), //pa is done
        //        .A_pa_fail(A_pa_fail), //pa is fail due to error secret key length

        .B_pa_finish(B_pa_finish), //pa is done
        .B_pa_fail(B_pa_fail), //pa is fail due to error secret key length

        .B_reset_pa_parameter(B_reset_pa_parameter) //

    );

//****************************** AB_pa test ******************************


    reg A_finish, B_finish;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_finish <= 1'b0;
        end
        else if (A_pa_finish) begin
            A_finish <= 1'b1;
        end
        else begin
            A_finish <= A_finish;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            B_finish <= 1'b0;
        end
        else if (B_pa_finish) begin
            B_finish <= 1'b1;
        end
        else begin
            B_finish <= B_finish;
        end
    end

    integer A_secretkey_out;
    initial A_secretkey_out = $fopen("D:/LAB/quantum_cryptography/QKD_post_processing/QKD_post_processing/privacy_amplification/kcu116_PA_v2/HW_sim_result/A_secretkey_out.txt", "w");

    always @(*) begin
        if (Asecretkey_web && Asecretkey_enb) begin
            $fdisplay(A_secretkey_out,"%H",Asecretkey_dinb);
        end
    end


    integer B_secretkey_out;
    initial B_secretkey_out = $fopen("D:/LAB/quantum_cryptography/QKD_post_processing/QKD_post_processing/privacy_amplification/kcu116_PA_v2/HW_sim_result/B_secretkey_out.txt", "w");

    always @(*) begin
        if (Bsecretkey_web && Bsecretkey_enb) begin
            $fdisplay(B_secretkey_out,"%H",Bsecretkey_dinb);
        end
    end

    always @(*) begin
        if ( A_finish && B_finish) begin
            $display("[FINISH]");
            $display("[FINISH]");
            $display("[FINISH]");
            $display("[FINISH]");
            $display("[FINISH]");
            $display("[FINISH]");
            $display("[FINISH]");
            #(CLK_PERIOD);
            $fclose(A_secretkey_out);
            $fclose(B_secretkey_out);
            $finish;
        end
    end


endmodule