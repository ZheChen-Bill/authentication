`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/11 05:24:07
// Design Name: 
// Module Name: modulus
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

//Barrett Reduction modulus
module modulus #(parameter p=32'd4294967291, // 2**32-5
                           parameter bit = 64
)
(
    input wire clk,
    input wire rst_n,
    input wire [63:0] divident,
    output wire [31:0] quotient,
    output wire [31:0] remainder
);
    localparam u = 33'd4294967301; // (2**64/p)
    reg [31:0] quotient_out;
    reg [64:0] remainder_FF;
    wire [96:0] quotient_FF;
    wire [63:0] multiplier;
    wire [31:0] quotient_next;
    
    assign quotient_FF = (divident * u) >> bit;
    assign multiplier = quotient_FF[31:0] * p;
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            remainder_FF <= 65'd0;
        end else begin
            remainder_FF <= {1'b0, divident} - {1'b0, multiplier};
        end
    end

    assign remainder = (remainder_FF[64]) ? (remainder_FF[31:0]+p) : (remainder_FF >= p) ? (remainder_FF[31:0]-p) : (remainder_FF[31:0]);
    assign quotient_next = (remainder_FF[64]) ? (quotient_FF[31:0]-1) : (remainder_FF >= p) ? (quotient_FF[31:0]+1) : (quotient_FF[31:0]);
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            quotient_out <= 0;
        end else begin
            quotient_out <= quotient_next;
        end
    end
    assign quotient = quotient_out;
endmodule
