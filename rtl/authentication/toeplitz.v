`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 02:22:23
// Design Name: 
// Module Name: toeplitz
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


module toeplitz#(parameter TAGP_LENGTH = 192,
                         parameter KEYT_LENGTH = 231,
                         parameter TAGT_LENGTH = 40
)
(
    input wire clk,
    input wire rst_n,
    input wire [(TAGP_LENGTH-1):0] ss_tdata,
    input wire ss_tvalid,
    output wire ss_tready, 
    
    input wire [(KEYT_LENGTH-1):0] toeplitz_key,
    
    output wire [(TAGT_LENGTH-1):0] sm_tdata,
    output wire sm_tvalid,
    input wire sm_tready
);
//****************************** MAC input ******************************

    wire [(TAGP_LENGTH-1):0] tagp;
    wire [(KEYT_LENGTH-TAGP_LENGTH):0] tagt;
    //192 random_bit * 40
    wire [(TAGP_LENGTH-1):0]  key_in   [0:(TAGT_LENGTH-1)];
    
    assign tagp = ss_tdata;
    genvar i;
    generate
        for (i=0 ; i<TAGT_LENGTH ; i=i+1) begin
            assign key_in[i] = {toeplitz_key[i+: TAGP_LENGTH]};
        end
    endgenerate
//****************************** MAC input ******************************
//****************************** MAC instantiation ******************************
    genvar mac_idx;
    generate
        for (mac_idx=0 ; mac_idx<TAGT_LENGTH ; mac_idx=mac_idx+1) begin
            mac mac_i(
                .clk(clk),      //clk
                .rst_n(rst_n),    //reset

                .random_bit(tagp),
                .key_bit(key_in[mac_idx]),

                .sum_bit(tagt[mac_idx])
            );
        end
    endgenerate
//****************************** MAC instantiation ******************************
//------------------------------------------ Output Data ------------------------------------
reg output_valid;
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            output_valid <= 1'b0;
        end else begin
            if (ss_tvalid) begin
                output_valid <= 1'b1;
            end else begin
                output_valid <= 1'b0;
            end
        end
    end
assign sm_tvalid = output_valid;
assign sm_tdata = tagt;
//------------------------------------------ Output Data ------------------------------------
//------------------------------------------ Input Ready ------------------------------------
assign ss_tready = 1'b1;
//------------------------------------------ Input Ready ------------------------------------
endmodule
