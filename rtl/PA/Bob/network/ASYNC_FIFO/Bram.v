`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/03 15:21:43
// Design Name: 
// Module Name: Bram
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


// bram behavior code (can't be synthesis)
module Bram#(    
    parameter     DEPTH = 16,
    parameter     DWIDTH = 32
)(
    input                       arst_n, 
    input                       wclk,   
    input                       wen,    
    input [AWIDTH-1:0]          waddr,  
    input [DWIDTH-1:0]          wdata,  

    input                       rclk,   
    input                       ren,    
    output reg                rdv,    
    input        [AWIDTH-1:0]    raddr,  
    output reg [DWIDTH-1:0]   rdata   
);
  localparam AWIDTH = log2(DEPTH);
  reg [DWIDTH-1:0] mem [0:DEPTH-1]; 

  always @(posedge wclk) begin
    if (wen)
      mem[waddr] <= wdata;
  end

  always @(posedge rclk or negedge arst_n) begin
    if (!arst_n)
        rdv <= 1'b0;
    else
        rdv <= ren;
  end

  // assign rdata = mem[raddr];
  always @(posedge rclk, negedge arst_n) begin
    if (!arst_n)
        rdata <= 'b0;
    else if (ren)
        rdata <= mem[raddr];
  end

function integer log2;
    input integer x;
    integer n, m;
    begin
        n = 1;
        m = 2;
        while (m < x) begin
            n = n + 1;
            m = m * 2;
        end
        log2 = n;
    end
endfunction
endmodule
