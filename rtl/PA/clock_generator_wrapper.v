//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Tue May 28 18:09:03 2024
//Host        : DESKTOP-650NISA running 64-bit major release  (build 9200)
//Command     : generate_target clock_generator_wrapper.bd
//Design      : clock_generator_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clock_generator_wrapper
   (clk_in1_n,
    clk_in1_p,
    clk_out1_62_5M,
    clk_out2_100M,
    clk_out3_300M,
    clk_out4_375M,
    reset);
  input clk_in1_n;
  input clk_in1_p;
  output clk_out1_62_5M;
  output clk_out2_100M;
  output clk_out3_300M;
  output clk_out4_375M;
  input reset;

  wire clk_in1_n;
  wire clk_in1_p;
  wire clk_out1_62_5M;
  wire clk_out2_100M;
  wire clk_out3_300M;
  wire clk_out4_375M;
  wire reset;

  clock_generator clock_generator_i
       (.clk_in1_n(clk_in1_n),
        .clk_in1_p(clk_in1_p),
        .clk_out1_62_5M(clk_out1_62_5M),
        .clk_out2_100M(clk_out2_100M),
        .clk_out3_300M(clk_out3_300M),
        .clk_out4_375M(clk_out4_375M),
        .reset(reset));
endmodule
