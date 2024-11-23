`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/03 15:21:43
// Design Name: 
// Module Name: asynchronous_fifo
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


// TOP-level module
module asynchronous_fifo #
(
    parameter     DEPTH = 16,
    parameter     AWIDTH = 3,
    parameter     DWIDTH = 32
)
(
    input                   arst_n,

    input                   wclk,   
    input                   wdv,    
    input   [DWIDTH-1:0]    wdata,  
    output                  wfull,  

    input                   rclk,   
    input                   rrq,    
    output  [DWIDTH-1:0]    rdata,  
    output                  rempty, 
    output                  rdv
);


    // internal nets
    wire [AWIDTH:0]     rgray;
    wire [AWIDTH:0]     wgray;
    wire [AWIDTH-1:0]   waddr;
    wire [AWIDTH-1:0]   raddr;
    wire                wen;
    wire                ren;


// Write logic
write  #(.AWIDTH(AWIDTH))
  write
(
    .wclk       (wclk   ),
    .arst_n     (arst_n ),
    .wdv        (wdv    ),
    .rgray      (rgray  ),
    .wgray      (wgray  ),
    .waddr      (waddr  ),
    .wfull      (wfull  ),
    .wen        (wen    )
);

// Read logic
read  #(.AWIDTH(AWIDTH))
  read
(
    .rclk       (rclk   ),
    .arst_n     (arst_n ),
    .rrq        (rrq    ),
    .wgray      (wgray  ),
    .rgray      (rgray  ),
    .raddr      (raddr  ),
    .rempty     (rempty ),
    .ren        (ren    )
);


// Block RAM
Bram  #(
    .DEPTH(DEPTH),
    .DWIDTH(DWIDTH)
)
  Bram
(
    .arst_n  (arst_n  ),
    .wclk    (wclk    ),
    .wen     (wen     ),
    .waddr   (wgray   ),
    .wdata   (wdata   ),
    .rclk    (rclk    ),
    .raddr   (rgray   ),
    .rdata   (rdata   ),
    .ren     (ren     ),
    .rdv     (rdv     )
);


endmodule
