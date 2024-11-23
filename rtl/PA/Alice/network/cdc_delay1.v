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


module cdc_delay1
#(parameter DATA_BITS = 1)
(
    input wire clk_src,
    input wire clk_des,
    input wire reset,
    input wire [DATA_BITS-1:0] pulse_src,
    output reg [DATA_BITS-1:0] pulse_des
);
 (* ASYNC_REG = "TRUE" *)  reg [DATA_BITS-1:0] pulse_delay;
 (* ASYNC_REG = "TRUE" *)  reg [DATA_BITS-1:0] pulse_delay2;
    always @(posedge clk_src or posedge reset) begin
        if (reset) begin
            pulse_delay <= {DATA_BITS{1'b0}};
        end else begin
            pulse_delay <= pulse_src[DATA_BITS-1:0];
        end
    end

    always @(posedge clk_des or posedge reset) begin
        if(reset) begin
            pulse_delay2 <= {DATA_BITS{1'b0}};
            pulse_des  <= {DATA_BITS{1'b0}};
        end else begin
            pulse_delay2 <= pulse_delay[DATA_BITS-1:0];
            pulse_des  <= pulse_delay2[DATA_BITS-1:0];
        end
    end
endmodule
