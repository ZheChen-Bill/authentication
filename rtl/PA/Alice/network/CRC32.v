`timescale 1ns / 1ps

module CRC32(
input tx_clk,
input tx_rstb,
input [63:0]packet_in,
input [7:0]keep,
input valid_in,
//input start,
input last,
output reg valid_out,
output reg [63:0]packet_out,
output reg [7:0]control_out,
output reg last_out,
output reg [31:0] crc32_out,
output wire crc32_valid
    );
reg rst,valid_pip,valid_pip_next,valid_pip1;
reg last_pip,last_pip_next,last_pip1_next,last_pip1,last_pip2,last_pip2_next,last_out_next;
reg [31:0]FCS_tmp,FCS_tmp_reg,FCS_next,FCS,D;
reg [63:0]inframe,packet_out_next,packet_pip,packet_pip_next;
reg [31:0]matrix0_0,matrix0_1,matrix0_2,matrix0_3,matrix0_4,matrix0_5,matrix0_6,matrix0_7,matrix0_8,matrix0_9,matrix0_10,matrix0_11,matrix0_12,matrix0_13,matrix0_14,matrix0_15,matrix0_16,matrix0_17,matrix0_18;
reg [31:0]matrix0_19,matrix0_20,matrix0_21,matrix0_22,matrix0_23,matrix0_24,matrix0_25,matrix0_26,matrix0_27,matrix0_28,matrix0_29,matrix0_30,matrix0_31;
reg [31:0]matrix1_0,matrix1_1,matrix1_2,matrix1_3,matrix1_4,matrix1_5,matrix1_6,matrix1_7,matrix1_8,matrix1_9,matrix1_10,matrix1_11,matrix1_12,matrix1_13,matrix1_14,matrix1_15,matrix1_16,matrix1_17,matrix1_18;
reg [31:0]matrix1_19,matrix1_20,matrix1_21,matrix1_22,matrix1_23,matrix1_24,matrix1_25,matrix1_26,matrix1_27,matrix1_28,matrix1_29,matrix1_30,matrix1_31;
reg [31:0]matrix0_0_next,matrix0_1_next,matrix0_2_next,matrix0_3_next,matrix0_4_next,matrix0_5_next,matrix0_6_next,matrix0_7_next,matrix0_8_next,matrix0_9_next,matrix0_10_next,matrix0_11_next,matrix0_12_next,matrix0_13_next,matrix0_14_next,matrix0_15_next,matrix0_16_next,matrix0_17_next,matrix0_18_next;
reg [31:0]matrix0_19_next,matrix0_20_next,matrix0_21_next,matrix0_22_next,matrix0_23_next,matrix0_24_next,matrix0_25_next,matrix0_26_next,matrix0_27_next,matrix0_28_next,matrix0_29_next,matrix0_30_next,matrix0_31_next;
reg [7:0]keep_reg,keep_reg_next;
reg [7:0]control_out_next;
always@*
if(last)
    keep_reg_next=keep;
else
    keep_reg_next=keep_reg;

always@*
if(valid_in)
    valid_pip_next=1'b1;
else
    valid_pip_next=1'b0;

always@*
    valid_out=valid_pip1|/*last_pip|*/last_pip1|last_pip2|last_out;

always@*
    rst=(~tx_rstb)|last_out;

always@*
    last_out_next=last_pip2;

reg valid_in_del;
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
	valid_in_del <= 1'b0;
else
	valid_in_del <= valid_in;

wire start = valid_in & (~valid_in_del);

always@*
if(valid_in & last)
   /* if(keep[0]&keep[1]&keep[2]&keep[3])
        begin
            last_pip2_next=1'b0;
            last_pip1_next=1'b0;
            last_pip_next=1'b1;
        end
    else*/
        begin
            last_pip2_next=1'b0;
            last_pip1_next=1'b1;
            last_pip_next=1'b0;
        end
else
    begin
        last_pip2_next=last_pip1;
        last_pip1_next=last_pip;
        last_pip_next=1'b0;
    end
    
always@*
    if(start)
        inframe={
                 packet_in[56],packet_in[57],packet_in[58],packet_in[59],packet_in[60],packet_in[61],packet_in[62],packet_in[63],
                 packet_in[48],packet_in[49],packet_in[50],packet_in[51],packet_in[52],packet_in[53],packet_in[54],packet_in[55],
                 packet_in[40],packet_in[41],packet_in[42],packet_in[43],packet_in[44],packet_in[45],packet_in[46],packet_in[47],
                 packet_in[32],packet_in[33],packet_in[34],packet_in[35],packet_in[36],packet_in[37],packet_in[38],packet_in[39],
                 ~packet_in[24],~packet_in[25],~packet_in[26],~packet_in[27],~packet_in[28],~packet_in[29],~packet_in[30],~packet_in[31],
                 ~packet_in[16],~packet_in[17],~packet_in[18],~packet_in[19],~packet_in[20],~packet_in[21],~packet_in[22],~packet_in[23],
                 ~packet_in[8],~packet_in[9],~packet_in[10],~packet_in[11],~packet_in[12],~packet_in[13],~packet_in[14],~packet_in[15],
                 ~packet_in[0],~packet_in[1],~packet_in[2],~packet_in[3],~packet_in[4],~packet_in[5],~packet_in[6],~packet_in[7]
                 };
    else if(valid_in)
        inframe={
                 packet_in[56],packet_in[57],packet_in[58],packet_in[59],packet_in[60],packet_in[61],packet_in[62],packet_in[63],
                 packet_in[48],packet_in[49],packet_in[50],packet_in[51],packet_in[52],packet_in[53],packet_in[54],packet_in[55],
                 packet_in[40],packet_in[41],packet_in[42],packet_in[43],packet_in[44],packet_in[45],packet_in[46],packet_in[47],
                 packet_in[32],packet_in[33],packet_in[34],packet_in[35],packet_in[36],packet_in[37],packet_in[38],packet_in[39],
                 packet_in[24],packet_in[25],packet_in[26],packet_in[27],packet_in[28],packet_in[29],packet_in[30],packet_in[31],
                 packet_in[16],packet_in[17],packet_in[18],packet_in[19],packet_in[20],packet_in[21],packet_in[22],packet_in[23],
                 packet_in[8],packet_in[9],packet_in[10],packet_in[11],packet_in[12],packet_in[13],packet_in[14],packet_in[15],
                 packet_in[0],packet_in[1],packet_in[2],packet_in[3],packet_in[4],packet_in[5],packet_in[6],packet_in[7]
                 };
    else
        inframe=64'd0;   
        
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    control_out<=8'hff;
else if(last_out)
    control_out<=8'hff;
else if(start)
    control_out<=8'h01;
else
    control_out<=control_out_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    keep_reg<=8'd0;
else
    keep_reg<=keep_reg_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    last_out<=1'd0;
else
    last_out<=last_out_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    valid_pip<=1'd0;
else
    valid_pip<=valid_pip_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    valid_pip1<=1'd0;
else
    valid_pip1<=valid_pip;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    last_pip<=1'd0;
else
    last_pip<=last_pip_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    last_pip1<=1'd0;
else
    last_pip1<=last_pip1_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    last_pip2<=1'd0;
else
    last_pip2<=last_pip2_next;    

always@(posedge tx_clk or posedge rst)
if(rst)
    FCS<=32'd0;
else
    FCS<=FCS_next;
    
always@(posedge tx_clk or posedge rst)
if(rst)
    FCS_tmp_reg<=32'd0;
else
    FCS_tmp_reg<=FCS_tmp;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    packet_out<=64'd0;
else
    packet_out<=packet_out_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    packet_pip<=64'd0;
else
    packet_pip<=packet_pip_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_31<=32'd0;
else
    matrix0_31<=matrix0_31_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_30<=32'd0;
else
    matrix0_30<=matrix0_30_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_29<=32'd0;
else
    matrix0_29<=matrix0_29_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_28<=32'd0;
else
    matrix0_28<=matrix0_28_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_27<=32'd0;
else
    matrix0_27<=matrix0_27_next;
   
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_26<=32'd0;
else
    matrix0_26<=matrix0_26_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_25<=32'd0;
else
    matrix0_25<=matrix0_25_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_24<=32'd0;
else
    matrix0_24<=matrix0_24_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_23<=32'd0;
else
    matrix0_23<=matrix0_23_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_22<=32'd0;
else
    matrix0_22<=matrix0_22_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_21<=32'd0;
else
    matrix0_21<=matrix0_21_next;    
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_20<=32'd0;
else
    matrix0_20<=matrix0_20_next;
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_19<=32'd0;
else
    matrix0_19<=matrix0_19_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_18<=32'd0;
else
    matrix0_18<=matrix0_18_next;   
 
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_17<=32'd0;
else
    matrix0_17<=matrix0_17_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_16<=32'd0;
else
    matrix0_16<=matrix0_16_next;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_15<=32'd0;
else
    matrix0_15<=matrix0_15_next;
   
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_14<=32'd0;
else
    matrix0_14<=matrix0_14_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_13<=32'd0;
else
    matrix0_13<=matrix0_13_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_12<=32'd0;
else
    matrix0_12<=matrix0_12_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_11<=32'd0;
else
    matrix0_11<=matrix0_11_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_10<=32'd0;
else
    matrix0_10<=matrix0_10_next;     
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_9<=32'd0;
else
    matrix0_9<=matrix0_9_next;
 
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_8<=32'd0;
else
    matrix0_8<=matrix0_8_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_7<=32'd0;
else
    matrix0_7<=matrix0_7_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_6<=32'd0;
else
    matrix0_6<=matrix0_6_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_5<=32'd0;
else
    matrix0_5<=matrix0_5_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_4<=32'd0;
else
    matrix0_4<=matrix0_4_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_3<=32'd0;
else
    matrix0_3<=matrix0_3_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_2<=32'd0;
else
    matrix0_2<=matrix0_2_next;
    
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_1<=32'd0;
else
    matrix0_1<=matrix0_1_next;            

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
    matrix0_0<=32'd0;
else
    matrix0_0<=matrix0_0_next;   
    


always@*
begin
    FCS_next[31]=(^(matrix1_31 & FCS_tmp))^inframe[39];
    FCS_next[30]=(^(matrix1_30 & FCS_tmp))^inframe[38];
    FCS_next[29]=(^(matrix1_29 & FCS_tmp))^inframe[37];
    FCS_next[28]=(^(matrix1_28 & FCS_tmp))^inframe[36];
    FCS_next[27]=(^(matrix1_27 & FCS_tmp))^inframe[35];
    FCS_next[26]=(^(matrix1_26 & FCS_tmp))^inframe[34];
    FCS_next[25]=(^(matrix1_25 & FCS_tmp))^inframe[33];
    FCS_next[24]=(^(matrix1_24 & FCS_tmp))^inframe[32];
    FCS_next[23]=(^(matrix1_23 & FCS_tmp))^inframe[47];
    FCS_next[22]=(^(matrix1_22 & FCS_tmp))^inframe[46];
    FCS_next[21]=(^(matrix1_21 & FCS_tmp))^inframe[45];
    FCS_next[20]=(^(matrix1_20 & FCS_tmp))^inframe[44];
    FCS_next[19]=(^(matrix1_19 & FCS_tmp))^inframe[43];
    FCS_next[18]=(^(matrix1_18 & FCS_tmp))^inframe[42];
    FCS_next[17]=(^(matrix1_17 & FCS_tmp))^inframe[41];
    FCS_next[16]=(^(matrix1_16 & FCS_tmp))^inframe[40];
    FCS_next[15]=(^(matrix1_15 & FCS_tmp))^inframe[55];
    FCS_next[14]=(^(matrix1_14 & FCS_tmp))^inframe[54];
    FCS_next[13]=(^(matrix1_13 & FCS_tmp))^inframe[53];
    FCS_next[12]=(^(matrix1_12 & FCS_tmp))^inframe[52];
    FCS_next[11]=(^(matrix1_11 & FCS_tmp))^inframe[51];
    FCS_next[10]=(^(matrix1_10 & FCS_tmp))^inframe[50];
    FCS_next[9]=(^(matrix1_9 & FCS_tmp))^inframe[49];
    FCS_next[8]=(^(matrix1_8 & FCS_tmp))^inframe[48];
    FCS_next[7]=(^(matrix1_7 & FCS_tmp))^inframe[63];
    FCS_next[6]=(^(matrix1_6 & FCS_tmp))^inframe[62];
    FCS_next[5]=(^(matrix1_5 & FCS_tmp))^inframe[61];
    FCS_next[4]=(^(matrix1_4 & FCS_tmp))^inframe[60];
    FCS_next[3]=(^(matrix1_3 & FCS_tmp))^inframe[59];
    FCS_next[2]=(^(matrix1_2 & FCS_tmp))^inframe[58];
    FCS_next[1]=(^(matrix1_1 & FCS_tmp))^inframe[57];
    FCS_next[0]=(^(matrix1_0 & FCS_tmp))^inframe[56];
end

always@*
begin
    FCS_tmp[31]=(^(matrix0_31 & FCS))^inframe[7];
    FCS_tmp[30]=(^(matrix0_30 & FCS))^inframe[6];
    FCS_tmp[29]=(^(matrix0_29 & FCS))^inframe[5];
    FCS_tmp[28]=(^(matrix0_28 & FCS))^inframe[4];
    FCS_tmp[27]=(^(matrix0_27 & FCS))^inframe[3];
    FCS_tmp[26]=(^(matrix0_26 & FCS))^inframe[2];
    FCS_tmp[25]=(^(matrix0_25 & FCS))^inframe[1];
    FCS_tmp[24]=(^(matrix0_24 & FCS))^inframe[0];
    FCS_tmp[23]=(^(matrix0_23 & FCS))^inframe[15];
    FCS_tmp[22]=(^(matrix0_22 & FCS))^inframe[14];
    FCS_tmp[21]=(^(matrix0_21 & FCS))^inframe[13];
    FCS_tmp[20]=(^(matrix0_20 & FCS))^inframe[12];
    FCS_tmp[19]=(^(matrix0_19 & FCS))^inframe[11];
    FCS_tmp[18]=(^(matrix0_18 & FCS))^inframe[10];
    FCS_tmp[17]=(^(matrix0_17 & FCS))^inframe[9];
    FCS_tmp[16]=(^(matrix0_16 & FCS))^inframe[8];
    FCS_tmp[15]=(^(matrix0_15 & FCS))^inframe[23];
    FCS_tmp[14]=(^(matrix0_14 & FCS))^inframe[22];
    FCS_tmp[13]=(^(matrix0_13 & FCS))^inframe[21];
    FCS_tmp[12]=(^(matrix0_12 & FCS))^inframe[20];
    FCS_tmp[11]=(^(matrix0_11 & FCS))^inframe[19];
    FCS_tmp[10]=(^(matrix0_10 & FCS))^inframe[18];
    FCS_tmp[9]=(^(matrix0_9 & FCS))^inframe[17];
    FCS_tmp[8]=(^(matrix0_8 & FCS))^inframe[16];
    FCS_tmp[7]=(^(matrix0_7 & FCS))^inframe[31];
    FCS_tmp[6]=(^(matrix0_6 & FCS))^inframe[30];
    FCS_tmp[5]=(^(matrix0_5 & FCS))^inframe[29];
    FCS_tmp[4]=(^(matrix0_4 & FCS))^inframe[28];
    FCS_tmp[3]=(^(matrix0_3 & FCS))^inframe[27];
    FCS_tmp[2]=(^(matrix0_2 & FCS))^inframe[26];
    FCS_tmp[1]=(^(matrix0_1 & FCS))^inframe[25];
    FCS_tmp[0]=(^(matrix0_0 & FCS))^inframe[24];
end

/*always@*
 D=inframe[63:32]^inframe[31:0];*/
 
always@*
case(keep)
8'b01111111:
            begin
                matrix0_31_next=32'h808B2080;
                matrix0_30_next=32'hC0459040;
                matrix0_29_next=32'hE022C820;
                matrix0_28_next=32'h70116410;
                matrix0_27_next=32'hB808B208;
                matrix0_26_next=32'hDC045904;
                matrix0_25_next=32'h6E890C02;
                matrix0_24_next=32'h37448601;
                matrix0_23_next=32'h1BA24300;
                matrix0_22_next=32'h8D5A0100;
                matrix0_21_next=32'h46262000;
                matrix0_20_next=32'hA3131000;
                matrix0_19_next=32'h51898800;
                matrix0_18_next=32'hA8C4C400;
                matrix0_17_next=32'hD4626200;
                matrix0_16_next=32'h6A313100;
                matrix0_15_next=32'h3593B800;
                matrix0_14_next=32'h9AC9DC00;
                matrix0_13_next=32'h4D64EE00;
                matrix0_12_next=32'h26B27700;
                matrix0_11_next=32'h13D21B00;
                matrix0_10_next=32'h09622D00;
                matrix0_9_next=32'h843A3600;
                matrix0_8_next=32'hC21D1B00;
                matrix0_7_next=32'hE185AD00;
                matrix0_6_next=32'h7049F600;
                matrix0_5_next=32'h3824FB00;
                matrix0_4_next=32'h1C995D00;
                matrix0_3_next=32'h0EC78E00;
                matrix0_2_next=32'h0763C700;
                matrix0_1_next=32'h033AC300;
                matrix0_0_next=32'h01164100; 
            end
8'b00111111:
            begin
                matrix0_31_next=32'h8B208000;
                matrix0_30_next=32'h45904000;
                matrix0_29_next=32'h22C82000;
                matrix0_28_next=32'h11641000;
                matrix0_27_next=32'h08B20800;
                matrix0_26_next=32'h04590400;
                matrix0_25_next=32'h890C0200;
                matrix0_24_next=32'h44860100;
                matrix0_23_next=32'hA2430080;
                matrix0_22_next=32'h5A010040;
                matrix0_21_next=32'h26200020;
                matrix0_20_next=32'h13100010;
                matrix0_19_next=32'h89880008;
                matrix0_18_next=32'hC4C40004;
                matrix0_17_next=32'h62620002;
                matrix0_16_next=32'h31310001;///????
                matrix0_15_next=32'h93B80000;
                matrix0_14_next=32'hC9DC0000;
                matrix0_13_next=32'h64EE0000;
                matrix0_12_next=32'hB2770000;
                matrix0_11_next=32'hD21B0000;
                matrix0_10_next=32'h622D0000;
                matrix0_9_next=32'h3A360000;
                matrix0_8_next=32'h1D1B0000;
                matrix0_7_next=32'h85AD0000;
                matrix0_6_next=32'h49F60000;
                matrix0_5_next=32'h24FB0000;
                matrix0_4_next=32'h995D0000;
                matrix0_3_next=32'hC78E0000;
                matrix0_2_next=32'h63C70000;
                matrix0_1_next=32'h3AC30000;
                matrix0_0_next=32'h16410000; 
            end
8'b00011111:
            begin
                matrix0_31_next=32'h20800000;
                matrix0_30_next=32'h90400000;
                matrix0_29_next=32'hC8200000;
                matrix0_28_next=32'h64100000;
                matrix0_27_next=32'hB2080000;
                matrix0_26_next=32'h59040000;
                matrix0_25_next=32'h0C020000;
                matrix0_24_next=32'h86010000;
                matrix0_23_next=32'h43008000;
                matrix0_22_next=32'h01004000;
                matrix0_21_next=32'h20002000;
                matrix0_20_next=32'h10001000;
                matrix0_19_next=32'h88000800;
                matrix0_18_next=32'hC4000400;
                matrix0_17_next=32'h62000200;
                matrix0_16_next=32'h31000100;
                matrix0_15_next=32'hB8000080;
                matrix0_14_next=32'hDC000040;
                matrix0_13_next=32'hEE000020;
                matrix0_12_next=32'h77000010;
                matrix0_11_next=32'h1B000008;
                matrix0_10_next=32'h2D000004;
                matrix0_9_next=32'h36000002;
                matrix0_8_next=32'h1B000001;
                matrix0_7_next=32'hAD000000;
                matrix0_6_next=32'hF6000000;
                matrix0_5_next=32'hFB000000;
                matrix0_4_next=32'h5D000000;
                matrix0_3_next=32'h8E000000;
                matrix0_2_next=32'hC7000000;
                matrix0_1_next=32'hC3000000;
                matrix0_0_next=32'h41000000; 
            end
default:
            begin
                matrix0_31_next=32'hFB808B20;
                matrix0_30_next=32'h7DC04590;
                matrix0_29_next=32'hBEE022C8;
                matrix0_28_next=32'h5F701164;
                matrix0_27_next=32'h2FB808B2;
                matrix0_26_next=32'h97DC0459;
                matrix0_25_next=32'hB06E890C;
                matrix0_24_next=32'h58374486;
                matrix0_23_next=32'hAC1BA243;
                matrix0_22_next=32'hAD8D5A01;
                matrix0_21_next=32'hAD462620;
                matrix0_20_next=32'h56A31310;
                matrix0_19_next=32'h2B518988;
                matrix0_18_next=32'h95A8C4C4;
                matrix0_17_next=32'hCAD46262;
                matrix0_16_next=32'h656A3131;
                matrix0_15_next=32'h493593B8;
                matrix0_14_next=32'h249AC9DC;
                matrix0_13_next=32'h924D64EE;
                matrix0_12_next=32'hC926B277;
                matrix0_11_next=32'h9F13D21B;
                matrix0_10_next=32'hB409622D;
                matrix0_9_next=32'h21843A36;
                matrix0_8_next=32'h90C21D1B;
                matrix0_7_next=32'h33E185AD;
                matrix0_6_next=32'h627049F6;
                matrix0_5_next=32'h313824FB;
                matrix0_4_next=32'hE31C995D;
                matrix0_3_next=32'h8A0EC78E;
                matrix0_2_next=32'hC50763C7;
                matrix0_1_next=32'h19033AC3;
                matrix0_0_next=32'hF7011641; 
            end
endcase


always@*
case(keep)
8'b00000111:
            begin
                matrix1_31=32'h808B2080;
                matrix1_30=32'hC0459040;
                matrix1_29=32'hE022C820;
                matrix1_28=32'h70116410;
                matrix1_27=32'hB808B208;
                matrix1_26=32'hDC045904;
                matrix1_25=32'h6E890C02;
                matrix1_24=32'h37448601;
                matrix1_23=32'h1BA24300;
                matrix1_22=32'h8D5A0100;
                matrix1_21=32'h46262000;
                matrix1_20=32'hA3131000;
                matrix1_19=32'h51898800;
                matrix1_18=32'hA8C4C400;
                matrix1_17=32'hD4626200;
                matrix1_16=32'h6A313100;
                matrix1_15=32'h3593B800;
                matrix1_14=32'h9AC9DC00;
                matrix1_13=32'h4D64EE00;
                matrix1_12=32'h26B27700;
                matrix1_11=32'h13D21B00;
                matrix1_10=32'h09622D00;
                matrix1_9=32'h843A3600;
                matrix1_8=32'hC21D1B00;
                matrix1_7=32'hE185AD00;
                matrix1_6=32'h7049F600;
                matrix1_5=32'h3824FB00;
                matrix1_4=32'h1C995D00;
                matrix1_3=32'h0EC78E00;
                matrix1_2=32'h0763C700;
                matrix1_1=32'h033AC300;
                matrix1_0=32'h01164100; 
            end
8'b00000011:
            begin
                matrix1_31=32'h8B208000;
                matrix1_30=32'h45904000;
                matrix1_29=32'h22C82000;
                matrix1_28=32'h11641000;
                matrix1_27=32'h08B20800;
                matrix1_26=32'h04590400;
                matrix1_25=32'h890C0200;
                matrix1_24=32'h44860100;
                matrix1_23=32'hA2430080;
                matrix1_22=32'h5A010040;
                matrix1_21=32'h26200020;
                matrix1_20=32'h13100010;
                matrix1_19=32'h89880008;
                matrix1_18=32'hC4C40004;
                matrix1_17=32'h62620002;
                matrix1_16=32'h31310001;///????
                matrix1_15=32'h93B80000;
                matrix1_14=32'hC9DC0000;
                matrix1_13=32'h64EE0000;
                matrix1_12=32'hB2770000;
                matrix1_11=32'hD21B0000;
                matrix1_10=32'h622D0000;
                matrix1_9=32'h3A360000;
                matrix1_8=32'h1D1B0000;
                matrix1_7=32'h85AD0000;
                matrix1_6=32'h49F60000;
                matrix1_5=32'h24FB0000;
                matrix1_4=32'h995D0000;
                matrix1_3=32'hC78E0000;
                matrix1_2=32'h63C70000;
                matrix1_1=32'h3AC30000;
                matrix1_0=32'h16410000; 
            end
8'b00000001:
            begin
                matrix1_31=32'h20800000;
                matrix1_30=32'h90400000;
                matrix1_29=32'hC8200000;
                matrix1_28=32'h64100000;
                matrix1_27=32'hB2080000;
                matrix1_26=32'h59040000;
                matrix1_25=32'h0C020000;
                matrix1_24=32'h86010000;
                matrix1_23=32'h43008000;
                matrix1_22=32'h01004000;
                matrix1_21=32'h20002000;
                matrix1_20=32'h10001000;
                matrix1_19=32'h88000800;
                matrix1_18=32'hC4000400;
                matrix1_17=32'h62000200;
                matrix1_16=32'h31000100;
                matrix1_15=32'hB8000080;
                matrix1_14=32'hDC000040;
                matrix1_13=32'hEE000020;
                matrix1_12=32'h77000010;
                matrix1_11=32'h1B000008;
                matrix1_10=32'h2D000004;
                matrix1_9=32'h36000002;
                matrix1_8=32'h1B000001;
                matrix1_7=32'hAD000000;
                matrix1_6=32'hF6000000;
                matrix1_5=32'hFB000000;
                matrix1_4=32'h5D000000;
                matrix1_3=32'h8E000000;
                matrix1_2=32'hC7000000;
                matrix1_1=32'hC3000000;
                matrix1_0=32'h41000000; 
            end
default:
            begin
                matrix1_31=32'hFB808B20;
                matrix1_30=32'h7DC04590;
                matrix1_29=32'hBEE022C8;
                matrix1_28=32'h5F701164;
                matrix1_27=32'h2FB808B2;
                matrix1_26=32'h97DC0459;
                matrix1_25=32'hB06E890C;
                matrix1_24=32'h58374486;
                matrix1_23=32'hAC1BA243;
                matrix1_22=32'hAD8D5A01;
                matrix1_21=32'hAD462620;
                matrix1_20=32'h56A31310;
                matrix1_19=32'h2B518988;
                matrix1_18=32'h95A8C4C4;
                matrix1_17=32'hCAD46262;
                matrix1_16=32'h656A3131;
                matrix1_15=32'h493593B8;
                matrix1_14=32'h249AC9DC;
                matrix1_13=32'h924D64EE;
                matrix1_12=32'hC926B277;
                matrix1_11=32'h9F13D21B;
                matrix1_10=32'hB409622D;
                matrix1_9=32'h21843A36;
                matrix1_8=32'h90C21D1B;
                matrix1_7=32'h33E185AD;
                matrix1_6=32'h627049F6;
                matrix1_5=32'h313824FB;
                matrix1_4=32'hE31C995D;
                matrix1_3=32'h8A0EC78E;
                matrix1_2=32'hC50763C7;
                matrix1_1=32'h19033AC3;
                matrix1_0=32'hF7011641; 
            end
endcase

always@*
packet_pip_next=packet_in;



always@*
if(last_pip1)
    case(keep_reg)
        8'b0000_1111:
                    begin
                     packet_out_next={
                                         ~FCS[0],~FCS[1],~FCS[2],~FCS[3],~FCS[4],~FCS[5],~FCS[6],~FCS[7],//FCS[7:0]   
                                         ~FCS[8],~FCS[9],~FCS[10],~FCS[11],~FCS[12],~FCS[13],~FCS[14],~FCS[15],//FCS[15:8]
                                         ~FCS[16],~FCS[17],~FCS[18],~FCS[19],~FCS[20],~FCS[21],~FCS[22],~FCS[23],//FCS[23:16]
                                         ~FCS[24],~FCS[25],~FCS[26],~FCS[27],~FCS[28],~FCS[29],~FCS[30],~FCS[31],//FCS[31:24]
                                         packet_pip[31:24],
                                         packet_pip[23:16],
                                         packet_pip[15:8],
                                         packet_pip[7:0]
                                     };
                     control_out_next=8'd0;
                    end
        8'b0000_0111:        
                    begin
                     packet_out_next={
                                         8'hFD,
                                         ~FCS[0],~FCS[1],~FCS[2],~FCS[3],~FCS[4],~FCS[5],~FCS[6],~FCS[7],//FCS[7:0]   
                                         ~FCS[8],~FCS[9],~FCS[10],~FCS[11],~FCS[12],~FCS[13],~FCS[14],~FCS[15],//FCS[15:8]
                                         ~FCS[16],~FCS[17],~FCS[18],~FCS[19],~FCS[20],~FCS[21],~FCS[22],~FCS[23],//FCS[23:16]
                                         ~FCS[24],~FCS[25],~FCS[26],~FCS[27],~FCS[28],~FCS[29],~FCS[30],~FCS[31],//FCS[31:24]
                                         packet_pip[23:16],
                                         packet_pip[15:8],
                                         packet_pip[7:0]  
                                     };
                     control_out_next=8'b1000_0000;
                    end
        8'b0000_0011:
                    begin
                     packet_out_next={
                                         16'h07FD,
                                         ~FCS[0],~FCS[1],~FCS[2],~FCS[3],~FCS[4],~FCS[5],~FCS[6],~FCS[7],//FCS[7:0]   
                                         ~FCS[8],~FCS[9],~FCS[10],~FCS[11],~FCS[12],~FCS[13],~FCS[14],~FCS[15],//FCS[15:8]
                                         ~FCS[16],~FCS[17],~FCS[18],~FCS[19],~FCS[20],~FCS[21],~FCS[22],~FCS[23],//FCS[23:16]
                                         ~FCS[24],~FCS[25],~FCS[26],~FCS[27],~FCS[28],~FCS[29],~FCS[30],~FCS[31],//FCS[31:24]
                                         packet_pip[15:8],
                                         packet_pip[7:0]
                                     };
                     control_out_next=8'b1100_0000;
                    end                  
        8'b0000_0001:
                    begin
                     packet_out_next={
                                         24'h0707FD,
                                         ~FCS[0],~FCS[1],~FCS[2],~FCS[3],~FCS[4],~FCS[5],~FCS[6],~FCS[7],//FCS[7:0]   
                                         ~FCS[8],~FCS[9],~FCS[10],~FCS[11],~FCS[12],~FCS[13],~FCS[14],~FCS[15],//FCS[15:8]
                                         ~FCS[16],~FCS[17],~FCS[18],~FCS[19],~FCS[20],~FCS[21],~FCS[22],~FCS[23],//FCS[23:16]
                                         ~FCS[24],~FCS[25],~FCS[26],~FCS[27],~FCS[28],~FCS[29],~FCS[30],~FCS[31],//FCS[31:24]
                                         packet_pip[7:0]       
                                     };
                     control_out_next=8'b1110_0000;
                    end
        8'b11111111:
                    begin
                     packet_out_next={
                                         packet_pip
                                     };
                     control_out_next=8'd0;
                    end
        8'b0111_1111:
                    begin
                     packet_out_next={
                                         ~FCS_tmp[24],~FCS_tmp[25],~FCS_tmp[26],~FCS_tmp[27],~FCS_tmp[28],~FCS_tmp[29],~FCS_tmp[30],~FCS_tmp[31],
                                         packet_pip[55:48],
                                         packet_pip[47:40],
                                         packet_pip[39:32],
                                         packet_pip[31:24],
                                         packet_pip[23:16],
                                         packet_pip[15:8],
                                         packet_pip[7:0]
                                     };
                     control_out_next=8'd0;
                    end
        8'b0011_1111:
                    begin
                     packet_out_next={  
                                         ~FCS_tmp[16],~FCS_tmp[17],~FCS_tmp[18],~FCS_tmp[19],~FCS_tmp[20],~FCS_tmp[21],~FCS_tmp[22],~FCS_tmp[23],
                                         ~FCS_tmp[24],~FCS_tmp[25],~FCS_tmp[26],~FCS_tmp[27],~FCS_tmp[28],~FCS_tmp[29],~FCS_tmp[30],~FCS_tmp[31],                                       
                                         packet_pip[47:40],
                                         packet_pip[39:32],
                                         packet_pip[31:24],
                                         packet_pip[23:16],
                                         packet_pip[15:8],
                                         packet_pip[7:0]
                                     };
                     control_out_next=8'd0;
                    end
        8'b0001_1111:
                    begin
                     packet_out_next={
                                         ~FCS_tmp[8],~FCS_tmp[9],~FCS_tmp[10],~FCS_tmp[11],~FCS_tmp[12],~FCS_tmp[13],~FCS_tmp[14],~FCS_tmp[15],
                                         ~FCS_tmp[16],~FCS_tmp[17],~FCS_tmp[18],~FCS_tmp[19],~FCS_tmp[20],~FCS_tmp[21],~FCS_tmp[22],~FCS_tmp[23],
                                         ~FCS_tmp[24],~FCS_tmp[25],~FCS_tmp[26],~FCS_tmp[27],~FCS_tmp[28],~FCS_tmp[29],~FCS_tmp[30],~FCS_tmp[31],                                                       
                                         packet_pip[39:32],
                                         packet_pip[31:24],
                                         packet_pip[23:16],
                                         packet_pip[15:8],
                                         packet_pip[7:0]
                                     };
                     control_out_next=8'd0;
                    end
       default:
                    begin
                     packet_out_next={
                                         packet_pip
                                     };
                     control_out_next=8'd0;
                    end
   endcase
else if(last_pip2)
   case(keep_reg)
        8'b0000_1111:
                    begin
                     packet_out_next={
                                         64'h07070707070707FD
                                     };
                     control_out_next=8'b1111_1111;
                    end
        8'b1111_1111:
                    begin
                     packet_out_next={
                                         32'h070707FD,
                                         ~FCS_tmp_reg[0],~FCS_tmp_reg[1],~FCS_tmp_reg[2],~FCS_tmp_reg[3],~FCS_tmp_reg[4],~FCS_tmp_reg[5],~FCS_tmp_reg[6],~FCS_tmp_reg[7],
                                         ~FCS_tmp_reg[8],~FCS_tmp_reg[9],~FCS_tmp_reg[10],~FCS_tmp_reg[11],~FCS_tmp_reg[12],~FCS_tmp_reg[13],~FCS_tmp_reg[14],~FCS_tmp_reg[15],
                                         ~FCS_tmp_reg[16],~FCS_tmp_reg[17],~FCS_tmp_reg[18],~FCS_tmp_reg[19],~FCS_tmp_reg[20],~FCS_tmp_reg[21],~FCS_tmp_reg[22],~FCS_tmp_reg[23],
                                         ~FCS_tmp_reg[24],~FCS_tmp_reg[25],~FCS_tmp_reg[26],~FCS_tmp_reg[27],~FCS_tmp_reg[28],~FCS_tmp_reg[29],~FCS_tmp_reg[30],~FCS_tmp_reg[31]  
                                     };
                     control_out_next=8'b1111_0000;
                    end
        8'b0111_1111:
                    begin
                     packet_out_next={   
                                         40'h07070707FD,
                                         ~FCS_tmp_reg[0],~FCS_tmp_reg[1],~FCS_tmp_reg[2],~FCS_tmp_reg[3],~FCS_tmp_reg[4],~FCS_tmp_reg[5],~FCS_tmp_reg[6],~FCS_tmp_reg[7],
                                         ~FCS_tmp_reg[8],~FCS_tmp_reg[9],~FCS_tmp_reg[10],~FCS_tmp_reg[11],~FCS_tmp_reg[12],~FCS_tmp_reg[13],~FCS_tmp_reg[14],~FCS_tmp_reg[15],
                                         ~FCS_tmp_reg[16],~FCS_tmp_reg[17],~FCS_tmp_reg[18],~FCS_tmp_reg[19],~FCS_tmp_reg[20],~FCS_tmp_reg[21],~FCS_tmp_reg[22],~FCS_tmp_reg[23]
                                     };
                     control_out_next=8'b1111_1000;
                    end
        8'b0011_1111:
                    begin
                     packet_out_next={
                                         48'h0707070707FD,
                                         ~FCS_tmp_reg[0],~FCS_tmp_reg[1],~FCS_tmp_reg[2],~FCS_tmp_reg[3],~FCS_tmp_reg[4],~FCS_tmp_reg[5],~FCS_tmp_reg[6],~FCS_tmp_reg[7],
                                         ~FCS_tmp_reg[8],~FCS_tmp_reg[9],~FCS_tmp_reg[10],~FCS_tmp_reg[11],~FCS_tmp_reg[12],~FCS_tmp_reg[13],~FCS_tmp_reg[14],~FCS_tmp_reg[15]
                                     };
                     control_out_next=8'b1111_1100;
                    end
        8'b0001_1111:
                    begin
                     packet_out_next={
                                         56'h070707070707FD,
                                         ~FCS_tmp_reg[0],~FCS_tmp_reg[1],~FCS_tmp_reg[2],~FCS_tmp_reg[3],~FCS_tmp_reg[4],~FCS_tmp_reg[5],~FCS_tmp_reg[6],~FCS_tmp_reg[7]
                                     };
                     control_out_next=8'b1111_1110;
                    end
       default:
                    begin
                     packet_out_next=64'h0707070707070707;
                     control_out_next=8'b1111_1111;
                    end
   endcase
else        
begin
packet_out_next=
                {
                    packet_pip
                };
control_out_next= valid_in? 8'h0: control_out;//8'd0;
end


wire [31:0] inv_FCS_tmp;
wire [31:0] inv_FCS_next;

genvar i;
generate
for(i=0;i<32;i=i+1)begin
assign inv_FCS_tmp      [i] = ~FCS_tmp [31-i];    
assign inv_FCS_next     [i] = ~FCS_next[31-i];
end
endgenerate


reg last_d;
reg crc32_true;
reg [7:0] keep_d;

always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)begin
    crc32_out <=32'd0;
    crc32_true <= 1'b0;
end
else if(start)begin
    crc32_out <=32'd0;
    crc32_true <= 1'b0;
end
else if(last) 
	case(keep)
		8'h0: begin
			crc32_out <= inv_FCS_tmp;
			crc32_true <= 1'b1;
		end
		8'h1: begin
			crc32_out <= inv_FCS_next;
			crc32_true <= 1'b1;
		end
		8'h3: begin
			crc32_out <= inv_FCS_next;
			crc32_true <= 1'b1;
		end
		8'h7: begin
			crc32_out <= inv_FCS_next;
			crc32_true <= 1'b1;
		end
		8'hf: begin
			crc32_out <= inv_FCS_next;
			crc32_true <= 1'b1;
		end
	endcase
else if(last_d)
	case(keep_d)
		8'h1f: begin
			crc32_out <=  inv_FCS_tmp;
			crc32_true <= 1'b1;
		end
		8'h3f: begin
			crc32_out <=  inv_FCS_tmp;
			crc32_true <= 1'b1;
		end
		8'h7f: begin
			crc32_out <=  inv_FCS_tmp;
			crc32_true <= 1'b1;
		end
		8'hff: begin
			crc32_out <=  inv_FCS_tmp;
			crc32_true <= 1'b1;
		end


	endcase


reg true_d;
always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)begin
	last_d <= 1'h0;
	true_d <= 1'b0;
end
else begin
	last_d <= last;
	true_d <= crc32_true;
end


always@(posedge tx_clk or negedge tx_rstb)
if(!tx_rstb)
	keep_d <= 8'h0;
else if(last)
	keep_d <= keep;

assign crc32_valid = crc32_true &(~true_d); 

endmodule
