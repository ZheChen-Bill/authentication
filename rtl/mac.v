`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/17 02:09:11
// Design Name: 
// Module Name: mac
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


module mac #(parameter TAGP_LENGTH = 192)
(
    input clk,      //clk
    input rst_n,    //reset

    input [(TAGP_LENGTH-1):0] random_bit,
    input [(TAGP_LENGTH-1):0] key_bit,

    output reg sum_bit
);
    wire next_sum_bit;
    wire [(TAGP_LENGTH-1):0] and_result;
    //next sum bit
//    assign next_sum_bit = ((^and_result)^(sum_bit));
    assign next_sum_bit = ((^and_result));

    // AND gate
    assign and_result = random_bit & key_bit;

    //sum bit DFF
    always @(posedge clk ) begin
        if (~rst_n) begin
            sum_bit <= 0;
        end
        else begin
            sum_bit <= next_sum_bit;
        end
    end

endmodule