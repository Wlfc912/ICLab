`timescale 1ns / 1ps


module sum(
    input clk, rst_n,
    input a_valid, b_valid, c_valid, d_valid,
    input [8:0] a_data_in, b_data_in, c_data_in, d_data_in,
    
    output reg [8:0] data_out,
    output reg out_valid,
    output reg [2:0] output_counter
    );
    
    reg [10:0] input_reg [5:0];
    
    reg rdy;
    reg [17:0] div;
    wire [8:0] mod_res;
    wire mod_out_valid;
    integer a_counter, b_counter, c_counter, d_counter, input_counter = 0;
    integer i, j;
    
    mod_operation MOD_SUM (
        .clk(clk),
        .rst_n(rst_n),
        .rdy(rdy),
        .dividend(div),
        .remainder(mod_res),
        .out_valid(mod_out_valid)
    );
    
    localparam Data_in = 2'd0;
    localparam mod_input = 2'd1;
    localparam mod_output = 2'd2;
    
    reg [2:0] State = Data_in;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        // reset
            for(i=0; i<6; i=i+1) begin
                input_reg[i] <= 11'b0;
            end
            out_valid <= 1'b0;
            data_out <= 9'b0;
            a_counter <= 0;
            b_counter <= 0;
            c_counter <= 0;
            d_counter <= 0;
            input_counter <= 0;
            output_counter <= 0; 
        end
        else begin
            case (State)
                Data_in: begin
                
                    if(a_valid) begin
                        input_reg[a_counter] <= input_reg[a_counter] + a_data_in;
                        a_counter <= a_counter+1;
                    end
                    if(b_valid) begin
                        input_reg[b_counter] <= input_reg[b_counter] + b_data_in;
                        b_counter <= b_counter+1;
                    end
                    if(c_valid) begin
                        input_reg[c_counter] <= input_reg[c_counter] + c_data_in;
                        c_counter <= c_counter+1;
                    end
                    if(d_valid) begin
                        input_reg[d_counter] <= input_reg[d_counter] + d_data_in;
                        d_counter <= d_counter+1;
                    end
                    
                    if(d_counter==6) begin
                        State <= mod_input;
                        a_counter <= 0;
                        b_counter <= 0;
                        c_counter <= 0;
                        d_counter <= 0;
                    end
                   
                end
                
                
                mod_input: begin
                    if(input_counter == 6) begin
                        input_counter <= 0;
                        State <= mod_output;
                    end else if (input_reg[input_counter] >= 509)begin
                        input_reg[input_counter] <= input_reg[input_counter] - 509;
                    end else begin
                        input_counter <= input_counter+1;
                    end
                end
                
                mod_output: begin
                    if(output_counter == 3'd6) begin
                        output_counter <= 0;
                        out_valid <= 1'b0;
                        State <= Data_in;
                        data_out <= 9'b0;
                        for(i=0; i<6; i=i+1) begin
                            input_reg[i] <= 11'b0;
                        end
                    end else begin
                        data_out <= input_reg[output_counter];
                        out_valid <= 1'b1;
                        output_counter <= output_counter+1;
                    end
                end
                default: begin
                    State <= Data_in;
                end
            endcase
            
        end
    end
endmodule