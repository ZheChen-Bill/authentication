`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/04 17:25:39
// Design Name: 
// Module Name: clock_domain_crossing
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


module clock_domain_crossing(
    input clk_src, 
    input clk_des,
    input reset,
    input pulse_src,
    output reg pulse_des
    );
    reg Tq;
    wire Tq_next;
    reg [2:0] fifo;
    wire [2:0] fifo_next;
    always @(posedge clk_src or posedge reset) begin 
        if (reset) begin 
            Tq <= 1'b0;
        end else begin 
            Tq <= Tq_next;
        end 
    end 
    assign Tq_next = Tq ^ pulse_src;
    always @(posedge clk_des or posedge reset) begin 
        if (reset) begin 
            fifo <= 3'd0;
        end else begin 
            fifo <= fifo_next;
        end 
    end 
    assign fifo_next = {fifo[1:0], Tq};
    
    wire pulse_des_next;
    always @(posedge clk_des or posedge reset) begin 
        if (reset) begin 
            pulse_des <= 1'b0;
        end else begin 
            pulse_des <= pulse_des_next;
        end 
    end 
    assign pulse_des_next = fifo[2] ^ fifo[1];
endmodule
