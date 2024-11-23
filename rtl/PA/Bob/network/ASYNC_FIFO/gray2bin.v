`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/03 15:21:43
// Design Name: 
// Module Name: gray2bin
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


module gray2bin #
(
    parameter SIZE = 4
)
(
    input      [SIZE-1:0] gray,
    output reg [SIZE-1:0] bin
);

    integer k;

    always @* begin // combinational logic
        for (k = 0; k < SIZE; k = k+1) begin
            bin[k] = ^(gray >> k);
        end
    end

endmodule
