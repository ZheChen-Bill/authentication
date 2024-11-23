



`include "./pa_parameter.v"
`include "./packet_parameter.v"

module A2B_test (

    input clk,
    input rst_n,


    input reset_pa_parameter,
    output PArandombit_full,

    // A_A2B pa fifo
    output wire A_TX_pa_rd_clk,
    output wire A_TX_pa_rd_en,
    input wire [31:0] A_TX_pa_rd_dout,
    input wire A_TX_pa_empty,
    input wire A_TX_pa_rd_valid,

    // B_A2B secret key length fifo
    output wire  B_RX_secretkey_length_wr_clk,
    output wire  [31:0] B_RX_secretkey_length_wr_din,
    output wire  B_RX_secretkey_length_wr_en,
    input wire B_RX_secretkey_length_full,
    input wire B_RX_secretkey_length_wr_ack,


    // B_A2B randombit bram
    output wire [63:0] B_RX_PArandombit_din,
    output reg [13:0] B_RX_PArandombit_addr,    //0~16383
    output wire  B_RX_PArandombit_clk,
    output wire  B_RX_PArandombit_en,            //1'b1
    output wire  B_RX_PArandombit_we,       

    output [3:0] A2B_state
);


    reg [31:0] randombit_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            randombit_bram_cnt <= 32'b0;
        end
        else if (reset_pa_parameter) begin
            randombit_bram_cnt <= 32'b0;
        end
        else if (reset_parameter && (packet_type==`A2B_PA_RANDOMBIT)) begin
            randombit_bram_cnt <= randombit_bram_cnt + 1;
        end
        else begin
            randombit_bram_cnt <= randombit_bram_cnt;
        end
    end
    assign PArandombit_full = (randombit_bram_cnt==32);






//****************************** FIFO setup ******************************
    assign B_RX_secretkey_length_wr_clk = clk;
    assign A_TX_pa_rd_clk = clk;
//****************************** FIFO setup ******************************
//****************************** BRAM setup ******************************
    assign B_RX_PArandombit_clk = clk;
    assign B_RX_PArandombit_en = 1'b1;
//****************************** BRAM setup ******************************



//****************************** A2B fsm ******************************
    wire read_header_en;
    wire reset_parameter;

    //wire setting_done;
    wire write_bram_done;
    assign write_bram_done = (write_bram_cnt==(real_depth+3))? 1'b1:1'b0;
    wire read_bram_done;
    assign read_bram_done = (read_bram_cnt==(real_depth+7))? 1'b1:1'b0;


    A2B_fsm A2B_FSM(
        .clk(clk),
        .rst_n(rst_n),

        .A_A2B_rd_valid(A_TX_pa_rd_valid),
        //.setting_done(setting_done),
        .write_bram_done(write_bram_done),
        .read_bram_done(read_bram_done),

        .reset_parameter(reset_parameter),
        .read_header_en(read_header_en),
        .A2B_state(A2B_state)
    );

//****************************** A2B fsm ******************************



//****************************** parameter ******************************
 

    reg [10:0] real_depth;
    wire [`PACKET_LENGTH_WIDTH-1:0] packet_depth;
    assign packet_depth = header_ff[27:24];

    always @(*) begin
        if (packet_depth==`PACKET_LENGTH_257) begin
            real_depth = header_ff[23:15];
        end
        else if (packet_depth==`PACKET_LENGTH_514) begin
            real_depth = 11'd512;
        end
        else if (packet_depth==`PACKET_LENGTH_771) begin
            real_depth = 11'd768;
        end
        else if (packet_depth==`PACKET_LENGTH_1028) begin
            real_depth = 11'd1024;
        end
        else begin
            real_depth = 11'd1024;
        end
    end

    wire [`PACKET_TYPE_WIDTH-1:0] packet_type;
    assign packet_type = header_ff[31:28];

    reg [31:0] header_ff;

    always @(posedge clk ) begin
        if (~rst_n)begin
            header_ff <= 32'b0;
        end
        else if (read_header_en) begin
            header_ff <= A_TX_pa_rd_dout;
        end
        else if (reset_parameter) begin
            header_ff <= 32'b0;
        end
        else begin
            header_ff <= header_ff;
        end
    end

//****************************** parameter ******************************




//****************************** write to BRAM ******************************
    reg [10:0] write_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            write_bram_cnt <= 11'b0;
        end
        else if (A2B_state==4'd3) begin
            write_bram_cnt <= write_bram_cnt + 1;
        end
        else if (reset_parameter) begin
            write_bram_cnt <= 11'b0;
        end
        else begin
            write_bram_cnt <= write_bram_cnt;
        end
    end

    assign A_TX_pa_rd_en = ((write_bram_cnt>0)&&(write_bram_cnt<(real_depth+2)))? 1'b1:1'b0;


    reg wea;
    reg [10:0] addra;
    reg [31:0] dina;

    always @(posedge clk ) begin
        if (~rst_n) begin
            addra <= 11'b0;
            wea <= 1'b0;
            dina <= 32'b0;
        end
        else if (A_TX_pa_rd_en) begin
            addra <= write_bram_cnt-1;
            wea <= 1'b1;
            dina <= A_TX_pa_rd_dout;
        end
        else begin
            addra <= 11'b0;
            wea <= 1'b0;
            dina <= 32'b0;
        end
    end
//****************************** write to BRAM ******************************



//****************************** read from BRAM ******************************
    reg [15:0] read_bram_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            read_bram_cnt <= 16'b0;
        end
        else if (A2B_state==4'd5) begin
            read_bram_cnt <= read_bram_cnt + 1;
        end
        else if (reset_parameter) begin
            read_bram_cnt <= 16'b0;
        end
        else begin
            read_bram_cnt <= read_bram_cnt;
        end
    end


    

    reg [10:0] addrb;

    always @(posedge clk ) begin
        if (~rst_n) begin
            addrb <= 11'b0;
        end
        else if ((read_bram_cnt>0)&&(read_bram_cnt<(real_depth+2))) begin
            addrb <= read_bram_cnt-1;
        end
        else begin
            addrb <= 11'b0;
        end
    end


    wire [31:0] doutb;
    reg [31:0] doutb_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            doutb_ff <= 32'b0;
        end
        else begin
            doutb_ff <= doutb;
        end
    end


    wire B_A2B_wr_en;
    wire [31:0] B_A2B_wr_din;
    assign B_A2B_wr_en = ((read_bram_cnt>5)&&(read_bram_cnt<(real_depth+6)))? 1'b1:1'b0;
    assign B_A2B_wr_din = (B_A2B_wr_en)? doutb_ff:32'b0;


    //RX sel
    assign B_RX_secretkey_length_wr_en = (packet_type==`A2B_SECRETKEY_LENGTH)? B_A2B_wr_en:1'b0;
    assign B_RX_secretkey_length_wr_din = (packet_type==`A2B_SECRETKEY_LENGTH)? B_A2B_wr_din:32'b0;

    assign B_RX_PArandombit_we = ((packet_type==`A2B_PA_RANDOMBIT)&&B_A2B_wr_en)? 
                                        (B_RX_PArandombit_we_sel):1'b0;
    assign B_RX_PArandombit_din = ((packet_type==`A2B_PA_RANDOMBIT)&&B_RX_PArandombit_we_sel)?
                                        ({B_A2B_wr_din_delay, B_A2B_wr_din}):64'b0;


    always @(posedge clk ) begin
        if (~rst_n) begin
            B_RX_PArandombit_addr <= 14'b0;
        end
        else if (reset_pa_parameter) begin
            B_RX_PArandombit_addr <= 14'b0;
        end
        else if (B_RX_PArandombit_we) begin
            B_RX_PArandombit_addr <= B_RX_PArandombit_addr + 1;
        end
        else begin
            B_RX_PArandombit_addr <= B_RX_PArandombit_addr;
        end
    end



    // RX bram 32 bit -> randombit bram 64 bit
    reg [31:0] B_A2B_wr_din_delay;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_A2B_wr_din_delay <= 32'b0;
        end
        else begin
            B_A2B_wr_din_delay <= B_A2B_wr_din;
        end
    end

    reg B_RX_PArandombit_we_sel;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_RX_PArandombit_we_sel <= 1'b0;
        end
        else if (reset_parameter) begin
            B_RX_PArandombit_we_sel <= 1'b0;
        end
        else if (B_A2B_wr_en) begin
            B_RX_PArandombit_we_sel <= ~B_RX_PArandombit_we_sel;
        end
        else begin
            B_RX_PArandombit_we_sel <= B_RX_PArandombit_we_sel;
        end
    end
    
    

//****************************** read from BRAM ******************************





//****************************** B2A BRAM instantiation ******************************
    
    A2B_BRAM A2B_packet_bram (
        .clka(clk),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [10 : 0] addra
        .dina(dina),    // input wire [31 : 0] dina
        .douta(),  // output wire [31 : 0] douta


        .clkb(clk),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .web(1'b0),      // input wire [0 : 0] web
        .addrb(addrb),  // input wire [10 : 0] addrb
        .dinb(),    // input wire [31 : 0] dinb
        .doutb(doutb)  // output wire [31 : 0] doutb
    );

//****************************** B2A BRAM instantiation ******************************










endmodule















module A2B_fsm (
    input clk,
    input rst_n,

    input A_A2B_rd_valid,
    //input setting_done,
    input write_bram_done,
    input read_bram_done,

    output reg read_header_en,
    output reg reset_parameter,
    output reg [3:0] A2B_state

);
    localparam IDLE                 = 4'd15;
    localparam READ_HEADER          = 4'd1;
    localparam SET_PARAMETER        = 4'd2;
    localparam WRITE_BRAM           = 4'd3;
    localparam PACKET_DONE          = 4'd4;
    localparam READ_BRAM            = 4'd5;
    localparam UNPACKET_DONE        = 4'd6;
    localparam A2B_FINISH           = 4'd7;





    always @(*) begin
        case (A2B_state)
            IDLE : begin
                if (A_A2B_rd_valid) begin
                    next_A2B_state = READ_HEADER;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A2B_state = IDLE;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end 
            READ_HEADER : begin
                next_A2B_state = SET_PARAMETER;
                read_header_en = 1'b1;
                reset_parameter = 1'b0;
            end

            SET_PARAMETER : begin
                next_A2B_state = WRITE_BRAM;
                read_header_en = 1'b0;
                reset_parameter = 1'b0;
            end

            WRITE_BRAM : begin
                if (write_bram_done) begin
                    next_A2B_state = PACKET_DONE;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A2B_state = WRITE_BRAM;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end

            PACKET_DONE : begin
                next_A2B_state = READ_BRAM;
                read_header_en = 1'b0;
                reset_parameter = 1'b0;
            end

            READ_BRAM : begin
                if (read_bram_done) begin
                    next_A2B_state = UNPACKET_DONE;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
                else begin
                    next_A2B_state = READ_BRAM;
                    read_header_en = 1'b0;
                    reset_parameter = 1'b0;
                end
            end

            UNPACKET_DONE : begin
                next_A2B_state = A2B_FINISH;
                read_header_en = 1'b0;
                reset_parameter = 1'b0;
            end

            A2B_FINISH : begin
                next_A2B_state = IDLE;
                read_header_en = 1'b0;
                reset_parameter = 1'b1;
            end

            default: begin
                next_A2B_state = IDLE;
                read_header_en = 1'b0;
                reset_parameter = 1'b0;
            end
        endcase
    end






    reg [3:0] next_A2B_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A2B_state <= IDLE;
        end
        else begin
            A2B_state <= next_A2B_state;
        end
    end


    
endmodule