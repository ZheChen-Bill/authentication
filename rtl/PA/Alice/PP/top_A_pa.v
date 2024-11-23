






`include "../pa_parameter.v"
`include "../packet_parameter.v"



module top_A_pa (
    input clk,                              //clk
    input rst_n,                            //reset

    input start_A_pa,                       //start to pa

    output A_pa_finish,                     //pa is done
    output A_pa_fail,                       //pa is fail due to error secret key length


    input [31:0] secretkey_length,   //secret key length

    input reconciled_key_addr_index,                        //address index
                                                            //0:addr0 ~ addr16383
                                                            //1:addr16384 ~ addr32767


    // reconciled key BRAM (input)
    // width = 64, depth = 32768
    // port B
    input wire [63 : 0] key_doutb,  
    output wire key_clkb,
    output wire key_enb,            //1'b1
    output wire key_web,            //1'b0
    output wire key_rstb,           //1'b0
    output wire [14 : 0] key_index_and_addrb,   //0~32767


    //Random bit BRAM (input)
    // width = 64 , depth = 16384
    // port B
    input wire [63:0]PArandombit_doutb,
    output wire [13:0]PArandombit_addrb,    //0~16383
    output wire PArandombit_clkb,
    //output wire [63:0]PArandombit_dinb,
    output wire PArandombit_enb,            //1'b1
    output wire PArandombit_rstb,           //1'b0
    output wire [7:0]PArandombit_web,       //8'b0


    //Secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]Secretkey_addrb,   //0~32767
    output wire Secretkey_clkb,      
    output wire [63:0]Secretkey_dinb,
    output wire Secretkey_enb,           //1'b1
    output wire Secretkey_rstb,          //1'b0
    output wire [7:0]Secretkey_web,     


    // A_TX_pa FIFO (output)
    // width = 32 , depth = 2048
    output wire A_TX_pa_wr_clk,
    output reg [31:0] A_TX_pa_wr_din,
    output reg A_TX_pa_wr_en,
    input wire A_TX_pa_full,
    input wire A_TX_pa_wr_ack,
    input wire A_TX_pa_empty
);

//****************************** BRAM setup ******************************
/*
    // reconciled key BRAM (input)
    // width = 64, depth = 32768
    // port B
    assign key_clkb = clk;
    assign key_enb = 1'b1;
    assign key_web = 1'b0;

    //Random bit BRAM (input)
    // width = 64 , depth = 16384
    // port B
    assign PArandombit_clkb = clk;
    assign PArandombit_enb = 1'b1;
    assign PArandombit_web = 8'b0;

    //Secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    assign Secretkey_clkb = clk;
    assign Secretkey_enb = 1'b1;
*/
//****************************** BRAM setup ******************************
//****************************** FIFO setup ******************************
    // A_TX_pa FIFO (output)
    // width = 32 , depth = 2048
    assign A_TX_pa_wr_clk = clk;
//****************************** FIFO setup ******************************
//****************************** DFF for bram output ******************************
    reg [63:0] PArandombit_doutb_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            PArandombit_doutb_ff <= 64'b0;
        end
        else begin
            PArandombit_doutb_ff <= PArandombit_doutb;
        end
    end
//****************************** DFF for bram output ******************************
//****************************** secretkey_length_ff ******************************
    reg [31:0] secretkey_length_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            secretkey_length_ff <= 32'b0;
        end
        else if (reset_pa_parameter) begin
            secretkey_length_ff <= 32'b0;
        end
        else if (start_A_pa) begin
            secretkey_length_ff <= secretkey_length;
        end
        else begin
            secretkey_length_ff <= secretkey_length_ff;
        end
    end
//****************************** secretkey_length_ff ******************************
//****************************** reconciled_key_addr_index_ff ******************************
    reg reconciled_key_addr_index_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            reconciled_key_addr_index_ff <= 1'b0;
        end
        else if (reset_pa_parameter) begin
            reconciled_key_addr_index_ff <= 1'b0;
        end
        else if (start_A_pa) begin
            reconciled_key_addr_index_ff <= reconciled_key_addr_index;
        end
        else begin
            reconciled_key_addr_index_ff <= reconciled_key_addr_index_ff;
        end
    end
//****************************** reconciled_key_addr_index_ff ******************************






//****************************** A pa fsm ******************************
    //fsm input
    //wire start_A_pa;
    wire send_PArandombit_finish;
    wire send_secretkey_length_finish;
    //reg [31:0] secretkey_length_ff; 
    wire finish_compute;



    //fsm output
    wire send_PArandombit_en;
    wire send_secretkey_length_en;
    wire start_pa_compute;
    wire reset_pa_parameter;
    wire compute_busy;
    //wire A_pa_finish;
    //wire A_pa_fail;

    wire [3:0] A_pa_state;

    A_pa_fsm Apa_fsm(
        .clk(clk),
        .rst_n(rst_n),

        .start_A_pa(start_A_pa),
        .send_PArandombit_finish(send_PArandombit_finish),
        .send_secretkey_length_finish(send_secretkey_length_finish),
        .secretkey_length_ff(secretkey_length_ff),
        .finish_compute(finish_compute),


        .send_PArandombit_en(send_PArandombit_en),
        .send_secretkey_length_en(send_secretkey_length_en),
        .start_pa_compute(start_pa_compute),
        .reset_pa_parameter(reset_pa_parameter),
        .A_pa_finish(A_pa_finish),
        .A_pa_fail(A_pa_fail),
        .compute_busy(compute_busy),
        .A_pa_state(A_pa_state)
    );



//****************************** A pa fsm ******************************











//****************************** send PA random bit ******************************
    //wire send_PArandombit_en;
    //wire send_PArandombit_finish;

    //fsm input
    wire send_randombit_en;
    wire round_count_finish;
    wire last_round;
    
    assign send_randombit_en = send_PArandombit_en;

    //fsm output
    wire round_count_en;
    wire reset_randombit_cnt;
    wire reset_round_cnt;

    wire [19:0] randombit_round_addr_offset;
    wire [7:0] randombit_round;
    wire [3:0] randombit_state;


    send_randombit_fsm randombit_fsm(
        .clk(clk),
        .rst_n(rst_n),


        .send_randombit_en(send_randombit_en),
        .A_TX_pa_empty(A_TX_pa_empty),
        .round_count_finish(round_count_finish),
        .last_round(last_round),


        .round_count_en(round_count_en),
        .reset_randombit_cnt(reset_randombit_cnt),
        .send_randombit_finish(send_PArandombit_finish),
        .reset_round_cnt(reset_round_cnt),

        .randombit_round_addr_offset(randombit_round_addr_offset),
        .randombit_round(randombit_round),
        .randombit_state(randombit_state)
    );

    // output wire [13:0]PArandombit_addrb,    //0~16383
    reg [10:0] randombit_addr_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            randombit_addr_cnt <= 11'b0;
        end
        else if (reset_round_cnt) begin
            randombit_addr_cnt <= 11'b0;
        end
        else if (round_count_en&&(randombit_addr_cnt<1023)) begin
            randombit_addr_cnt <= randombit_addr_cnt + 1;
        end
        else begin
            randombit_addr_cnt <= randombit_addr_cnt;
        end
    end

    wire [13:0] send_randombit_addr;    //0~16383
    assign send_randombit_addr = (randombit_addr_cnt[10:1] + randombit_round_addr_offset);

    assign round_count_finish = (randombit_addr_cnt==1023);



    reg [10:0] randombit_addr_cnt_delay_1, randombit_addr_cnt_delay_2;
    always @(posedge clk ) begin
        if (~rst_n) begin
            randombit_addr_cnt_delay_1 <= 1'b0;
            randombit_addr_cnt_delay_2 <= 1'b0;
        end
        else begin
            randombit_addr_cnt_delay_1 <= randombit_addr_cnt;
            randombit_addr_cnt_delay_2 <= randombit_addr_cnt_delay_1;
        end
    end

    reg round_count_en_delay;
    reg randombit_wr_en;
    always @(posedge clk ) begin
        if (~rst_n) begin
            round_count_en_delay <= 1'b0;
            randombit_wr_en <= 1'b0;
        end
        else begin
            round_count_en_delay <= round_count_en;
            randombit_wr_en <= round_count_en_delay;
        end
    end

    wire [31:0] randombit_wr_din;
    assign randombit_wr_din = ((~randombit_addr_cnt_delay_2[0]) && randombit_wr_en)? 
                            PArandombit_doutb_ff[63:32]:PArandombit_doutb_ff[31:0];

    wire [31:0] randombit_A2B_header;
    assign randombit_A2B_header = {`A2B_PA_RANDOMBIT ,
                                `PACKET_LENGTH_1028,
                                16'b0,
                                randombit_round};
    wire randombit_A2B_header_write_en;
    assign randombit_A2B_header_write_en = (randombit_addr_cnt==1)? 1'b1:1'b0;

    // last round
    assign last_round = (randombit_round==8'd31)? 1'b1:1'b0;
//****************************** send PA random bit ******************************






//****************************** send secret key length ******************************
    //wire send_secretkey_length_finish;
    //wire send_secretkey_length_en;


    reg [3:0] send_secretkey_length_cnt;
    always @(posedge clk ) begin
        if (~rst_n) begin
            send_secretkey_length_cnt <= 4'b0;
        end
        else if (reset_pa_parameter) begin
            send_secretkey_length_cnt <= 4'b0;
        end
        else if (send_secretkey_length_en&&(send_secretkey_length_cnt<5)) begin
            send_secretkey_length_cnt <= send_secretkey_length_cnt + 1;
        end
        else begin
            send_secretkey_length_cnt <= 4'b0;
        end
    end

    assign send_secretkey_length_finish = (send_secretkey_length_cnt==4);


    wire secretkey_length_A2B_header_write_en;
    wire [31:0] secretkey_length_A2B_header;

    wire secretkey_length_wr_en;
    wire [31:0] secretkey_length_wr_din;


    assign secretkey_length_A2B_header = {`A2B_SECRETKEY_LENGTH,
                                          `PACKET_LENGTH_257,
                                          9'd1,                 //real packet depth = 1
                                          15'b0};
    

    assign secretkey_length_A2B_header_write_en = (send_secretkey_length_cnt==2);
    
    assign secretkey_length_wr_din = secretkey_length_ff;

    assign secretkey_length_wr_en = (send_secretkey_length_cnt==3);
//****************************** send secret key length ******************************







//****************************** write A2B FIFO ******************************

    always @(posedge clk ) begin
        if (~rst_n) begin
            A_TX_pa_wr_din <= 32'b0;
            A_TX_pa_wr_en <= 1'b0;
        end
        else if (send_randombit_en && randombit_A2B_header_write_en) begin
            A_TX_pa_wr_din <= randombit_A2B_header;
            A_TX_pa_wr_en <= 1'b1;
        end
        else if (send_randombit_en) begin
            A_TX_pa_wr_din <= randombit_wr_din;
            A_TX_pa_wr_en <= randombit_wr_en;
        end


        else if (send_secretkey_length_en && secretkey_length_A2B_header_write_en) begin
            A_TX_pa_wr_din <= secretkey_length_A2B_header;
            A_TX_pa_wr_en <= 1'b1;
        end
        else if (send_secretkey_length_en && secretkey_length_wr_en) begin
            A_TX_pa_wr_din <= secretkey_length_wr_din;
            A_TX_pa_wr_en <= secretkey_length_wr_en;
        end

        
        else begin
            A_TX_pa_wr_din <= 32'b0;
            A_TX_pa_wr_en <= 1'b0;
        end
    end

//****************************** write A2B FIFO ******************************





//****************************** PA instantiation ******************************
    wire [13:0] rb_addrb;


    top_pa Apa(
        .clk(clk),                              //clk
        .rst_n(rst_n),                            //reset

        .secretkey_length(secretkey_length_ff[`SECRETKEY_LENGTH_WIDTH-1:0]),   //secret key length
        .start_compute(start_pa_compute),                                    //start to compute privacy amplification
        .reconciled_key_addr_index(reconciled_key_addr_index_ff),        //address indeex
                                                                //0:addr0 ~ addr16383
                                                                //1:addr16384 ~ addr32767


        //Key BRAM
        // width = 64, depth = 32768
        .key_doutb(key_doutb),  
        .key_clkb(key_clkb),
        .key_enb(key_enb),            //1'b1
        .key_web(key_web),            //1'b0
        .key_rstb(),           //1'b0
        .key_index_and_addrb(key_index_and_addrb),   //0~32767


        //Random bit BRAM
        // width = 64 , depth = 16384
        .PArandombit_doutb(rb_doutb),
        .PArandombit_addrb(rb_addrb),    //0~16383
        .PArandombit_clkb(PArandombit_clkb),
        .PArandombit_enb(PArandombit_enb),            //1'b1
        .PArandombit_rstb(),           //1'b0
        .PArandombit_web(PArandombit_web),       //8'b0

        //Secret key BRAM
        // width = 64 , depth = 65536
        .Secretkey_addrb(Secretkey_addrb),   //0~65535
        .Secretkey_clkb(Secretkey_clkb),      
        .Secretkey_dinb(Secretkey_dinb),
        .Secretkey_enb(Secretkey_enb),           //1'b1
        .Secretkey_rstb(),          //1'b0
        .Secretkey_web(Secretkey_web),      


        .finish_compute(finish_compute)             //secret key is done

    );
//****************************** PA instantiation ******************************




//****************************** random bit bram port sel ******************************
    wire [63:0] rb_doutb;


    assign PArandombit_addrb = (send_PArandombit_en)? send_randombit_addr:rb_addrb;

    assign rb_doutb = (compute_busy)? PArandombit_doutb:64'b0;


//****************************** random bit bram port sel ******************************


endmodule



















































module send_randombit_fsm (
    input clk,
    input rst_n,

    input send_randombit_en,
    input A_TX_pa_empty,
    input round_count_finish,
    input last_round,


    output reg round_count_en,
    output reg reset_randombit_cnt,
    output reg send_randombit_finish,

    output wire reset_round_cnt,

    output wire [19:0] randombit_round_addr_offset,
    output reg [7:0] randombit_round,
    output reg [3:0] randombit_state
);

    localparam RANDOMBIT_IDLE               = 4'd0;
    localparam RANDOMBIT_START              = 4'd1;
    localparam ROUND_IDLE                   = 4'd2;
    localparam ROUND_COUNT                  = 4'd3;
    localparam ROUND_COUNT_END              = 4'd4;
    localparam RESET_RANDOMBIT_CNT          = 4'd5;
    localparam RANDOMBIT_END                = 4'd6;


    assign reset_round_cnt = ((randombit_state==ROUND_IDLE)&&(next_randombit_state==ROUND_COUNT))?
                                1'b1:1'b0; 


    always @(posedge clk ) begin
        if (~rst_n) begin
            randombit_round <= 8'b0;
        end
        else if (reset_randombit_cnt) begin
            randombit_round <= 8'b0;
        end
        else if (randombit_state==ROUND_COUNT_END) begin
            randombit_round <= randombit_round + 1;
        end
        else begin
            randombit_round <= randombit_round;
        end
    end


    assign randombit_round_addr_offset = (randombit_round<<9);

    reg [3:0] next_randombit_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            randombit_state <= RANDOMBIT_IDLE;
        end
        else begin
            randombit_state <= next_randombit_state;
        end
    end


    always @(*) begin
        case (randombit_state)
            RANDOMBIT_IDLE: begin
                if (send_randombit_en) begin
                    next_randombit_state = RANDOMBIT_START;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
                else begin
                    next_randombit_state = RANDOMBIT_IDLE;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
            end


            RANDOMBIT_START: begin
                next_randombit_state = ROUND_IDLE;
                round_count_en = 1'b0;
                reset_randombit_cnt = 1'b0;
                send_randombit_finish = 1'b0;
            end

            ROUND_IDLE: begin
                if (A_TX_pa_empty) begin
                    next_randombit_state = ROUND_COUNT;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
                else begin
                    next_randombit_state = ROUND_IDLE;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
            end

            ROUND_COUNT: begin
                if (round_count_finish) begin
                    next_randombit_state = ROUND_COUNT_END;
                    round_count_en = 1'b1;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
                else begin
                    next_randombit_state = ROUND_COUNT;
                    round_count_en = 1'b1;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
            end


            ROUND_COUNT_END: begin
                if (last_round) begin
                    next_randombit_state = RESET_RANDOMBIT_CNT;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
                else begin
                    next_randombit_state = ROUND_IDLE;
                    round_count_en = 1'b0;
                    reset_randombit_cnt = 1'b0;
                    send_randombit_finish = 1'b0;
                end
            end


            RESET_RANDOMBIT_CNT: begin
                next_randombit_state = RANDOMBIT_END;
                round_count_en = 1'b0;
                reset_randombit_cnt = 1'b1;
                send_randombit_finish = 1'b0;
            end

            RANDOMBIT_END: begin
                next_randombit_state = RANDOMBIT_IDLE;
                round_count_en = 1'b0;
                reset_randombit_cnt = 1'b0;
                send_randombit_finish = 1'b1;
            end

            default: begin
                next_randombit_state = RANDOMBIT_IDLE;
                round_count_en = 1'b0;
                reset_randombit_cnt = 1'b0;
                send_randombit_finish = 1'b0;
            end
        endcase
    end



endmodule


























module A_pa_fsm (
    input clk,
    input rst_n,

    input start_A_pa,
    input send_PArandombit_finish,
    input send_secretkey_length_finish,
    input [31:0] secretkey_length_ff,
    input finish_compute,


    output reg send_PArandombit_en,
    output reg send_secretkey_length_en,
    output reg start_pa_compute,
    output reg reset_pa_parameter,
    output reg A_pa_finish,
    output reg A_pa_fail,
    output wire compute_busy,
    output reg [3:0] A_pa_state
);

    localparam PA_IDLE                  = 4'd0;
    localparam PA_START                 = 4'd1;
    localparam SEND_PARANDOMBIT         = 4'd2;
    localparam PARANDOMBIT_END          = 4'd3;
    localparam SEND_SECRETKEY_LENGTH    = 4'd4;
    localparam SECRETKEY_LENGTH_END     = 4'd5;
    localparam DETERMINE_LENGTH         = 4'd6;
    localparam START_COMPUTE            = 4'd7;
    localparam COMPUTE_BUSY             = 4'd8;
    localparam COMPUTE_END              = 4'd9;
    localparam RESET_PA_PARAMETER       = 4'd10;
    localparam PA_END                   = 4'd11;
    localparam PA_FAIL                  = 4'd12;

    assign compute_busy = (A_pa_state==COMPUTE_BUSY);

    reg [3:0] next_A_pa_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            A_pa_state <= PA_IDLE;
        end
        else begin
            A_pa_state <= next_A_pa_state;
        end
    end

    always @(*) begin
        case (A_pa_state)
            PA_IDLE: begin
                if (start_A_pa) begin
                    next_A_pa_state = PA_START;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else begin
                    next_A_pa_state = PA_IDLE;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
            end

            PA_START: begin
                next_A_pa_state = SEND_PARANDOMBIT;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end

            SEND_PARANDOMBIT: begin
                if (send_PArandombit_finish) begin
                    next_A_pa_state = PARANDOMBIT_END;
                    send_PArandombit_en = 1'b1;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else begin
                    next_A_pa_state = SEND_PARANDOMBIT;
                    send_PArandombit_en = 1'b1;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
            end

            PARANDOMBIT_END: begin
                next_A_pa_state = SEND_SECRETKEY_LENGTH;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end


            SEND_SECRETKEY_LENGTH: begin
                if (send_secretkey_length_finish) begin
                    next_A_pa_state = SECRETKEY_LENGTH_END;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b1;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else begin
                    next_A_pa_state = SEND_SECRETKEY_LENGTH;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b1;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
            end

            SECRETKEY_LENGTH_END: begin
                next_A_pa_state = DETERMINE_LENGTH;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end

            DETERMINE_LENGTH: begin
                if (secretkey_length_ff[31:28]==4'b1111) begin
                    next_A_pa_state = PA_FAIL;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else if (secretkey_length_ff[31:28]==4'b0) begin
                    next_A_pa_state = START_COMPUTE;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else begin
                    next_A_pa_state = DETERMINE_LENGTH;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
            end

            START_COMPUTE: begin
                next_A_pa_state = COMPUTE_BUSY;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b1;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end

            COMPUTE_BUSY: begin
                if (finish_compute) begin
                    next_A_pa_state = COMPUTE_END;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
                else begin
                    next_A_pa_state = COMPUTE_BUSY;
                    send_PArandombit_en = 1'b0;
                    send_secretkey_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    A_pa_finish = 1'b0;
                    A_pa_fail = 1'b0;
                end
            end

            COMPUTE_END: begin
                next_A_pa_state = RESET_PA_PARAMETER;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end

            RESET_PA_PARAMETER: begin
                next_A_pa_state = PA_END;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b1;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end

            PA_END: begin
                next_A_pa_state = PA_IDLE;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b1;
                A_pa_fail = 1'b0;
            end


            PA_FAIL: begin
                next_A_pa_state = PA_IDLE;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b1;
                A_pa_finish = 1'b1;
                A_pa_fail = 1'b1;
            end








            default: begin
                next_A_pa_state = PA_IDLE;
                send_PArandombit_en = 1'b0;
                send_secretkey_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                A_pa_finish = 1'b0;
                A_pa_fail = 1'b0;
            end
        endcase
    end



    
endmodule