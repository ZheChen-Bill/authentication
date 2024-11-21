`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 02:22:23
// Design Name: 
// Module Name: polynomial
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


module polynomial #(parameter MESSAGE_WIDTH = 8,
                              parameter MESSAGE_LENGTH = 248,
                              parameter LAMBDA = 6,
                              parameter OMEGA = 31,
                              parameter KEYP_LENGTH = 186,
                              parameter TAGP_LENGTH = 192
)
(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    input wire [(MESSAGE_WIDTH-1):0] ss_tdata,
    input wire ss_tvalid,
    output wire ss_tready, 
    input wire [(KEYP_LENGTH-1):0] polynomial_key,
    
    output wire [(TAGP_LENGTH-1):0] sm_tdata,
    output wire sm_tvalid,
    input wire sm_tready
);
    localparam
    COUNTER_BIT = log2(MESSAGE_LENGTH/MESSAGE_WIDTH);
    reg  [(MESSAGE_LENGTH-1):0] shift_reg_1;
    reg  [(MESSAGE_LENGTH-1):0] shift_reg_2;
    reg  switch, switch_delay;
    wire [(MESSAGE_LENGTH-1):0] shift_reg;
    wire [(OMEGA-1):0] message [0:((MESSAGE_LENGTH/OMEGA)-1)];
    reg  [(COUNTER_BIT-1):0] data_count;
    reg valid;
    wire [(OMEGA-1):0] key [0:(LAMBDA-1)];
//--------------------------------------- serial to parallel ----------------------------------
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_count <= 0;
        end else begin
            if (start) begin
                data_count <= 0;
            end else if (data_count == ((MESSAGE_LENGTH/MESSAGE_WIDTH)-1)) begin
                data_count <= 0;
            end else if (ss_tvalid && ss_tready) begin
                data_count <= data_count +1'b1;
            end else begin
                data_count <= data_count;
            end
        end
    end
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid <= 1'b0;
        end else begin
            if (start) begin
                valid <= 1'b1;
            end else if (data_count == ((MESSAGE_LENGTH/MESSAGE_WIDTH)-1)) begin
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
   
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            shift_reg_1 <= 0;
            shift_reg_2 <= 0;
        end else begin
            if (~switch) begin
                if (sm_tvalid) begin
                    shift_reg_2 <= 0;
                end else begin
                    shift_reg_2 <= shift_reg_2;
                end
                if (ss_tvalid && ss_tready) begin
                    shift_reg_1 <= {shift_reg_1[((MESSAGE_LENGTH-1)-MESSAGE_WIDTH):0],ss_tdata};
                end else begin
                    shift_reg_1 <= shift_reg_1;
                end
            end else begin
                if (sm_tvalid) begin
                    shift_reg_1 <= 0;
                end else begin
                    shift_reg_1 <= shift_reg_1;
                end
                if (ss_tvalid && ss_tready) begin
                    shift_reg_2 <= {shift_reg_2[((MESSAGE_LENGTH-1)-MESSAGE_WIDTH):0],ss_tdata};
                end else begin
                    shift_reg_2 <= shift_reg_2;
                end
            end
        end
    end 
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            switch <= 0;
        end else begin
            if (start) begin
                switch <= ~switch;
            end else if (data_count == ((MESSAGE_LENGTH/MESSAGE_WIDTH)-1)) begin
                switch <= ~switch;
            end else begin
                switch <= switch;
            end
        end
    end 
    always@ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            switch_delay <= 0;
        end else begin
            switch_delay <= switch;
        end
    end 
    assign shift_reg = (~switch_delay)? shift_reg_1 : shift_reg_2;
    genvar k;
    generate
            for (k=0; k<(MESSAGE_LENGTH/OMEGA); k=k+1) begin : message_assignment
                assign message[k] = (valid)? shift_reg[(MESSAGE_LENGTH-1)-(31*k)-:31]: message[k];
            end
    endgenerate
//--------------------------------------- serial to parallel ----------------------------------
//--------------------------------------- Key Assignment ----------------------------------
    genvar i;
    generate
        for (i=0; i<LAMBDA; i=i+1) begin : key_assignment
            assign key[i] = polynomial_key[(KEYP_LENGTH-1)-(31*i)-:31];
        end
    endgenerate
//--------------------------------------- Key Assignment ----------------------------------
//---------------------------------- Polynomial Hashing Operation ----------------------
    reg  [31:0] prevmessage [0:(LAMBDA-1)];
    reg  [31:0] prevkey  [0:(LAMBDA-1)];
    reg [63:0] divident_m [0:(LAMBDA-1)]; // combinational usage
    reg [63:0] divident_m_delay [0:(LAMBDA-1)]; // combinational usage
    reg [63:0] divident_k [0:(LAMBDA-1)];  // combinational usage
    wire [31:0] remainder_m [0:(LAMBDA-1)];
    wire [31:0] remainder_k [0:(LAMBDA-1)];
    reg  [(COUNTER_BIT):0] operation_count;
    reg  count_en, count_en_delay;
    
    genvar ii;
    generate
        for (ii=0; ii<LAMBDA; ii=ii+1) begin : out_tmp
            always@* begin
                if (~rst_n) begin
                    prevmessage[ii] <= 32'd0;
                end else begin
                    if (count_en||count_en_delay) begin
                        prevmessage[ii] <= remainder_m[ii];
                    end else begin
                        prevmessage[ii] <= prevmessage[ii];
                    end
                end
            end 
        end
    endgenerate
    
    genvar jj;
    generate
        for (jj=0; jj<LAMBDA; jj=jj+1) begin : key_tmp
            always@* begin
                if (~rst_n) begin
                    prevkey[jj] = 32'd1;
                end else begin
                    if (prevmessage[jj]==divident_m_delay[jj]) begin
                        prevkey[jj] = prevkey[jj];
                    end else if (count_en||count_en_delay) begin
                        prevkey[jj] = remainder_k[jj];
                    end else begin
                        prevkey[jj] = prevkey[jj];
                    end
                end
            end 
        end
    endgenerate
    
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            count_en <= 1'b0;
        end else begin
            if (valid) begin
                count_en <= 1'b1;
            end else if (operation_count == ((MESSAGE_LENGTH/OMEGA)-1))begin
                count_en <= 1'b0;
            end else begin
                count_en <= count_en;
            end
        end
    end
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            count_en_delay <= 1'b0;
        end else begin
            count_en_delay <= count_en;
        end
    end
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            operation_count <= 0;
        end else begin
            if (operation_count ==((MESSAGE_LENGTH/OMEGA)-1)) begin
                operation_count <= 0;
            end else if (count_en||valid) begin
                operation_count <= operation_count + 1'b1;
            end else begin
                operation_count <= operation_count;
            end
        end
    end
    genvar kk;
    generate
        for (kk=0; kk<LAMBDA; kk=kk+1) begin : modulus_generate
            always@* begin
                if (~rst_n) begin
                    divident_m[kk] = 0;
                end else begin
                    if (valid) begin
                        divident_m[kk] = remainder_m[kk] + message[operation_count]* prevkey[kk];
                    end else if (count_en) begin
                        divident_m[kk] = remainder_m[kk] + message[operation_count]* prevkey[kk];
                    end else begin
                        divident_m[kk] = divident_m[kk];
                    end
                end
            end 
            always@(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    divident_m_delay[kk] <= 0;
                end else begin
                    divident_m_delay[kk] <= divident_m[kk];
                end
            end
            always@ * begin
                if (~rst_n) begin
                    divident_k[kk] = 0;
                end else begin
                    if (divident_m[kk]== divident_m_delay[kk]) begin
                        divident_k[kk] = prevkey[kk];
                    end else if (valid) begin
                        divident_k[kk] = prevkey[kk] * key[kk];
                    end else if (count_en) begin
                        divident_k[kk] = prevkey[kk] * key[kk];
                    end else begin
                        divident_k[kk] = divident_k[kk];
                    end
                end
            end 
            modulus message_i(
                .clk(clk),
                .rst_n(rst_n),
                .divident(divident_m[kk]),
                .quotient(),
                .remainder(remainder_m[kk])
            );
            modulus key_i(
                .clk(clk),
                .rst_n(rst_n),
                .divident(divident_k[kk]),
                .quotient(),
                .remainder(remainder_k[kk])
            );
        end
    endgenerate

//---------------------------------- Polynomial Hashing Operation -----------------------
//------------------------------------------ Output Data ------------------------------------
reg output_valid;
wire [(TAGP_LENGTH-1):0] tagp;
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            output_valid <= 1'b0;
        end else begin
            if (operation_count ==((MESSAGE_LENGTH/OMEGA)-1)) begin
                output_valid <= 1'b1;
            end else begin
                output_valid <= 1'b0;
            end
        end
    end
assign sm_tvalid = output_valid;
assign tagp = {prevmessage[5],prevmessage[4],prevmessage[3],prevmessage[2],prevmessage[1],prevmessage[0]} ;
assign sm_tdata = tagp;
//------------------------------------------ Output Data ------------------------------------
//------------------------------------------ Input Ready ------------------------------------
assign ss_tready = 1'b1;
//------------------------------------------ Input Ready ------------------------------------

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
