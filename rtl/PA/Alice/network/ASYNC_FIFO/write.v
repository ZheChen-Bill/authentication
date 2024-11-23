`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/03 15:21:43
// Design Name: 
// Module Name: write
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


module write #
(
    parameter     AWIDTH = 4
)
(
    input                   wclk,   
    input                   arst_n, 
    input                   wdv,
    input      [AWIDTH:0]   rgray,  // gray read pointer from reader to writer 
    output     [AWIDTH:0]   wgray,  // gray write pointer from  writer to reader 
    output     [AWIDTH-1:0] waddr,  // write address for the FIFO buffer
    output reg              wfull,  // FIFO full indicator for the writing circuit
    output                  wen    
);


// internal nets
    reg [AWIDTH:0]  rgray_step1;        
    reg [AWIDTH:0]  rgray_wsync;       
    wire [AWIDTH:0] rgray_wsync_bin;    
    reg [AWIDTH:0]  wbincounter;        
    wire [AWIDTH:0] wbincounter_next;   

    assign waddr = wbincounter[AWIDTH-1:0];
    assign wen = wdv && !wfull;  


// Synchronize rgray in wclk domain (2 stage FF synchronizer)
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n) begin
            rgray_step1 <= 0;
            rgray_wsync  <= 0;
        end else begin
            rgray_step1 <= rgray;
            rgray_wsync <= rgray_step1;
        end
    end


// binary counter
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n)
            wbincounter <= 0;
        else
            wbincounter <= wbincounter_next;
    end

    assign wbincounter_next = (wen) ? (wbincounter + 1'b1) : wbincounter;


// binary to gray conversion
    bin2gray #(.SIZE(AWIDTH+1))
        bin2gray (
            .bin       (wbincounter ),
            .gray      (wgray       )
        );

// gray to binary conversion
    gray2bin #(.SIZE(AWIDTH+1))
        gray2bin (
            .gray      (rgray_wsync         ),
            .bin       (rgray_wsync_bin)
        );


// Full logic
    always @(posedge wclk, negedge arst_n) begin
        if (!arst_n)
            wfull <= 0;
        else begin
            wfull <= (rgray_wsync_bin == {~wbincounter_next[AWIDTH], wbincounter_next[AWIDTH-1:0]});
        end
    end
endmodule
