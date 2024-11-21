`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/17 02:49:48
// Design Name: 
// Module Name: tb_toeplitz
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


module tb_toeplitz
#( parameter CLK_PERIOD = 10 // 100MHz
)
(
    );
    reg clk;
    reg rst_n;
    reg [191:0] din;
    reg din_valid;
    wire din_ready;
    reg [230:0] toeplitz_key;
    wire [39:0] dout;
    wire dout_valid;
    reg dout_ready;
    
    
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

    initial begin
        din <= 192'd0;
        din_valid <= 1'b0;
		wait (rst_n == 0);
		wait (rst_n == 1);
		#(CLK_PERIOD);
		din <= 192'b100000100111010001001011111001000001101000000111001100100001100011110111100000110001011111010101000001010101010111100010101000010011101101001011110010110100100111000010101110111011011101011000;
		din_valid <= 1'b1;
		#(CLK_PERIOD);
		din_valid <= 1'b0;
		#(CLK_PERIOD*100);
		$finish;
    end
    
    initial begin
        toeplitz_key <= 231'b111101011010110101010001010000001000001111111000001101000100010101100110111110010001000111010000110000100110010100001100010100110111110100010001111001101011100000001100100111100110110101110000111100010010001000111111100101000010011;
    end
    
    initial begin
        dout_ready <= 1'b1;
    end
    
    toeplitz dut(
    .clk(clk),
    .rst_n(rst_n),
    
    .ss_tdata(din),
    .ss_tvalid(din_valid),
    .ss_tready(din_ready), 
    
    .toeplitz_key(toeplitz_key),
    
    .sm_tdata(dout),
    .sm_tvalid(dout_valid),
    .sm_tready(dout_ready)
    );

endmodule
