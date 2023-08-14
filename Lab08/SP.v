`timescale 1ns / 1ps


module SP(
    input in_valid,
    input [2:0] in_mode,
    input [8:0] in_data,
    input clk, rst_n,
    input cg_en,
    output [8:0] out_data,
    output out_valid 
    );
    
    reg [2:0] mode_reg;
    reg [8:0] in_data_reg;
    reg in_valid_reg;
    reg delay_flag = 1'b0;
    
    reg inv_working, mult_working, sort_working, sum_working; 
    
    wire [8:0] inv_data_out;
    wire inv_valid;
    wire [8:0] mult_data_out;
    wire mult_valid;
    wire [8:0] sort_data_out;
    wire sort_valid;
    
    wire [3:0] round_counter;
    wire [2:0] mult_out_count, sort_out_count, sum_out_count;
    
    wire clk_inv, clk_mult, clk_sort, clk_sum;	
    wire sleep_inv, sleep_mult, sleep_sort, sleep_sum;	
    GATED_OR GATED_INV(.CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_inv), .RST_N(rst_n), .CLOCK_GATED(clk_inv));	
    GATED_OR GATED_MULT(.CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_mult), .RST_N(rst_n), .CLOCK_GATED(clk_mult));
    GATED_OR GATED_SORT(.CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_sort), .RST_N(rst_n), .CLOCK_GATED(clk_sort));
    GATED_OR GATED_SUM(.CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_sum), .RST_N(rst_n), .CLOCK_GATED(clk_sum));
    
    assign sleep_inv = !inv_working;	
    assign sleep_mult = !mult_working;
    assign sleep_sort = !sort_working;	
    assign sleep_sum = !sum_working;
    
    
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
    
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inv_working <= 1'b0;
        end else begin
            if(in_valid_reg) begin
                inv_working <= 1'b1;
            end else if (inv_valid && round_counter == 9) begin
                inv_working <= 1'b0;
            end
        end
    end
    
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mult_working <= 1'b0;
        end else begin
            if(inv_valid) begin
                mult_working <= 1'b1;
            end else if (mult_valid && mult_out_count == 3'd6) begin
                mult_working <= 1'b0;
            end
        end
    end
    
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sort_working <= 1'b0;
        end else begin
            if(mult_valid) begin
                sort_working <= 1'b1;
            end else if (sort_valid && sort_out_count == 3'd6) begin
                sort_working <= 1'b0;
            end
        end
    end
    
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sum_working <= 1'b0;
        end else begin
            if(in_valid_reg) begin
                sum_working <= 1'b1;
            end else if (out_valid && sum_out_count == 3'd6) begin
                sum_working <= 1'b0;
            end
        end
    end
    
    
    mod_inverse INV (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid_reg),
        .mode(mode_reg[0]),
        .data_in(in_data_reg),
        
        .data_out(inv_data_out),
        .global_valid(inv_valid),
        .round_counter(round_counter)
    );
    
    mod_mult MULT (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(inv_valid),
        .mode(mode_reg[1]),
        .data_in(inv_data_out),
        
        .data_out(mult_data_out),
        .out_valid(mult_valid),
        .output_counter(mult_out_count)
    );
    
    sort_top SORT (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(mult_valid),
        .mode(mode_reg[2]),
        .data_in(mult_data_out),
        
        .data_out(sort_data_out),
        .out_valid(sort_valid),
        .output_counter(sort_out_count)
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
        .out_valid(out_valid),
        .output_counter(sum_out_count)
    );
    
endmodule
