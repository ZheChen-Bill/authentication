`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 02:22:23
// Design Name: 
// Module Name: top
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


module top#(parameter TAGP_LENGTH = 192,
                   parameter KEYP_LENGTH = 186,
                   parameter KEYT_LENGTH = 231,
                   parameter TAG_WIDTH = 40,
                   parameter MESSAGE_WIDTH = 8,
                   parameter pADDR_WIDTH = 32,
                   parameter pDATA_WIDTH = 64
)
(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    input wire [(MESSAGE_WIDTH-1):0] ss_tdata,
    input wire ss_tvalid,
    output wire ss_tready, 
    
    output wire                     awready,
    output wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output wire                     rvalid,
    output wire [(pDATA_WIDTH-1):0] rdata,   
    
    output wire [(TAG_WIDTH-1):0] sm_tdata,
    output wire sm_tvalid,
    input wire sm_tready
);

    reg [(pDATA_WIDTH-1):0] polynomial_key1;
    reg [(pDATA_WIDTH-1):0] polynomial_key2;
    reg [(pDATA_WIDTH-1):0] polynomial_key3; // need 182 bit
    
    reg [(pDATA_WIDTH-1):0] toeplitz_key1;
    reg [(pDATA_WIDTH-1):0] toeplitz_key2;
    reg [(pDATA_WIDTH-1):0] toeplitz_key3;
    reg [(pDATA_WIDTH-1):0] toeplitz_key4; // need 231 bit

    reg [(pDATA_WIDTH-1):0] OTP_key1; // need 40 bit

    reg rvalid_reg;
    reg [(pDATA_WIDTH-1):0] rdata_reg;
    reg [(pADDR_WIDTH-1):0] awaddr_reg;
    reg [(pADDR_WIDTH-1):0] araddr_reg;

    wire [(TAGP_LENGTH-1):0] tagp;
    wire tagp_valid;
    wire tagp_ready;
    wire [(KEYP_LENGTH-1):0] polynomial_key;
    wire [(KEYT_LENGTH-1):0] toeplitz_key;
    wire [(TAG_WIDTH-1):0] OTP_key;
    wire [(TAG_WIDTH-1):0] dout;
    wire dout_valid;
    wire dout_ready;
    // Write address handshake
    assign awready = 1'b1;
    assign wready   = 1'b1;
    // Read address handshake
    assign arready = 1'b1;
    assign rvalid = rvalid_reg;
    assign rdata = rdata_reg;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            awaddr_reg <= 0;
        end else begin
            if (awvalid) begin
                awaddr_reg <= awaddr;
            end else begin
                awaddr_reg <= awaddr_reg;
            end
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            araddr_reg <= 0;
        end else begin
            if (arvalid) begin
                araddr_reg <= araddr;
            end else begin
                araddr_reg <= araddr_reg;
            end
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            polynomial_key1 <= 0;
            polynomial_key2 <= 0;
            polynomial_key3 <= 0;
            toeplitz_key1 <= 0;
            toeplitz_key2 <= 0;
            toeplitz_key3 <= 0;
            toeplitz_key4 <= 0;
            OTP_key1 <= 0;
        end else begin
            if (wvalid && awvalid) begin
                case (awaddr)
                    32'h0000_0000: begin
                        polynomial_key1 <= wdata;
                    end
                    32'h0000_0008: begin
                        polynomial_key2 <= wdata;
                    end
                    32'h0000_0010: begin
                        polynomial_key3 <= wdata;
                    end
                    32'h0000_0018: begin
                        toeplitz_key1 <= wdata;
                    end
                    32'h0000_0020: begin
                        toeplitz_key2 <= wdata;
                    end
                    32'h0000_0028: begin
                        toeplitz_key3 <= wdata;
                    end
                    32'h0000_0030: begin
                        toeplitz_key4 <= wdata;
                    end
                    32'h0000_0038: begin
                        OTP_key1 <= wdata;
                    end
                endcase
            end else if (wvalid) begin
                case (awaddr_reg)
                    32'h0000_0000: begin
                        polynomial_key1 <= wdata;
                    end
                    32'h0000_0008: begin
                        polynomial_key2 <= wdata;
                    end
                    32'h0000_0010: begin
                        polynomial_key3 <= wdata;
                    end
                    32'h0000_0018: begin
                        toeplitz_key1 <= wdata;
                    end
                    32'h0000_0020: begin
                        toeplitz_key2 <= wdata;
                    end
                    32'h0000_0028: begin
                        toeplitz_key3 <= wdata;
                    end
                    32'h0000_0030: begin
                        toeplitz_key4 <= wdata;
                    end
                    32'h0000_0038: begin
                        OTP_key1 <= wdata;
                    end
                endcase
            end else begin
                polynomial_key1 <= polynomial_key1;
                polynomial_key2 <= polynomial_key2;
                polynomial_key3 <= polynomial_key3;
                toeplitz_key1 <= toeplitz_key1;
                toeplitz_key2 <= toeplitz_key2;
                toeplitz_key3 <= toeplitz_key3;
                toeplitz_key4 <= toeplitz_key4;
                OTP_key1 <= OTP_key1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rvalid_reg <= 0;
            rdata_reg <= 0;
        end else begin
            // Read data
            if (arvalid && rready) begin
                rvalid_reg <= 1'b1;
                case (araddr)
                    32'h0000_0000: begin
                        rdata_reg <= polynomial_key1;
                    end
                    32'h0000_0008: begin
                        rdata_reg <= polynomial_key2;
                    end
                    32'h0000_0010: begin
                        rdata_reg <= polynomial_key3;
                    end
                    32'h0000_0018: begin
                        rdata_reg <= toeplitz_key1;
                    end
                    32'h0000_0020: begin
                        rdata_reg <= toeplitz_key2;
                    end
                    32'h0000_0028: begin
                        rdata_reg <= toeplitz_key3;
                    end
                    32'h0000_0030: begin
                        rdata_reg <= toeplitz_key4;
                    end
                    32'h0000_0038: begin
                        rdata_reg <= OTP_key1;
                    end                   
                    default: rdata_reg <= 32'h0000_0000;
                endcase
             end else if (arvalid) begin
                rvalid_reg <= 1'b1;
                case (araddr_reg)
                    32'h0000_0000: begin
                        rdata_reg <= polynomial_key1;
                    end
                    32'h0000_0008: begin
                        rdata_reg <= polynomial_key2;
                    end
                    32'h0000_0010: begin
                        rdata_reg <= polynomial_key3;
                    end
                    32'h0000_0018: begin
                        rdata_reg <= toeplitz_key1;
                    end
                    32'h0000_0020: begin
                        rdata_reg <= toeplitz_key2;
                    end
                    32'h0000_0028: begin
                        rdata_reg <= toeplitz_key3;
                    end
                    32'h0000_0030: begin
                        rdata_reg <= toeplitz_key4;
                    end
                    32'h0000_0038: begin
                        rdata_reg <= OTP_key1;
                    end                   
                    default: rdata_reg <= 32'h0000_0000;
                endcase
             end else begin
                rvalid_reg <= 1'b0;
                rdata_reg <= 32'h0000_0000;
             end
        end
    end
    
    assign polynomial_key = {polynomial_key3[57:0], polynomial_key2, polynomial_key1};
    assign toeplitz_key = {toeplitz_key4[38:0], toeplitz_key3, toeplitz_key2, toeplitz_key1};
    assign OTP_key = OTP_key1[39:0];
    
    polynomial u_polynomial(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    
    .ss_tdata(ss_tdata),
    .ss_tvalid(ss_tvalid),
    .ss_tready(ss_tready), 
    
    .polynomial_key(polynomial_key),
    
    .sm_tdata(tagp),
    .sm_tvalid(tagp_valid),
    .sm_tready(tagp_ready)
    );
    
    toeplitz u_toeplitz(
    .clk(clk),
    .rst_n(rst_n),  
      
    .ss_tdata(tagp),
    .ss_tvalid(tagp_valid),
    .ss_tready(tagp_ready), 
    
    .toeplitz_key(toeplitz_key),
    
    .sm_tdata(dout),
    .sm_tvalid(dout_valid),
    .sm_tready(dout_ready)
    );
    assign sm_tdata = (dout ^ OTP_key);
    assign sm_tvalid = dout_valid;
    assign dout_ready = sm_tready;
    endmodule
