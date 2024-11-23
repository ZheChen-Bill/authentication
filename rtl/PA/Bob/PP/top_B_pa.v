



`include "../pa_parameter.v"




module top_B_pa (
    input clk,                              //clk
    input rst_n,                            //reset

    input start_B_pa,                       //start to pa

    input PArandombit_full,                 //PA randombit from Alice is full
    output reset_pa_parameter,              //

    output B_pa_finish,                     //pa is done
    output B_pa_fail,                       //pa is fail due to error secret key length


    //input [`SECRETKEY_LENGTH_WIDTH-1:0] secretkey_length,   //secret key length

    input reconciled_key_addr_index,                        //address index
                                                            //0:addr0 ~ addr16383
                                                            //1:addr16384 ~ addr32767


    // secret key length FIFO (input)
    // width = 32 , depth = 512
    output wire B_RX_secretkey_length_rd_clk,
    output wire B_RX_secretkey_length_rd_en,
    input wire [31:0] B_RX_secretkey_length_rd_dout,
    input wire B_RX_secretkey_length_empty,
    input wire B_RX_secretkey_length_rd_valid,


    // reconciled key BRAM (input)
    // width = 64, depth = 32768
    // port B
    input wire [63 : 0] key_doutb,  
    output wire key_clkb,
    output wire key_enb,            //1'b1
    output wire key_web,            //1'b0
    output wire key_rstb,           //1'b0
    output wire [14 : 0] key_index_and_addrb,   //0~32767


    //Secret key BRAM (output)
    // width = 64 , depth = 32768
    // port B
    output wire [14:0]Secretkey_addrb,   //0~32767
    output wire Secretkey_clkb,      
    output wire [63:0]Secretkey_dinb,
    output wire Secretkey_enb,           //1'b1
    output wire Secretkey_rstb,          //1'b0
    output wire [7:0]Secretkey_web,      




    //Random bit BRAM (input)
    // width = 64 , depth = 16384
    // port B
    input wire [63:0]PArandombit_doutb,
    output wire [13:0]PArandombit_addrb,    //0~16383
    output wire PArandombit_clkb,
    //output wire [63:0]PArandombit_dinb,
    output wire PArandombit_enb,            //1'b1
    output wire PArandombit_rstb,           //1'b0
    output wire [7:0]PArandombit_web       //8'b0

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
    // secret key length FIFO (input)
    // width = 32 , depth = 512
    assign B_RX_secretkey_length_rd_clk = clk;
//****************************** FIFO setup ******************************
//****************************** reconciled_key_addr_index_ff ******************************
    reg reconciled_key_addr_index_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            reconciled_key_addr_index_ff <= 1'b0;
        end
        else if (reset_pa_parameter) begin
            reconciled_key_addr_index_ff <= 1'b0;
        end
        else if (start_B_pa) begin
            reconciled_key_addr_index_ff <= reconciled_key_addr_index;
        end
        else begin
            reconciled_key_addr_index_ff <= reconciled_key_addr_index_ff;
        end
    end
//****************************** reconciled_key_addr_index_ff ******************************
//****************************** secretkey_length_ff ******************************
    reg [31:0] secretkey_length_ff;
    always @(posedge clk ) begin
        if (~rst_n) begin
            secretkey_length_ff <= 32'b0;
        end
        else if (reset_pa_parameter) begin
            secretkey_length_ff <= 32'b0;
        end
        else if (read_key_length_en) begin
            secretkey_length_ff <= B_RX_secretkey_length_rd_dout;
        end
        else begin
            secretkey_length_ff <= secretkey_length_ff;
        end
    end

    assign B_RX_secretkey_length_rd_en = read_key_length_en;
//****************************** secretkey_length_ff ******************************





//****************************** B pa fsm ******************************
    //fsm input
    //wire start_B_pa;
    //wire PArandombit_full;
    //wire B_RX_secretkey_length_rd_valid;
    //reg [31:0] secretkey_length_ff;
    wire finish_compute;

    //fsm output
    wire read_key_length_en;
    wire start_pa_compute;
    //wire reset_pa_parameter;
    //wire B_pa_finish;
    //wire B_pa_fail;

    wire [3:0] B_pa_state;


    B_pa_fsm Bpa_fsm(
        .clk(clk),
        .rst_n(rst_n),

        .start_B_pa(start_B_pa),
        .PArandombit_full(PArandombit_full),
        .B_RX_secretkey_length_rd_valid(B_RX_secretkey_length_rd_valid),
        .secretkey_length_ff(secretkey_length_ff),
        .finish_compute(finish_compute),


        .read_key_length_en(read_key_length_en),
        .start_pa_compute(start_pa_compute),
        .reset_pa_parameter(reset_pa_parameter),
        .B_pa_finish(B_pa_finish),
        .B_pa_fail(B_pa_fail),
        .B_pa_state(B_pa_state)
    );
//****************************** B pa fsm ******************************




//****************************** PA instantiation ******************************

    top_pa Bpa(
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
        .PArandombit_doutb(PArandombit_doutb),
        .PArandombit_addrb(PArandombit_addrb),    //0~16383
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




endmodule








































module B_pa_fsm (
    input clk,
    input rst_n,

    input start_B_pa,
    input PArandombit_full,
    input B_RX_secretkey_length_rd_valid,
    input [31:0] secretkey_length_ff,
    input finish_compute,


    output reg read_key_length_en,
    output reg start_pa_compute,
    output reg reset_pa_parameter,
    output reg B_pa_finish,
    output reg B_pa_fail,
    output reg [3:0] B_pa_state
);

    localparam PA_IDLE                                  = 4'd0;
    localparam PA_START                                 = 4'd1;
    localparam WAIT_PARANDOMBIT_SECRETKEY_LENGTH        = 4'd2;
    localparam PARANDOMBIT_FULL_SECRETKEY_LENGTH_VALID  = 4'd3;
    localparam READ_SECRETKEY_LENGTH                    = 4'd4;
    localparam SECRETKEY_LENGTH_READY                   = 4'd5;
    localparam DETERMINE_LENGTH                         = 4'd6;
    localparam START_COMPUTE                            = 4'd7;
    localparam COMPUTE_BUSY                             = 4'd8;
    localparam COMPUTE_END                              = 4'd9;
    localparam RESET_PA_PARAMETER                       = 4'd10;
    localparam PA_END                                   = 4'd11;
    localparam PA_FAIL                                  = 4'd12;



    reg [3:0] next_B_pa_state;
    always @(posedge clk ) begin
        if (~rst_n) begin
            B_pa_state <= PA_IDLE;
        end
        else begin
            B_pa_state <= next_B_pa_state;
        end
    end
    
    always @(*) begin
        case (B_pa_state)
            PA_IDLE: begin
                if (start_B_pa) begin
                    next_B_pa_state = PA_START;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
                else begin
                    next_B_pa_state = PA_IDLE;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
            end

            PA_START: begin
                next_B_pa_state = WAIT_PARANDOMBIT_SECRETKEY_LENGTH;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end

            WAIT_PARANDOMBIT_SECRETKEY_LENGTH: begin
                if (PArandombit_full && B_RX_secretkey_length_rd_valid) begin
                    next_B_pa_state = PARANDOMBIT_FULL_SECRETKEY_LENGTH_VALID;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
                else begin
                    next_B_pa_state = WAIT_PARANDOMBIT_SECRETKEY_LENGTH;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
            end

            PARANDOMBIT_FULL_SECRETKEY_LENGTH_VALID: begin
                next_B_pa_state = READ_SECRETKEY_LENGTH;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end


            READ_SECRETKEY_LENGTH: begin
                next_B_pa_state = SECRETKEY_LENGTH_READY;
                read_key_length_en = 1'b1;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end


            SECRETKEY_LENGTH_READY: begin
                next_B_pa_state = DETERMINE_LENGTH;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end


            DETERMINE_LENGTH: begin
                if (secretkey_length_ff[31:28]==4'b1111) begin
                    next_B_pa_state = PA_FAIL;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
                else if (secretkey_length_ff[31:28]==4'b0) begin
                    next_B_pa_state = START_COMPUTE;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
                else begin
                    next_B_pa_state = DETERMINE_LENGTH;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
            end


            START_COMPUTE: begin
                next_B_pa_state = COMPUTE_BUSY;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b1;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end



            COMPUTE_BUSY: begin
                if (finish_compute) begin
                    next_B_pa_state = COMPUTE_END;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
                else begin
                    next_B_pa_state = COMPUTE_BUSY;
                    read_key_length_en = 1'b0;
                    start_pa_compute = 1'b0;
                    reset_pa_parameter = 1'b0;
                    B_pa_finish = 1'b0;
                    B_pa_fail = 1'b0;
                end
            end


            COMPUTE_END: begin
                next_B_pa_state = RESET_PA_PARAMETER;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end

            RESET_PA_PARAMETER: begin
                next_B_pa_state = PA_END;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b1;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end

            PA_END: begin
                next_B_pa_state = PA_IDLE;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b1;
                B_pa_fail = 1'b0;
            end

            PA_FAIL: begin
                next_B_pa_state = PA_IDLE;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b1;
                B_pa_finish = 1'b1;
                B_pa_fail = 1'b1;
            end


            default: begin
                next_B_pa_state = PA_IDLE;
                read_key_length_en = 1'b0;
                start_pa_compute = 1'b0;
                reset_pa_parameter = 1'b0;
                B_pa_finish = 1'b0;
                B_pa_fail = 1'b0;
            end
        endcase
    end


    
endmodule


