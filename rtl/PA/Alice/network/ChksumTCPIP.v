`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/30 21:05:21
// Design Name: 
// Module Name: ChksumTCPIP
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


module ChksumTCPIP(
    input clk,
    input reset,
    
    input [31:0] data,
    input data_vld,
    input data_last,
    output [15:0] chksum,
    output reg chksum_vld,
    input chksum_ready
    );
    reg [19:0] chksum_pre_next, chksum_pre;
    reg chksum_vld_next;
    
    assign chksum = ~(chksum_pre[15:0] + {12'd0, chksum_pre[19:16]});   
    always @(posedge clk or posedge reset) begin 
        if (reset) begin 
            chksum_pre <= 20'd0;
            chksum_vld <= 1'b0;
        end else begin 
            chksum_pre <= chksum_pre_next;
            chksum_vld <= chksum_vld_next;
        end 
    end  
    always @* begin 
        chksum_pre_next = chksum_pre;
        if (chksum_ready) begin 
            chksum_pre_next = 20'd0;
        end 
        if (data_vld) begin 
            chksum_pre_next = {4'd0, chksum_pre[15:0]} + 
            {4'd0, data[31:16]} + {4'd0, data[15:0]}+
            {16'd0, chksum_pre[19:16]};
        end 
    end 
    always @* begin 
        chksum_vld_next = chksum_vld;
        if (~chksum_vld) begin 
            if (data_last) begin 
                chksum_vld_next = 1'b1;
            end 
        end else begin 
            if (chksum_ready) begin 
                chksum_vld_next = 1'b0;
            end 
        end 
    end 
endmodule
