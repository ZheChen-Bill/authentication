



`timescale 1ns/100ps

//`include "./pa_parameter.v"




module tb_AB_pa ();


    wire [31:0] secretkey_length;
    wire reconciled_key_addr_index;

    assign secretkey_length = 32'd4096;
    assign reconciled_key_addr_index = 0;

    parameter CLK_PERIOD = 8;

    reg clk;
    reg rst_n;
    reg start_switch;

    // ===== Clk fliping ===== //
	initial begin
		clk = 1;
		forever #(CLK_PERIOD/2) clk = ~clk;
	end

	initial begin
        rst_n = 1;
        #(CLK_PERIOD*2000) rst_n = 0;
        #(CLK_PERIOD*1000) rst_n = 1;  
	end


    initial begin
        start_switch = 0;
		wait (rst_n == 0);
		wait (rst_n == 1);
        #(CLK_PERIOD*4000);
        @(negedge clk);
        start_switch = 1;
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

    top_AB_pa test(
        .clk(clk),
        .rst_n(rst_n),

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
        .B_Secretkey_addrb(Bsecretkey_addrb),   //0~32767
        .B_Secretkey_clkb(Bsecretkey_clkb),      
        .B_Secretkey_dinb(Bsecretkey_dinb),
        .B_Secretkey_enb(Bsecretkey_enb),           //1'b1
        .B_Secretkey_rstb(Bsecretkey_rstb),          //1'b0
        .B_Secretkey_web(Bsecretkey_web),      


        .A_pa_finish(A_pa_finish),                     //pa is done
        .A_pa_fail(A_pa_fail),                       //pa is fail due to error secret key length

        .B_pa_finish(B_pa_finish),                     //pa is done
        .B_pa_fail(B_pa_fail),                       //pa is fail due to error secret key length

        .B_reset_pa_parameter(B_reset_pa_parameter)               //

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