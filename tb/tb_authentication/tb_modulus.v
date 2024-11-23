`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/11 13:28:13
// Design Name: 
// Module Name: tb_modulus
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


module tb_modulus(

    );
    parameter CLK_PERIOD = 10; // 100MHz
    parameter p=32'd4294967291;
    
    reg clk;
    reg rst_n;
    reg [63:0] divident;
    wire [31:0] quotient;
    wire [31:0] remainder;
    reg [63:0] loop_count;
    reg [31:0] quotient_golden;
    reg [31:0] remainder_golden;        
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
        divident <= 0;
        divider(divident, quotient_golden, remainder_golden);
		wait (rst_n == 0);
		wait (rst_n == 1);
        #(CLK_PERIOD*100);
        divident <= {$random,$random};
        divider(divident, quotient_golden, remainder_golden);
        #(CLK_PERIOD);
        for (loop_count = 0; loop_count < (10000); loop_count = loop_count+1) begin
            divident <= {$random,$random};
            divider(divident, quotient_golden, remainder_golden);
            #(CLK_PERIOD);
        end
        $display("Check the result : quotient error count = %d , remainder error count = %d", quotient_error_count, remainder_error_count);
        #(CLK_PERIOD);
        $finish;
    end
    
    modulus dut (
    .clk(clk),
    .rst_n(rst_n),
    .divident(divident),
    .quotient(quotient),
    .remainder(remainder)
    );
    
    task divider;
    input [63:0] din;
    output [31:0] q_out;
    output [31:0] remainder_out;
    begin
        q_out = (din/p);
        remainder_out = (din%p);
    end
    endtask
endmodule
