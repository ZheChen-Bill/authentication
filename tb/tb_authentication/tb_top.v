`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/17 04:49:12
// Design Name: 
// Module Name: tb_top
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


module tb_top
#( parameter DATA_NUM = 12500
)
(

    );
    parameter CLK_PERIOD = 10; // 100MHz
    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] din;
    reg din_valid;
    wire din_ready;
    
    reg   awvalid;
    wire  awready;
    reg  [31:0] awaddr;
    reg  wvalid;
    wire wready;
    reg  [63:0] wdata;

    reg   arvalid;
    wire  arready;
    reg  [31:0] araddr;
    wire rvalid;
    reg  rready;
    wire [63:0] rdata;
    
    reg [63:0] configuration_data;
    
    reg [39:0] XOR_key;
    reg [185:0] polynomial_key;
    reg [230:0] toeplitz_key;

    wire [191:0] tagp;
    wire tagp_valid;
    wire tagp_ready;
    
    wire [39:0] dout;    
    wire dout_valid;
    reg dout_ready;
    
    reg [31:0] data_length;
    integer data_in, input_data, key_p, key_p_data, key_t, key_t_data, otp_key, otp_key_data, m;
    reg [7:0] Din_list [0:(DATA_NUM-1)];
    reg [30:0] key_p_list [0:5];
    reg [230:0] key_t_list;
    reg [39:0] otp_key_list;
    initial begin
        data_length = 0;
        data_in = $fopen("./message.txt","r");
        key_p = $fopen("./polynomial_key.txt","r");
        key_t  = $fopen("./toeplitz_key.txt","r");
        otp_key = $fopen("./otp_key.txt","r");
        for(m=0;m<DATA_NUM;m=m+1) begin
            input_data = $fscanf(data_in,"%b", Din_list[m]);
            data_length = data_length + 1;
        end
        
        for(m=0;m<6;m=m+1) begin
            key_p_data = $fscanf(key_p,"%b", key_p_list[m]);
            polynomial_key = {polynomial_key[154:0], key_p_list[m]};
        end

        for(m=0;m<1;m=m+1) begin
            key_t_data = $fscanf(key_t,"%b", key_t_list);
            toeplitz_key = key_t_list;
        end
        
        for(m=0;m<1;m=m+1) begin
            otp_key_data = $fscanf(otp_key,"%b", otp_key_list);
            XOR_key = otp_key_list;
        end
    end
    
    initial begin
        clk = 1;
        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end
    end
    
    initial begin
        rst_n = 1;
        #(CLK_PERIOD*20) rst_n = 0;
        #(CLK_PERIOD*10) rst_n = 1;      
    end
    // configuration
    integer k;
    initial begin
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
		wait (rst_n == 0);
		wait (rst_n == 1);
		#(CLK_PERIOD);
		

		for (k=0;k<2;k=k+1) begin // polynomial key
		  axilite_write(32'h0000_0000+(8*(k)),polynomial_key[(64*(k))+:64]);
		end
		axilite_write(32'h0000_0010,{6'b0,polynomial_key[185:128]});
		
        awvalid <= 1'b0;
        wvalid  <= 1'b0;
        arvalid <= 1'b0;
        #(CLK_PERIOD*10);
        
        for (k=0;k<2;k=k+1) begin // polynomial key
		  axilite_read(32'h0000_0000+(8*(k)), configuration_data);
		end
		axilite_read(32'h0000_0010, configuration_data);
		
		awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
        #(CLK_PERIOD*10);
        
	    for (k=0;k<3;k=k+1) begin // toeplitz key
		  axilite_write_delay(32'h0000_0018+(8*(k)),toeplitz_key[(64*(k))+:64]);
		end
		axilite_write_delay(32'h0000_0030,{25'b0,toeplitz_key[230:192]});

		awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
        #(CLK_PERIOD*10); 
        
		for (k=0;k<3;k=k+1) begin // toeplitz key
		  axilite_read_delay(32'h0000_0018+(8*(k)), configuration_data);
		end
		axilite_read_delay(32'h0000_0030, configuration_data);
		
		awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
        #(CLK_PERIOD*10); 
		axilite_write(32'h0000_0038, XOR_key);
		awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
        #(CLK_PERIOD);
		axilite_read(32'h0000_0038, configuration_data);
		
		awvalid <= 1'b0;
        wvalid <= 1'b0;
        arvalid <= 1'b0;
    end
    // stream_in
    integer i;
    initial begin 
        din <= 8'd0;
        din_valid <= 1'b0;
        start <= 1'b0;
		wait (rst_n == 0);
		wait (rst_n == 1);
		#(CLK_PERIOD*100);
		for (i=0;i<data_length;i=i+1) begin
		  stream_din(Din_list[i]);
		end
		din_valid <= 1'b0;
		#(CLK_PERIOD*10);
		start <= 1'b1;
		#(CLK_PERIOD);
		start <= 1'b0;
		#(CLK_PERIOD*100);
		$finish;
    end
       
    initial begin
        dout_ready <= 1'b1;
        rready <= 1'b1;
    end
    
    top authentication_dut(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
    
        .ss_tdata(din),
        .ss_tvalid(din_valid),
        .ss_tready(din_ready), 
    
        .awvalid(awvalid),
        .awready(awready),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wready(wready),
        .wdata(wdata),
        
        .arvalid(arvalid),
        .arready(arready),
        .araddr(araddr),
        .rvalid(rvalid),
        .rready(rready),
        .rdata(rdata),
        
        .sm_tdata(dout),
        .sm_tvalid(dout_valid),
        .sm_tready(dout_ready)
);

    task stream_din;
        input [7:0] sm_tdata;
        begin
            din <= sm_tdata;
            din_valid <= 1;
            while (!din_ready) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
        end
    endtask
    
    task axilite_write;
        input [31:0] write_address;
        input [63:0] write_config;
        begin
            awvalid <= 1'b1;
            awaddr <= write_address;
            wvalid <= 1'b1;
            wdata <= write_config;
            while ((!awready) && (!wready)) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
        end
    endtask
    
    task axilite_write_delay;
        input [31:0] write_address;
        input [63:0] write_config;
        begin
            awvalid <= 1'b1;
            awaddr <= write_address;
            wvalid <= 1'b0;
            while (!awready) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
            awvalid <= 1'b0;
            #(CLK_PERIOD);
            #(CLK_PERIOD);
            #(CLK_PERIOD);
            wvalid <= 1'b1;
            wdata <= write_config;
            while (!wready) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
        end
    endtask
    
    task axilite_read;
        input [31:0] read_address;
        output [63:0] read_config;
        begin
            arvalid <= 1'b1;
            araddr <= read_address;
            while ((!arready) & (!rvalid)) begin
                #(CLK_PERIOD);
            end
            read_config <= rdata;
            #(CLK_PERIOD);
        end
    endtask
    
    task axilite_read_delay;
        input [31:0] read_address;
        output [63:0] read_config;
        begin
            arvalid <= 1'b1;
            araddr <= read_address;
            while (!arready) begin
                #(CLK_PERIOD);
            end
            #(CLK_PERIOD);
            arvalid <= 1'b0;
            #(CLK_PERIOD);
            #(CLK_PERIOD);
            #(CLK_PERIOD);
            read_config <= rdata;
            #(CLK_PERIOD);
        end
    endtask
endmodule
