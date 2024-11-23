//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Mon May 27 03:10:50 2024
//Host        : DESKTOP-650NISA running 64-bit major release  (build 9200)
//Command     : generate_target JTAG_wrapper.bd
//Design      : JTAG_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module JTAG_wrapper
   (bram_addrb_1,
    bram_clkb_1,
    bram_dinb_1,
    bram_enb_1,
    bram_rstb_1,
    bram_web_1,
    clk_in_100M,
    reset);
  input [31:0]bram_addrb_1;
  input bram_clkb_1;
  input [63:0]bram_dinb_1;
  input bram_enb_1;
  input bram_rstb_1;
  input [7:0]bram_web_1;
  input clk_in_100M;
  input reset;

  wire [31:0]bram_addrb_1;
  wire bram_clkb_1;
  wire [63:0]bram_dinb_1;
  wire bram_enb_1;
  wire bram_rstb_1;
  wire [7:0]bram_web_1;
  wire clk_in_100M;
  wire reset;

  JTAG JTAG_i
       (.bram_addrb_1(bram_addrb_1),
        .bram_clkb_1(bram_clkb_1),
        .bram_dinb_1(bram_dinb_1),
        .bram_enb_1(bram_enb_1),
        .bram_rstb_1(bram_rstb_1),
        .bram_web_1(bram_web_1),
        .clk_in_100M(clk_in_100M),
        .reset(reset));
endmodule
