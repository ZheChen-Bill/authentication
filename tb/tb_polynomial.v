`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/16 00:23:18
// Design Name: 
// Module Name: tb_polynomial
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


module tb_polynomial
#( parameter DATA_NUM = 12500
)
(

    );
    parameter CLK_PERIOD = 10; // 100MHz
    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] din;
    reg din_valid;
    wire din_ready;
    reg [185:0] polynomial_key;
    wire [191:0] dout;
    wire dout_valid;
    reg dout_ready;
    
    reg [31:0]  data_length;
    integer data_in, input_data, key, key_data, m;
    reg [7:0] Din_list [0:(DATA_NUM-1)];
    reg [30:0] key_list [0:5];
    initial begin
        data_length = 0;
        data_in = $fopen("./message.txt","r");
        key = $fopen("./polynomial_key.txt","r");
        for(m=0;m<DATA_NUM;m=m+1) begin
            input_data = $fscanf(data_in,"%b", Din_list[m]);
            data_length = data_length + 1;
        end
        for(m=0;m<6;m=m+1) begin
            key_data = $fscanf(key,"%b", key_list[m]);
            polynomial_key = {polynomial_key[154:0],key_list[m]};
        end
    end
    
    initial begin
        clk = 1;
        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end
    end
    initial begin
        rst_n = 1;
        #(CLK_PERIOD*20) rst_n = 0;
        #(CLK_PERIOD*10) rst_n = 1;      
    end

    integer i;
    initial begin
        din <= 8'd0;
        din_valid <= 1'b0;
        start <= 1'b0;
		wait (rst_n == 0);
		wait (rst_n == 1);
		#(CLK_PERIOD);
		for (i=0;i<data_length;i=i+1) begin
		  stream_din(Din_list[i]);
		end
		din_valid <= 1'b0;
		#(CLK_PERIOD*10);
		start <= 1'b1;
		#(CLK_PERIOD);
		start <= 1'b0;
		#(CLK_PERIOD*100);
		$finish;
    end
    
    initial begin
        dout_ready <= 1'b1;
    end
    
    polynomial dut(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    
    .ss_tdata(din),
    .ss_tvalid(din_valid),
    .ss_tready(din_ready), 
    
    .polynomial_key(polynomial_key),
    
    .sm_tdata(dout),
    .sm_tvalid(dout_valid),
    .sm_tready(dout_ready)
    );

    task stream_din;
        input [7:0] sm_tdata;
        begin
            din <= sm_tdata;
            din_valid <= 1;
            while (!din_ready) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
        end
    endtask
endmodule
