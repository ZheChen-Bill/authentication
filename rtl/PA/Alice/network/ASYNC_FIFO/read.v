`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/03 15:21:43
// Design Name: 
// Module Name: read
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


module read #
(
    parameter     AWIDTH = 4
)
(
    input                   rclk,   
    input                   arst_n, 
    input                   rrq,   
    input       [AWIDTH:0]   wgray,  // gray write pointer from writer to reader (for safe synchronization across clock domains)
    output     [AWIDTH:0]   rgray,  // gray read pointer from reader to writer  (for safe synchronization across clock domains)
    output     [AWIDTH-1:0] raddr,  // read address for the FIFO buffer
    output reg             rempty, // FIFO empty indicator for the reading circuit
    output                  ren     
);


    reg [AWIDTH:0]  wgray_step1;        
    reg [AWIDTH:0]  wgray_rsync;        
    wire [AWIDTH:0] wgray_rsync_bin;   
    reg [AWIDTH:0]  rbincounter;        
    wire [AWIDTH:0] rbincounter_next;   

    assign raddr = rbincounter[AWIDTH-1:0]; 
    assign ren = rrq && !rempty; 


// Synchronize wgray in rclk domain (2 stage FF synchronizer)
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n) begin
            wgray_step1 <= 0;
            wgray_rsync  <= 0;
        end else begin
            wgray_step1 <= wgray;
            wgray_rsync <= wgray_step1;
        end
    end


// binary counter
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n)
            rbincounter <= 0;
        else
            rbincounter <= rbincounter_next;
    end

    assign rbincounter_next = (ren) ? (rbincounter + 1'b1) : rbincounter;

// binary to gray conversion
    bin2gray #(.SIZE(AWIDTH+1))
        bin2gray (
            .bin       (rbincounter),
            .gray      (rgray)
        );

// gray to binary conversion
    gray2bin #(.SIZE(AWIDTH+1))
        gray2bin (
            .gray      (wgray_rsync),
            .bin       (wgray_rsync_bin)
        );


// Empty logic
    always @(posedge rclk, negedge arst_n) begin
        if (!arst_n)
            rempty <= 0;
        else begin
            rempty <= (wgray_rsync_bin == rbincounter_next);
        end
    end

endmodule
