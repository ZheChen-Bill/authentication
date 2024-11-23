



`timescale 1ns/100ps

//`include "./pa_parameter.v"




module tb_Bob ();


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
    reg [31:0] i_TX;
    reg [31:0] i_RX;

    reg [7:0]     gmii_rxd_TX; // Received Data to client MAC
    reg           gmii_rx_dv_TX; // Received control signal to client MAC.
    reg           gmii_rx_er_TX;

    wire [7:0] gmii_txd_TX;
    wire gmii_tx_en_TX;
    wire gmii_tx_er_TX;

    reg [7:0]     gmii_rxd_RX; // Received Data to client MAC
    reg           gmii_rx_dv_RX; // Received control signal to client MAC.
    reg           gmii_rx_er_RX;

    wire [7:0]    gmii_txd_RX;
    wire          gmii_tx_en_RX;
    wire          gmii_tx_er_RX;

    wire B2A_busy_PP2Net_TX;
    wire B2A_busy_Net2PP_TX;

    wire B2A_busy_Net2PP_RX;
    wire B2A_busy_PP2Net_RX;

    //    wire A2B_busy_Net2PP_RX;
    //    wire A2B_busy_PP2Net_RX;


    reg   link_status;
    reg   output_next_pb_TX;
    reg   output_next_pb_RX;
    reg   correct_TX;
    reg   correct_RX;
    reg [7:0] testData_TX;
    reg [7:0] testData_RX;
    reg [7:0] testOrigin_TX [0:475];
    reg [7:0] testOrigin_RX [0:475];
    reg [7:0] msg_frame_TX [0:(1098*8-1)];
    reg [7:0] msg_frame_RX [0:(1098*8-1)];
    parameter [31:0]  first_len = 32'd66;
    parameter [31:0]  second_len = 32'd66;
    parameter [31:0]  third_len = 32'd54;
    parameter [31:0]  fourth_len = 32'd95;
    parameter [31:0]  fifth_len = 32'd54;
    reg [31:0] i_out_TX;
    reg [31:0] i_out_RX;
    integer fp_w_TX;
    integer fp_w_RX;
    //----------------------------new add signal------------------------------

    initial begin
        $dumpfile("Bob.vcd");
        $dumpvars(0,tb_Bob);
    end
    // ===== Clk fliping ===== //
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        clk_PP = 1'b0;
        forever begin
            #1.315 clk_PP = 1'b1;
            #1.315 clk_PP = 1'b0;
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
        link_status = 1;
    end


    initial begin
        start_switch = 0;
        wait (rst_n == 0);
        wait (rst_n == 1);
        #(CLK_PERIOD*100);
        test_Bob;
        //       @(negedge B2A_busy_PP2Net_RX);
        #(CLK_PERIOD*1000);

        i_TX = 0;
        repeat(4)
            begin
                repeat (20) begin
                    @(negedge clk_GMII);
                end
                @(negedge clk_GMII);
                WriteToGMII_msg_TX(32'd1098, 32'd0, i_TX, i_out_TX);
                i_TX = i_out_TX;
                @(negedge gmii_tx_en_TX);
            end
        @(negedge B2A_busy_PP2Net_RX);
        repeat(4)
            begin
                repeat (20) begin
                    @(negedge clk_GMII);
                end
                @(negedge clk_GMII);
                WriteToGMII_msg_TX(32'd1098, 32'd0, i_TX, i_out_TX);
                i_TX = i_out_TX;
                @(negedge gmii_tx_en_TX);
            end

        start_switch = 1;
    end

    initial begin
        rst_n = 1;
        #(CLK_PERIOD*2000) rst_n = 0;
        #(CLK_PERIOD*1000) rst_n = 1;
    end










    //****************************** AB_pa test ******************************



    // Alice secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    wire [63:0] Asecretkey_dinb; //Alice secret key 
    wire [14:0] Asecretkey_addrb; //0~32767
    wire Asecretkey_clkb;
    wire Asecretkey_enb; //1'b1
    wire Asecretkey_web; //
    wire Asecretkey_rstb;


    // Bob secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    wire [63:0] Bsecretkey_dinb; //Bob secret key 
    wire [14:0] Bsecretkey_addrb; //0~32767
    wire Bsecretkey_clkb;
    wire Bsecretkey_enb; //1'b1
    wire Bsecretkey_web; //
    wire Bsecretkey_rstb;



    wire A_pa_finish;
    wire A_pa_fail;

    wire B_pa_finish;
    wire B_pa_fail;

    wire B_reset_pa_parameter;

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

        .gmii_txd(gmii_txd_TX), // Transmit data from client MAC.
        .gmii_tx_en(gmii_tx_en_TX), // Transmit control signal from client MAC.
        .gmii_tx_er(gmii_tx_er_TX), // Transmit control signal from client MAC.
        .gmii_rxd(gmii_rxd_TX), // Received Data to client MAC.
        .gmii_rx_dv(gmii_rx_dv_TX), // Received control signal to client MAC.
        .gmii_rx_er(gmii_rx_er_TX), // Received control signal to client MAC.

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

    task test_Alice;
        begin
            output_next_pb_TX = 1'b0;
            fp_w_TX = $fopen("./data_out.txt", "w");
            $readmemh ("./data_out.txt", msg_frame_TX);
            gmii_rx_dv_TX = 1'b0;
            gmii_rx_er_TX = 1'b0;
            gmii_rxd_TX = 8'h55;
            correct_TX = 1'b1;
            i_TX = 0;


            $readmemh ("./golden_packet_verilog.txt", testOrigin_TX);
            //            $display(testOrigin[0]);
            //            $display(testOrigin[1]);
            //            $display(testOrigin[i]);
            @(negedge clk_GMII)
            WriteToGMII_TX(first_len, 32'h7f69_d8a1, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of First packet!");
            //        repeat(50)
            //        begin 
            //            @(negedge clk_GMII);
            //        end

            //        i_TX = 0;
            //        @(negedge clk_GMII) 
            //        WriteToGMII_TX(first_len, 32'h7f69_d8a1, i_TX, i_out_TX);
            //        i_TX = i_out_TX;

            //        repeat(100)
            //        begin 
            //            @(negedge clk_GMII);
            //        end

            //        i = 0;
            //        @(negedge clk_GMII) 
            //        WriteToGMII(first_len, 32'h7f69_d8a1, i, i_out);
            //        i = i_out;

            @(posedge gmii_tx_en_TX);
            @(negedge clk_GMII)
            readFromGMII_TX(second_len, 32'ha1f9_7460, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Second packet!");

            @(negedge clk_GMII)
            WriteToGMII_TX(third_len, 32'h2b40_41b8, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Third packet!");
            repeat(100)
                begin
                    @(negedge clk_GMII);
                end
                //        i = 66+66;
                //        @(negedge clk_GMII) 
                //        WriteToGMII(third_len, 32'h2b40_41b8, i, i_out);
                //        i = i_out;
                //        $display("End of Third packet!");

            i_TX = 0;
            @(negedge clk_GMII)
            WriteToGMII_TX(first_len, 32'h7f69_d8a1, i_TX, i_out_TX);
            i_TX = i_out_TX;

            @(posedge gmii_tx_en_TX);
            @(negedge clk_GMII)
            readFromGMII_TX(second_len, 32'ha1f9_7460, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Second packet!");

            @(negedge clk_GMII)
            WriteToGMII_TX(third_len, 32'h2b40_41b8, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Third packet!");


            //        i = 0;

            //        repeat(4)
            //        begin
            //            repeat(12)
            //            begin 
            //                @(negedge clk_GMII) ;
            //            end 
            //            @(negedge clk_GMII);            
            //            WriteToGMII_msg(32'd1098, 32'd0, i, i_out);
            //            i = i_out;
            //            @(negedge gmii_tx_en);
            //        end

            //        output_next_pb_TX= 1'b1;
            //        #100 
            //        output_next_pb_TX = 1'b0;

            //        repeat (4)
            //        begin
            //            @(posedge gmii_tx_en_TX)
            //            repeat(1098)
            //            begin 
            //                @(negedge clk_GMII);
            //                $display("%x", gmii_txd_TX);
            //                $fwrite(fp_w_TX, "%x\n", gmii_txd_TX);
            //            end 

            //            repeat(20)
            //            begin 
            //                @(negedge clk_GMII) ;
            //            end 
            //            i_TX = 66+66+54+95;
            //            @(negedge clk_GMII) 
            //            WriteToGMII_TX(fifth_len, 32'ha362_3e38, i_TX, i_out_TX);
            //            i_TX = i_out_TX;
            //            $display("End of Fifth packet!");
            //        end

            //        @(negedge B2A_busy_Net2PP_TX);
            //        repeat (10) begin 
            //            @(negedge clk);
            //        end
            //        output_next_pb_TX = 1'b1;
            //        #100 
            //        output_next_pb_TX = 1'b0;

            //        repeat (4)
            //        begin
            //            @(posedge gmii_tx_en_TX)
            //            repeat(1098)
            //            begin 
            //                @(negedge clk_GMII);
            //                $display("%x", gmii_txd_TX);
            //                $fwrite(fp_w_TX, "%x\n", gmii_txd_TX);
            //            end 

            //            repeat(20)
            //            begin 
            //                @(negedge clk_GMII) ;
            //            end 
            //            i_TX = 66+66+54+95;
            //            @(negedge clk_GMII) 
            //            WriteToGMII_TX(fifth_len, 32'ha362_3e38, i_TX, i_out_TX);
            //            i_TX = i_out_TX;
            //            $display("End of Fifth packet!");
            //        end

            //        $fclose(fp_w_TX);
            //        @(negedge clk_GMII) 
            //        repeat(100)
            //        begin 
            //            @(negedge clk_GMII) ;
            //        end 

            //        j = 0;
            //        repeat(1098)
            //        begin 
            //            @(negedge clk_GMII)
            //            gmii_rxd = msg_frame[j];
            //            gmii_rx_dv = 1'b1;
            //            j = j + 1;
            //        end
            ////        @(negedge clk_GMII)
            ////        gmii_rxd = 8'h5b;
            ////        @(negedge clk_GMII)
            ////        gmii_rxd = 8'h44;
            ////        @(negedge clk_GMII)
            ////        gmii_rxd = 8'h20;
            ////        @(negedge clk_GMII)
            ////        gmii_rxd = 8'h29;
            //        @(negedge clk_GMII) 
            //        gmii_rx_dv = 1'b0;
            ////        readFromGMII(fourth_len, 32'h2c25_2405, i, i_out);
            ////        i = i_out;
            //        $display("End of Fourth packet!");
            //        repeat(100)
            //        begin 
            //            @(negedge clk_GMII) ;
            //        end 
            //        @(negedge clk_GMII) 
            //        WriteToGMII(fifth_len, 32'ha362_3e38, i, i_out);
            //        i = i_out;
            //        $display("End of Fifth packet!");
        end
    endtask

    task test_Bob;
        begin
            output_next_pb_TX = 1'b0;
            gmii_rx_dv_TX = 1'b0;
            gmii_rx_er_TX = 1'b0;
            gmii_rxd_TX = 8'h55;
            correct_TX = 1'b1;
            i_TX = 0;
            $readmemh ("./golden_packet_verilog.txt", testOrigin_TX);
            $readmemh ("./data_out_readOnly_TwoBatchMsg.txt", msg_frame_TX);
            //            $display(testOrigin[0]);
            //            $display(testOrigin[1]);
            //            $display(testOrigin[i]);
            @(negedge clk_GMII)
            readFromGMII_TX(first_len, 32'h7f69_d8a1, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of First packet!");

            //        repeat(20)
            //        begin 
            //            @(negedge clk_GMII);
            //        end 
            ////        $finish;
            //        @(negedge clk_GMII) 
            //        WriteToGMII_RX(second_len, 32'ha1f9_7460, i_RX, i_out_RX);
            //        i_RX = i_out_RX;
            //        $display("End of Second packet!");
            //        @(negedge clk_GMII) 
            //        readFromGMII_RX(third_len, 32'h2b40_41b8, i_RX, i_out_RX);
            //        i_RX = i_out_RX;
            //        $display("End of Third packet!");
            //        @(negedge clk_GMII) 
            //        WriteToGMII_RX(fourth_len, 32'h2c25_2405, i_RX, i_out_RX);
            //        i_RX = i_out_RX;
            //        $display("End of Fourth packet!");
            //        @(negedge clk_GMII) 
            //        readFromGMII_RX(fifth_len, 32'ha362_3e38, i_RX, i_out_RX);
            //        i_RX = i_out_RX;
            //        $display("End of Fifth packet!");
            //    end
            repeat(20)
                begin
                    @(negedge clk_GMII);
                end
                //        $finish;
            @(negedge clk_GMII)
            WriteToGMII_TX(second_len, 32'ha1f9_7460, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Second packet!");
            @(negedge clk_GMII)
            readFromGMII_TX(third_len, 32'h2b40_41b8, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Third packet!");
            @(negedge clk_GMII) ;


            repeat(20)
                begin
                    @(negedge clk_GMII);
                end
                //        $finish;
            i_TX = 66;
            @(negedge clk_GMII)
            WriteToGMII_TX(second_len, 32'ha1f9_7460, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Second packet!");


            //        output_next_pb = 1'b1;
            //        #100 
            //        output_next_pb = 1'b0;


            //        i = 66;
            //        @(negedge clk_GMII) ;
            //        WriteToGMII(second_len, 32'ha1f9_7460, i, i_out);
            //        i = i_out;
            //        $display("End of Second packet!");

            //        repeat (4)
            //        begin
            //            @(posedge gmii_tx_en)
            //            repeat(1098)
            //            begin 
            //                @(negedge clk_GMII);
            ////                $display("%x", gmii_txd);
            ////                $fwrite(fp_w, "%x\n", gmii_txd);
            //            end 

            ////            repeat(10)
            ////            begin 
            ////                @(negedge clk_GMII) ;
            ////            end 
            ////            i = 66+66;
            ////            @(negedge clk_GMII) 
            ////            WriteToGMII(fifth_len, 32'ha1f9_7460, i, i_out);
            ////            i = i_out;
            ////            $display("End of Fifth packet!");
            //        end

            //        $fclose(fp_w);
            //        repeat(12)
            //        begin 
            //            @(negedge clk_GMII) ;
            //        end 
            //        i = 0;
            @(negedge clk_GMII)
            readFromGMII_TX(third_len, 32'h2b40_41b8, i_TX, i_out_TX);
            i_TX = i_out_TX;
            $display("End of Third packet!");
            @(negedge clk_GMII) ;

            i_TX = 0;
            repeat(4)
                begin
                    repeat (20) begin
                        @(negedge clk_GMII);
                    end
                    @(negedge clk_GMII);
                    WriteToGMII_msg_TX(32'd1098, 32'd0, i_TX, i_out_TX);
                    i_TX = i_out_TX;
                    @(negedge gmii_tx_en_TX);
                end
            @(negedge B2A_busy_PP2Net_RX);

            repeat(4)
                begin
                    repeat (20) begin
                        @(negedge clk_GMII);
                    end
                    @(negedge clk_GMII);
                    WriteToGMII_msg_TX(32'd1098, 32'd0, i_TX, i_out_TX);
                    i_TX = i_out_TX;
                    @(negedge gmii_tx_en_TX);
                end
                ////        @(posedge gmii_tx_en)
                ////        repeat(1098)
                ////        begin 
                ////            @(negedge clk_GMII);
                ////            $display("%x", gmii_txd);
                ////        end 


                //        i = 66+66+54+95;
                //        @(negedge clk_GMII) 
                //        readFromGMII(fifth_len, 32'ha362_3e38, i, i_out);
                //        i = i_out;
                //        $display("End of Fifth packet!");

                //        readFromGMII(fourth_len, 32'h2c25_2405, i, i_out);
                //        i = i_out;
                //        $display("End of Fourth packet!");
                //        @(negedge clk_GMII) 
                //        readFromGMII(fifth_len, 32'ha362_3e38, i, i_out);
                //        i = i_out;
                //        $display("End of Fifth packet!");
        end
    endtask

    task automatic readFromGMII_TX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );

        begin
            i = i_in;
            @(posedge gmii_tx_en_TX);
            repeat(8) begin
                @(negedge clk_GMII);
            end
            repeat(lengh) begin
                testData_TX = testOrigin_TX[i];
                //                $display(testOrigin[i]);
                @(negedge clk_GMII)
                correct_TX = (testData_TX == gmii_txd_TX);
                i = i + 1;
            end
            @(negedge clk_GMII)
            testData_TX = FCS[31:24];
            correct_TX = (testData_TX == gmii_txd_TX);
            @(negedge clk_GMII)
            testData_TX = FCS[23:16];
            correct_TX = (testData_TX == gmii_txd_TX);
            @(negedge clk_GMII)
            testData_TX = FCS[15:8];
            correct_TX = (testData_TX == gmii_txd_TX);
            @(negedge clk_GMII)
            testData_TX = FCS[7:0];
            correct_TX = (testData_TX == gmii_txd_TX);

            //            $display("End of the first packet");
            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask

    task automatic WriteToGMII_TX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );
        begin
            i = i_in;
            @(negedge clk_GMII)
            gmii_rx_dv_TX = 1'b1;
            gmii_rxd_TX = 8'h55;
            repeat(6) begin
                @(negedge clk_GMII);
            end
            @(negedge clk_GMII)
            gmii_rxd_TX = 8'hd5;

            repeat(lengh) begin
                @(negedge clk_GMII)
                testData_TX = testOrigin_TX[i];
                gmii_rxd_TX = testData_TX;
                //                $display("Receiving: ", i, testOrigin[i]);
                i = i + 1;
            end
            @(negedge clk_GMII)
            testData_TX = FCS[31:24];
            gmii_rxd_TX = testData_TX;
            @(negedge clk_GMII)
            testData_TX = FCS[23:16];
            gmii_rxd_TX = testData_TX;
            @(negedge clk_GMII)
            testData_TX = FCS[15:8];
            gmii_rxd_TX = testData_TX;
            @(negedge clk_GMII)
            testData_TX = FCS[7:0];
            gmii_rxd_TX = testData_TX;

            @(negedge clk_GMII)
            gmii_rxd_TX = 8'h55;
            gmii_rx_dv_TX = 1'b0;
            //            $display("End of the second packet");

            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask

    task automatic readFromGMII_RX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );

        begin
            i = i_in;
            @(posedge gmii_tx_en_RX);
            repeat(8) begin
                @(negedge clk_GMII);
            end
            repeat(lengh) begin
                testData_RX = testOrigin_RX[i];
                //                $display(testOrigin[i]);
                @(negedge clk_GMII)
                correct_RX = (testData_RX == gmii_txd_RX);
                i = i + 1;
            end
            @(negedge clk_GMII)
            testData_RX = FCS[31:24];
            correct_RX = (testData_RX == gmii_txd_RX);
            @(negedge clk_GMII)
            testData_RX = FCS[23:16];
            correct_RX = (testData_RX == gmii_txd_RX);
            @(negedge clk_GMII)
            testData_RX = FCS[15:8];
            correct_RX = (testData_RX == gmii_txd_RX);
            @(negedge clk_GMII)
            testData_RX = FCS[7:0];
            correct_RX = (testData_RX == gmii_txd_RX);

            //            $display("End of the first packet");
            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask




    task automatic WriteToGMII_RX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );
        begin
            i = i_in;
            @(negedge clk_GMII)
            gmii_rx_dv_RX = 1'b1;
            gmii_rxd_RX = 8'h55;
            repeat(6) begin
                @(negedge clk_GMII);
            end
            @(negedge clk_GMII)
            gmii_rxd_RX = 8'hd5;

            repeat(lengh) begin
                @(negedge clk_GMII)
                testData_RX = testOrigin_RX[i];
                gmii_rxd_RX = testData_RX;
                //                $display("Receiving: ", i, testOrigin[i]);
                i = i + 1;
            end
            @(negedge clk_GMII)
            testData_RX = FCS[31:24];
            gmii_rxd_RX = testData_RX;
            @(negedge clk_GMII)
            testData_RX = FCS[23:16];
            gmii_rxd_RX = testData_RX;
            @(negedge clk_GMII)
            testData_RX = FCS[15:8];
            gmii_rxd_RX = testData_RX;
            @(negedge clk_GMII)
            testData_RX = FCS[7:0];
            gmii_rxd_RX = testData_RX;

            @(negedge clk_GMII)
            gmii_rxd_RX = 8'h55;
            gmii_rx_dv_RX = 1'b0;
            //            $display("End of the second packet");

            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask

    task automatic WriteToGMII_msg_TX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );
        begin
            i = i_in;
            //            @(negedge clk_GMII)
            //            gmii_rx_dv = 1'b1;
            //            gmii_rxd = 8'h55;
            //            repeat(6) begin 
            //                @(negedge clk_GMII);
            //            end
            //            @(negedge clk_GMII)
            //            gmii_rxd = 8'hd5;

            repeat(lengh) begin
                @(negedge clk_GMII)
                testData_TX = msg_frame_TX[i];
                gmii_rx_dv_TX = 1'b1;
                gmii_rxd_TX = testData_TX;
                //                $display("Receiving: ", i, testOrigin[i]);
                i = i + 1;
            end
            //            @(negedge clk_GMII)
            //            testData = FCS[31:24];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[23:16];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[15:8];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[7:0];
            //            gmii_rxd = testData;

            @(negedge clk_GMII)
            gmii_rxd_TX = 8'h55;
            gmii_rx_dv_TX = 1'b0;
            //            $display("End of the second packet");

            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask

    task automatic WriteToGMII_msg_RX (
        input [31:0] lengh,
        input [31:0] FCS,
        input [31:0] i_in,
        output [31:0] i
    );
        begin
            i = i_in;
            //            @(negedge clk_GMII)
            //            gmii_rx_dv = 1'b1;
            //            gmii_rxd = 8'h55;
            //            repeat(6) begin 
            //                @(negedge clk_GMII);
            //            end
            //            @(negedge clk_GMII)
            //            gmii_rxd = 8'hd5;

            repeat(lengh) begin
                @(negedge clk_GMII)
                testData_RX = msg_frame_RX[i];
                gmii_rx_dv_RX = 1'b1;
                gmii_rxd_RX = testData_RX;
                //                $display("Receiving: ", i, testOrigin[i]);
                i = i + 1;
            end
            //            @(negedge clk_GMII)
            //            testData = FCS[31:24];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[23:16];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[15:8];
            //            gmii_rxd = testData;
            //            @(negedge clk_GMII)
            //            testData = FCS[7:0];
            //            gmii_rxd = testData;

            @(negedge clk_GMII)
            gmii_rxd_RX = 8'h55;
            gmii_rx_dv_RX = 1'b0;
            //            $display("End of the second packet");

            //            repeat(100) begin 
            //                @(negedge clk_GMII);
            //            end 
        end
    endtask
endmodule