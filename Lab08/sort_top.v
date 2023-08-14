`timescale 1ns / 1ps


module sort_top(
    input clk, rst_n, in_valid,
    input mode,
    input [8:0] data_in,
    output reg out_valid,
    output reg [8:0] data_out,
    output reg [2:0] output_counter
    );
    
    integer i;
    reg [8:0] input_reg [5:0];
    reg [8:0] tmp;
    integer input_counter = 0;
    localparam Idle = 3'b000;
    localparam Input = 3'b001;
    localparam DirectOutput = 3'b010;
    localparam Sort = 3'b011;
    localparam SortOutput = 3'b100;
    
    reg [2:0] State = Idle;
    wire [9:0] sort_in [5:0];
    wire [9:0] sorted [5:0];
    
    assign sort_in[0] = input_reg[0];
    assign sort_in[1] = input_reg[1];
    assign sort_in[2] = input_reg[2];
    assign sort_in[3] = input_reg[3];
    assign sort_in[4] = input_reg[4];
    assign sort_in[5] = input_reg[5];
    
    sort SORT (
        .sort_in_0(sort_in[0]), 
        .sort_in_1(sort_in[1]), 
        .sort_in_2(sort_in[2]), 
        .sort_in_3(sort_in[3]), 
        .sort_in_4(sort_in[4]), 
        .sort_in_5(sort_in[5]),
        .sort_out_0(sorted[5]),
        .sort_out_1(sorted[4]), 
        .sort_out_2(sorted[3]), 
        .sort_out_3(sorted[2]), 
        .sort_out_4(sorted[1]), 
        .sort_out_5(sorted[0]) //for decreasing result
    );
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input_counter <= 0;
        end
        else begin
            if(in_valid) begin
                input_reg[input_counter] <= data_in;
                input_counter <= input_counter+1;
            end
        end
    end
    
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_valid <= 1'b0;
            data_out <= 9'b0;
            input_counter <= 0;
            output_counter <= 0;
        end
        else begin
            case (State)
                Idle: begin
                    if(in_valid) begin
                        State <= Input;
                    end else begin
                        State <= Idle;
                    end
                end
                
                Input: begin
                    if(input_counter == 6) begin
                        if(mode) begin
                            State <= Sort;
                            input_counter <= 0;
                        end else begin
                            State <= DirectOutput;
                            input_counter <= 0;
                        end
                    end else begin
                        input_reg[input_counter] <= data_in;
                        input_counter <= input_counter+1;
                    end
                end
                
                DirectOutput: begin
                    if(output_counter == 3'd6) begin
                        State <= Idle;
                        out_valid <= 1'b0;
                        data_out <= 9'b0;
                        output_counter <= 0;
                    end else begin
                        data_out  <= input_reg[output_counter];
                        output_counter <= output_counter+1;
                        out_valid <= 1'b1;
                    end
                end
                
                Sort: begin
                    for(i=0; i<6; i=i+1) begin
                        input_reg[i] <= sorted[i];
                    end
                    State <= SortOutput; 
                end
                
                SortOutput: begin
                    if(output_counter == 3'd6) begin
                        State <= Idle;
                        data_out <= 9'b0;
                        out_valid <= 1'b0;
                        output_counter <= 0;
                    end else begin
                        data_out  <= input_reg[output_counter];
                        output_counter <= output_counter+1;
                        out_valid <= 1'b1;
                    end
                end
                
                default: begin
                    State <= Idle;
                end
            endcase
        end
    end
endmodule
