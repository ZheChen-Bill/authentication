

`include "./pa_parameter.v"


module top_pa (
    input clk,                              //clk
    input rst_n,                            //reset

    input [`SECRETKEY_LENGTH_WIDTH-1:0] secretkey_length,   //secret key length
    input start_compute,                                    //start to compute privacy amplification
    input reconciled_key_addr_index,                        //address index
                                                            //0:addr0 ~ addr16383
                                                            //1:addr16384 ~ addr32767

    //Secret key BRAM
    // width = 64 , depth = 32768
    output reg [14:0]Secretkey_addrb,   //0~32767
    output Secretkey_clkb,      
    output reg [63:0]Secretkey_dinb,
    output Secretkey_enb,           //1'b1
    output Secretkey_rstb,          //1'b0
    output reg [7:0]Secretkey_web,      

    //Key BRAM
    // width = 64, depth = 32768
    input wire [63 : 0] key_doutb,  
    output wire key_clkb,
    output wire key_enb,            //1'b1
    output wire key_web,            //1'b0
    output wire key_rstb,           //1'b0
    output wire [14 : 0] key_index_and_addrb,   //0~32767
    //reg [13:0] key_addr;                      //0~16383
    //reg key_index;                            //address index 0:addr0 ~ addr16383  1:addr16384 ~ addr32767
    //output wire [63 : 0] key_dinb,
    


    //Random bit BRAM
    // width = 64 , depth = 16384
    input wire [63:0]PArandombit_doutb,
    output reg [13:0]PArandombit_addrb,    //0~16383
    output wire PArandombit_clkb,
    //output wire [63:0]PArandombit_dinb,
    output wire PArandombit_enb,            //1'b1
    output wire PArandombit_rstb,           //1'b0
    output wire [7:0]PArandombit_web,       //8'b0




    output reg finish_compute                                  //secret key is done

);
    




//****************************** BRAM setup ******************************
    /* Secret key BRAM set up 
    output Secretkey_clkb,      
    output Secretkey_enb,           //1'b1
    output Secretkey_rstb,          //~rst_n
    */  
    assign Secretkey_clkb = clk;
    assign Secretkey_enb = 1'b1;
    assign Secretkey_rstb = ~rst_n;


    
    /* Key BRAM set up 
    output wire key_clkb,
    output wire key_enb,            //1'b1
    output wire key_web,            //1'b0
    output wire key_rstb,           //~rst_n
    */
    assign key_clkb = clk;
    assign key_enb = 1'b1;
    assign key_web = 1'b0;
    assign key_rstb = ~rst_n;


    /*Random bit BRAM set up
    output wire PArandombit_clkb,
    output wire PArandombit_enb,            //1'b1
    output wire PArandombit_rstb,           //~rst_n
    output wire [7:0]PArandombit_web,       //8'b0
    */
    assign PArandombit_clkb = clk;
    assign PArandombit_enb = 1'b1;
    assign PArandombit_web = 8'b0;
    assign PArandombit_rstb = ~rst_n;





//****************************** BRAM setup ******************************








//****************************** DFF for bram output ******************************
    reg [63:0] key_out_ff , randombit_out_ff;

    always @(posedge clk ) begin
        if (~rst_n) begin
            key_out_ff <= key_doutb;
            randombit_out_ff <= PArandombit_doutb;
        end
        else begin
            key_out_ff <= key_doutb;
            randombit_out_ff <= PArandombit_doutb;
        end
    end
//****************************** DFF for bram output ******************************



//****************************** key index & key addr ******************************
    reg [13:0] key_addr;
    reg key_index;
    always @(posedge clk ) begin
        if (~rst_n) begin
            key_index <= 1'b0;
        end
        else if (start_compute) begin
            key_index <= reconciled_key_addr_index;
        end
        else begin
            key_index <= key_index;
        end
    end
    assign key_index_and_addrb = {key_index , key_addr};

//****************************** key index & key addr ******************************




//****************************** parameter ******************************



    reg [15:0] key_addr_max_index;
    reg [15:0] randombit_addr_max_index;
    reg [10:0] round_max_index;
    reg [`SECRETKEY_LENGTH_WIDTH-1:0] secretkey_length_ff;  //secret key length dff
    reg [`SECRETKEY_LENGTH_WIDTH-1:0] secretkey_length_down; //無條件捨去到64的倍數


    //if mod(secretkey_length,1024) < 64
    //  secretkey_length_up = {secretkey_length[19:10], 10'b0};
    //else 無條件進入到1024的倍數
    //  secretkey_length_up = {secretkey_length[19:10]+(|(secretkey_length[9:0])) , 10'b0};
    wire [`SECRETKEY_LENGTH_WIDTH-1:0] secretkey_length_up; 
    assign secretkey_length_up = (secretkey_length[9:0]<64)? {secretkey_length[19:10], 10'b0} : {secretkey_length[19:10]+(|(secretkey_length[9:0])) , 10'b0};

    

    always @(posedge clk ) begin
        if (~rst_n) begin
            key_addr_max_index <= 0;
            randombit_addr_max_index <= 0;
            round_max_index <= 0;
            secretkey_length_ff <= 0;
            secretkey_length_down <= 0;
        end
        else if (start_compute) begin
            key_addr_max_index <= (16384 - (secretkey_length_up>>6) );
            randombit_addr_max_index <= (16400 - (secretkey_length_up>>6) );
            round_max_index <= (secretkey_length_up>>10);
            secretkey_length_ff <= secretkey_length;
            secretkey_length_down <= {secretkey_length[19:6],6'b0};
        end
        else if (reset_parameter) begin
            key_addr_max_index <= 0;
            randombit_addr_max_index <= 0;
            round_max_index <= 0;
            secretkey_length_ff <= 0;
            secretkey_length_down <= 0;
        end
        else begin
            key_addr_max_index <= key_addr_max_index;
            randombit_addr_max_index <= randombit_addr_max_index;
            round_max_index <= round_max_index;
            secretkey_length_ff <= secretkey_length_ff;
            secretkey_length_down <= secretkey_length_down;
        end
    end
    
    //start compute delay dff
    reg start_compute_delay;
    always @(posedge clk ) begin
        if (~rst_n) begin
            start_compute_delay <= 1'b0;
        end
        else begin
            start_compute_delay <= start_compute;
        end
    end

    //computing_busy
    reg computing_busy;
    always @(posedge clk ) begin
        if (~rst_n) begin
            computing_busy <= 1'b0;
        end
        else begin
            if (start_compute) begin
                computing_busy <= 1'b1;
            end
            else if(reset_parameter) begin
                computing_busy <= 1'b0;
            end
            else begin
                computing_busy <= computing_busy;
            end
        end
    end
//****************************** parameter ******************************


//****************************** xor_key ******************************
    // store correspond partial key to xor hash product
    reg [`PA_K-1:0] xor_key;
    wire xor_enable;
    assign xor_enable = (cycle_counter==(21+key_addr_max_index))? 1'b1:1'b0;

    integer idx;

    always @(posedge clk ) begin
        if (~rst_n) begin
            xor_key <= 0;
        end
        else begin
            if ((cycle_counter>3) && (cycle_counter<20)) begin
                xor_key[((19-cycle_counter)<<6) +: 64] <= key_out_ff;
            end
            else if (round_finish) begin
                xor_key <= 0;
            end
            else if (xor_enable) begin
                xor_key <= xor_key^hash_product;
            end
            else begin
                xor_key <= xor_key;
            end
        end
    end
//****************************** xor_key ******************************


//****************************** write secret key ******************************
    reg write_enable;
    reg [4:0] write_counter;
    //write after xor(product , partial_key)
    always @(posedge clk ) begin
        if (~rst_n) begin
            write_enable <= 0;
        end
        else begin
            write_enable <= xor_enable;
        end
    end


    
    reg round_finish;                      //finish 1 round
    wire reset_parameter;                   //reset parameter to 0
    assign reset_parameter = (round_finish&&(round_counter==1))? 1'b1:1'b0;

    // finish_compute = reset_parameter delay
    always @(posedge clk ) begin
        if (~rst_n) begin
            finish_compute <= 1'b0;
        end
        else begin
            finish_compute <= reset_parameter;
        end
    end
    

    always @(posedge clk ) begin
        if (~rst_n) begin
            write_counter <= 0;
        end
        else if ((round_counter==1)&&(write_counter[3:0]==(secretkey_length_down[9:6]-1))) begin
            write_counter <= 0;
        end
        else if (write_enable) begin
            write_counter <= 1;
        end
        else if (write_counter==15) begin
            write_counter <= 0;
        end
        else if ((write_counter<15 && write_counter!=0)) begin
            write_counter <= write_counter + 1;
        end
        else begin
            write_counter <= 0;
        end
    end

    always @(posedge clk ) begin
        if (~rst_n) begin
            round_finish <= 0;
        end
        else if ((round_counter==1)&&(secretkey_length_down[9:6]==4'b0001)&&(write_enable)) begin
            round_finish <= 1;
        end
        else if ((round_counter==1)&&(write_counter[3:0]==(secretkey_length_down[9:6]-1))&&(write_counter!=0)) begin
            round_finish <= 1;
        end
        else if (write_enable) begin
            round_finish <= 0;
        end
        else if (write_counter==15) begin
            round_finish <= 1;
        end
        else if ((write_counter<15 && write_counter!=0)) begin
            round_finish <= 0;
        end
        else begin
            round_finish <= 0;
        end
    end


    


    /*Secret key BRAM
    // width = 64 , depth = 65536
    output [15:0]Secretkey_addrb,   //0~65535  
    output reg [63:0]Secretkey_dinb,
    output [7:0]Secretkey_web,      
    */

    always @(posedge clk ) begin
        if (~rst_n) begin
            Secretkey_addrb <= {16{1'b1}};
            Secretkey_dinb <= 64'b0;
            Secretkey_web <= 8'b0;
        end
        else if (write_counter!=0 || write_enable) begin
            Secretkey_addrb <= Secretkey_addrb + 1;
            Secretkey_dinb <= xor_key[((15-write_counter)<<6) +: 64];
            Secretkey_web <= 8'b1111_1111;
        end
        else begin
            Secretkey_addrb <= Secretkey_addrb;
            Secretkey_dinb <= 64'b0;
            Secretkey_web <= 8'b0;
        end
    end



//****************************** write secret key ******************************





//****************************** round_counter ******************************
    reg [31:0] round_counter;

    //need to use round_max_index to get secret key
    //each round can get 1024 bits secret key
    always @(posedge clk ) begin
        if (~rst_n) begin
            round_counter <= 32'b0;
        end
        else if (start_compute_delay) begin
            round_counter <= round_max_index;
        end
        else if (round_finish) begin
            round_counter <= round_counter - 1;
        end
        else if (reset_parameter) begin
            round_counter <= 32'b0;
        end
        else begin
            round_counter <= round_counter;
        end
    end

//****************************** round_counter ******************************


//****************************** cycle_counter ******************************
    reg [31:0] cycle_counter;

    // count for each round
    always @(posedge clk ) begin
        if (~rst_n) begin
            cycle_counter <= 0;
        end
        else begin
            if (start_compute_delay) begin
                cycle_counter <= 0; 
            end
            else if (round_finish) begin
                cycle_counter <= 0;
            end
            else if (computing_busy) begin
                cycle_counter <= cycle_counter + 1;
            end
            else begin
                cycle_counter <= cycle_counter;
            end
        end
    end


//****************************** cycle_counter ******************************







//****************************** address for key & random bit ******************************
    // key
    //output wire [14 : 0] key_index_and_addrb,   //0~32767
    //reg [13:0] key_addr;                      //0~16383
    //reg key_index;                            //address index 0:addr0 ~ addr16383  1:addr16384 ~ addr32767
    
    //reg [`PA_K-1:0] xor_key;                  //store correspond partial key to xor hash product
    
    always @(posedge clk ) begin
        if (~rst_n) begin
            key_addr <= 0;
        end
        else begin
            if (round_finish) begin
                key_addr <= 0;
            end
            else if (key_addr==(key_addr_max_index-1)) begin
                key_addr <= key_addr;
            end
            else if ((cycle_counter>0) && (cycle_counter<17)) begin
                key_addr <= key_addr_max_index + ((round_max_index-round_counter)<<4) + (cycle_counter-1);
            end
            else if ((cycle_counter>17)) begin
                key_addr <= (cycle_counter-18);
            end
            else begin
                key_addr <= 0;
            end
        end
    end



    // random bit
    //output reg [13:0]PArandombit_addrb,    //0~16383

    always @(posedge clk ) begin
        if (~rst_n) begin
            PArandombit_addrb <= 0;
        end
        else begin
            if (round_finish) begin
                PArandombit_addrb <= 0;
            end
            else if (PArandombit_addrb==(((round_counter-1)<<4) +randombit_addr_max_index-1)) begin
                PArandombit_addrb <= PArandombit_addrb;
            end
            else if ((cycle_counter>0))begin
                PArandombit_addrb <= ((round_counter-1)<<4) + (cycle_counter-1);
            end
            else begin
                PArandombit_addrb <= 0;
            end
        end
    end

//****************************** address for key & random bit ******************************




    assign rb_shift_en = ((cycle_counter>3) && (cycle_counter<=(3+randombit_addr_max_index)))? 1'b1:1'b0;
    assign key_en = ((cycle_counter>20) && (cycle_counter<=(20+key_addr_max_index)))? 1'b1:1'b0;

    assign toeplitz_key_in = (key_en)? key_out_ff:`PA_W'b0;
    assign toeplitz_randombit_in = (rb_shift_en)? randombit_out_ff:`PA_W'b0;


    //toeplitz_hashing input
    wire [`PA_W-1:0] toeplitz_randombit_in;
    wire rb_shift_en;
    wire key_en;
    wire [`PA_W-1:0] toeplitz_key_in;
    //toeplitz_hashing output
    wire [`PA_K-1:0] hash_product;

    toeplitz_hashing testchip0(
        .clk(clk),                              //clk
        .rst_n(rst_n),                            //reset

        .random_bit(toeplitz_randombit_in),              //random bit(0 or 1) series for hashing 

        //.key_bit(),
        .key_bit(toeplitz_key_in),                 //reconciliation key
        .shift_en(rb_shift_en),                         //shift control
        .key_en(key_en),

        .hash_product(hash_product)        //output hash product for PA
    );










endmodule









