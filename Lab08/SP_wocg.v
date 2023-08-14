`timescale 1ns / 1ps


module SP_wocg(
    input in_valid,
    input [2:0] in_mode,
    input [8:0] in_data,
    input clk, rst_n,
    
    output [8:0] out_data,
    output out_valid 
    );
    
    reg [2:0] mode_reg;
    reg [8:0] in_data_reg;
    reg in_valid_reg;
    reg delay_flag = 1'b0;
    
    wire [8:0] inv_data_out;
    wire inv_valid;
    wire [8:0] mult_data_out;
    wire mult_valid;
    wire [8:0] sort_data_out;
    wire sort_valid;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mode_reg <= 3'b0;
            in_data_reg <= 0;
            delay_flag <= 1'b0;
        end
        else if(in_valid) begin
            in_data_reg <= in_data;
            in_valid_reg <= in_valid;
            
            if(!delay_flag) begin
                delay_flag <= 1'b1;
                mode_reg <= in_mode;
            end
        end else begin
            in_valid_reg <= 1'b0;
            delay_flag <= 1'b0;    
        end 
    end
    
    
    mod_inverse INV (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid_reg),
        .mode(mode_reg[0]),
        .data_in(in_data_reg),
        
        .data_out(inv_data_out),
        .global_valid(inv_valid)
    );
    
    mod_mult MULT (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(inv_valid),
        .mode(mode_reg[1]),
        .data_in(inv_data_out),
        
        .data_out(mult_data_out),
        .out_valid(mult_valid)
    );
    
    sort_top SORT (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(mult_valid),
        .mode(mode_reg[2]),
        .data_in(mult_data_out),
        
        .data_out(sort_data_out),
        .out_valid(sort_valid)
    );
    
    sum SUM (
        .clk(clk),
        .rst_n(rst_n),
        .a_valid(in_valid_reg),
        .b_valid(inv_valid),
        .c_valid(mult_valid),
        .d_valid(sort_valid),
        .a_data_in(in_data_reg),
        .b_data_in(inv_data_out),
        .c_data_in(mult_data_out),
        .d_data_in(sort_data_out),
        .data_out(out_data),
        .out_valid(out_valid)
    );
    
endmodule
