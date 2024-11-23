





`include "./pa_parameter.v"






module toeplitz_hashing(
    input clk,                              //clk
    input rst_n,                            //reset

    input [`PA_W-1:0] random_bit,              //random bit(0 or 1) series for hashing 
    input [`PA_W-1:0] key_bit,                 //reconciliation key
    input shift_en,                         //shift control
    input key_en,                           //key control

    output hash_product_valid,              //output valid
    output [`PA_K-1:0] hash_product   //output hash tag for error verification
    
);









//****************************** shift random bits ******************************
    //64 random_bit * 17
    // (K + W) bit shift reg = 1024+64 = 1088
    wire [(`PA_K+`PA_W-1):0] shift_random_bit;


//****************************** shift random bits ******************************





//****************************** MAC input ******************************
    //64 random_bit * 1024
    wire [`PA_W-1:0]   mac_input   [0:`PA_K-1];
/*
    assign mac_input[`PA_K-512][`PA_W-1:0] = shift_random_bit[64:1];
    assign mac_input[`PA_K-511][`PA_W-1:0] = shift_random_bit[65:2];
    assign mac_input[`PA_K-510][`PA_W-1:0] = shift_random_bit[66:3];
    assign mac_input[`PA_K-509][`PA_W-1:0] = shift_random_bit[67:4];
    .
    .
    .
    assign mac_input[`PA_K-1][`PA_W-1:0] = shift_random_bit[575:512];
*/

    genvar i;
    generate
        for (i=0 ; i<`PA_K ; i=i+1) begin
            assign mac_input[i][`PA_W-1:0] = {shift_random_bit[i+64 : i+1]};
        end
    endgenerate





//****************************** MAC input ******************************





//****************************** MAC instantiation ******************************
    genvar mac_idx;
    generate
        for (mac_idx=0 ; mac_idx<`PA_K ; mac_idx=mac_idx+1) begin
            mac u_mac(
                .clk(clk),      //clk
                .rst_n(rst_n),    //reset

                .random_bit(mac_input[mac_idx][`PA_W-1:0]),
                .key_bit(key_bit),
                .key_en(key_en),

                .sum_bit(hash_product[`PA_K-(mac_idx+1)])
            );


        end
    endgenerate

//****************************** MAC instantiation ******************************






//****************************** shift register instantiation ******************************
// 64-bit shift register * 17

    shift_register s_reg0(
        .clk(clk),      //clk
        .rst_n(rst_n),    //reset

        .input_random_bit(random_bit),
        .shift_en(shift_en),
        
        //.output_random_bit(s_random_bits[0][`PA_W-1:0])
        .output_random_bit(shift_random_bit[`PA_W-1:0])
    );
    



    genvar shiftreg_idx;
    generate
        for (shiftreg_idx=1 ; shiftreg_idx<`PA_S ; shiftreg_idx=shiftreg_idx+1) begin
            shift_register u_shiftreg(
                .clk(clk),      //clk
                .rst_n(rst_n),    //reset
                
                .input_random_bit(shift_random_bit[(shiftreg_idx*64)-1 : (shiftreg_idx-1)*64]),
                .shift_en(shift_en),
                
                .output_random_bit(shift_random_bit[(shiftreg_idx+1)*64-1 : (shiftreg_idx*64)])
            );


        end
    endgenerate


//****************************** shift register instantiation ******************************




        



endmodule







//****************************** shift reg ******************************
module shift_register(
    input clk,      //clk
    input rst_n,    //reset

    input [`PA_W-1:0] input_random_bit,
    input shift_en,
    
    output reg [`PA_W-1:0] output_random_bit
);




    //DFF
    always @(posedge clk ) begin
        if (~rst_n) begin
            output_random_bit <= `PA_W'b0;
        end
        else if (shift_en)begin
            output_random_bit <= input_random_bit;
        end
        else begin
            output_random_bit <= output_random_bit;
        end
    end

endmodule
//****************************** shift reg ******************************













//****************************** MAC ******************************
module mac (
    input clk,      //clk
    input rst_n,    //reset

    input [`PA_W-1:0] random_bit,
    input [`PA_W-1:0] key_bit,
    input key_en,

    output reg sum_bit
);
    //next sum bit
    wire next_sum_bit;
    assign next_sum_bit = (key_en)? ((^and_result)^(sum_bit)):0;

    // AND gate
    wire [`PA_W-1:0] and_result;
    assign and_result = random_bit & key_bit;



    //sum bit DFF
    always @(posedge clk ) begin
        if (~rst_n) begin
            sum_bit <= 0;
        end
        else begin
            sum_bit <= next_sum_bit;
        end
    end

endmodule
//****************************** MAC ******************************