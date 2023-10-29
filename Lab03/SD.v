`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2023 08:39:51 PM
// Design Name: 
// Module Name: SD
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
module SD (
	input clk, rst_n,
	input in_valid,
	input [3:0] in,
	
	output reg out_valid,
	output reg [3:0] out
    );
    
    reg [3:0] in_count_col = 4'd1;
    reg [3:0] in_count_row = 4'd1;
    reg [3:0] blank_row [15:0]; 
    reg [3:0] blank_col [15:0];
    reg [3:0] blank_box [15:0];
    
    reg [1:9] row_possible [1:9];
    reg [1:9] col_possible [1:9];
    reg [1:9] box_possible [1:9];
    reg [1:9] cant_fill [0:15];
    
    
    // when going backward: read from the output vector and write back to the list of possible answer
    
    reg [3:0] output_vector [15:0];
    reg [1:9] possible_nums [15:0];
    reg [3:0] available_choices [15:0]; // for each blank space, how many possible numbers can be filled
    reg [3:0] blank_cnt = 4'd0;
    reg [3:0] blank_proc_ptr = 4'd1;
    reg [3:0] try_num = 0; // the number that will be tried to fill in the blank
    reg no_sol = 1'b0;
    reg [3:0] out_cnt = 4'd0;
    
    localparam  Idle = 2'd0,
                Forward = 2'd1,
                Backward = 2'd2,
                Output = 2'd3;
    
    reg [1:0] curr_state = Idle;
    reg [1:0] next_state = Idle;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) curr_state <= Idle;
        else curr_state <= next_state;
    end
    
    always@(*) begin
        case(curr_state)
            Idle: begin
                if(in_count_row == 4'd10) next_state = Forward;
                else next_state = Idle;
            end
            
            // both forward and backward: if no solution go back, else go forward
            Forward: begin
                if(blank_proc_ptr == 0 || no_sol) next_state = Output; // 15+1 and round to 0
                else if(try_num == 4'd0) next_state = Backward;
                else next_state = Forward;
            end
            
            Backward: begin
                if(blank_proc_ptr == 0) next_state = Output; // 1-1 becomes 0
                else if(try_num == 4'd0) next_state = Backward;
                else next_state = Forward;  // go forward again when a new number is found
            end
            
            Output: begin
                if(out_cnt == 4'd0) next_state = Idle; //round to zero
                else next_state = Output;
            end
        endcase
    end
    

    // idle/input state
    // current box = (in_count_row/3)*3 + in_count_col/3
    wire [9:0] box_row, box_col; // 4bit integer * 0.328 (6bit decimal)
    assign box_row = in_count_row * 6'b010101;
    assign box_col = in_count_col * 6'b010101;
    integer int_i, int_j, int_k;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            blank_cnt <= 4'd1;
            blank_proc_ptr <= 4'd1;
            out_cnt <= 4'd1;
            in_count_col <= 4'd1;
            in_count_row <= 4'd1;
            
            out <= 4'd0;
            out_valid <= 1'b0;
            no_sol <= 1'b0;
            
            for(int_i=0; int_i<16; int_i=int_i+1) begin
                blank_row[int_i] <= 4'd0;
                blank_col[int_i] <= 4'd0;
                blank_box[int_i] <= 4'd0;
                output_vector[int_i] <= 4'd0;
                cant_fill[int_i] <= 9'b1_1111_1111;
            end
            for(int_j=1; int_j<10; int_j=int_j+1) begin
                row_possible[int_j] <= 9'b1_1111_1111;
                col_possible[int_j] <= 9'b1_1111_1111;
                box_possible[int_j] <= 9'b1_1111_1111;
            end
            
        end else begin
            case(next_state)
                Idle: begin
                    if(in_valid) begin
                        if(in == 4'd0) begin
                            blank_row[blank_cnt] <= in_count_row; // store which position is blank; 
                            blank_col[blank_cnt] <= in_count_col;
                            blank_box[blank_cnt] <= box_row[9:6]*3 + box_col[9:6] + 1; // box index -> 1 to 9
                            blank_cnt <= blank_cnt + 1;
                        end else begin
                            if(!(row_possible[in_count_row][in] & col_possible[in_count_col][in] & box_possible[box_row[9:6]*3 + box_col[9:6] + 1][in])) begin
                                no_sol <= 1'b1;
                            end else begin
                                row_possible[in_count_row][in] <= 1'b0; // which number is possible to fill
                                col_possible[in_count_col][in] <= 1'b0;
                                box_possible[box_row[9:6]*3 + box_col[9:6] + 1][in] <= 1'b0;
                            end
                        end
                        
                        if(in_count_col == 9) begin
                            in_count_col <= 1;
                            in_count_row <= in_count_row + 1;
                        end else in_count_col <= in_count_col + 1;
                    end else begin
                        // reset before in_valid in Idle state
                        for(int_i=0; int_i<16; int_i=int_i+1) begin
                            blank_row[int_i] <= 4'd0;
                            blank_col[int_i] <= 4'd0;
                            blank_box[int_i] <= 4'd0;
                            output_vector[int_i] <= 4'd0;
                            cant_fill[int_i] <= 9'b1_1111_1111;
                        end
                        for(int_j=1; int_j<10; int_j=int_j+1) begin
                            row_possible[int_j] <= 9'b1_1111_1111;
                            col_possible[int_j] <= 9'b1_1111_1111;
                            box_possible[int_j] <= 9'b1_1111_1111;
                        end
                        blank_cnt <= 4'd1;
                        blank_proc_ptr <= 4'd1;
                        out_cnt <= 4'd1;
                        in_count_col <= 4'd1;
                        in_count_row <= 4'd1;
                        
                        out <= 4'd0;
                        out_valid <= 1'b0;
                        no_sol <= 1'b0;
                    end
                end
                
                Forward: begin
                    if(output_vector[blank_proc_ptr] > 0) begin
                        row_possible[blank_row[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        col_possible[blank_col[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        box_possible[blank_box[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        cant_fill[blank_proc_ptr][output_vector[blank_proc_ptr]] <= 1'b0;
                    end
                    
                    if(try_num != 4'd0) begin // there's a number to fill
                        output_vector[blank_proc_ptr] <= try_num;
                        blank_proc_ptr <= blank_proc_ptr + 1;
                        row_possible[blank_row[blank_proc_ptr]][try_num] <= 1'b0; // remove the number from possible choices
                        col_possible[blank_col[blank_proc_ptr]][try_num] <= 1'b0;
                        box_possible[blank_box[blank_proc_ptr]][try_num] <= 1'b0;
                    end else begin
                         // return to the last position
                        if(blank_proc_ptr == 4'd1) begin
                            blank_proc_ptr <= blank_proc_ptr - 1;
                            no_sol <= 1'b1;
                        end else blank_proc_ptr <= blank_proc_ptr - 1; // return to the last position
                    end
                end
                
                Backward: begin
                    if(available_choices[blank_proc_ptr-1] > 0) begin
                        row_possible[blank_row[blank_proc_ptr-1]][output_vector[blank_proc_ptr-1]] <= 1'b1;
                        col_possible[blank_col[blank_proc_ptr-1]][output_vector[blank_proc_ptr-1]] <= 1'b1;
                        box_possible[blank_box[blank_proc_ptr-1]][output_vector[blank_proc_ptr-1]] <= 1'b1;
                        cant_fill[blank_proc_ptr-1][output_vector[blank_proc_ptr-1]] <= 1'b0;
                    end
                    
                    if(available_choices[blank_proc_ptr] == 0) begin
                        cant_fill[blank_proc_ptr] <= 9'b1_1111_1111;
                    end
                    
                    if(output_vector[blank_proc_ptr] > 0) begin
                        row_possible[blank_row[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        col_possible[blank_col[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        box_possible[blank_box[blank_proc_ptr]][output_vector[blank_proc_ptr]] <= 1'b1;
                        blank_proc_ptr <= blank_proc_ptr - 1;
                        output_vector[blank_proc_ptr] <= 4'd0;
                    end else blank_proc_ptr <= blank_proc_ptr - 1;
                    
                    // before removal, if there's only one choice available, the pointer decrements 
                    if(blank_proc_ptr == 1) no_sol <= 1'b1;
                    
                end
                
                Output: begin
                    if(no_sol) begin
                        out <= 4'd10;
                        out_valid <= 1'b1;
                        no_sol <= 1'b0;	// in next cycle: out_valid be set to 0 and next_state is Idle
                        out_cnt <= 4'd0;
                    end else begin
                        if(out_cnt > 4'd0) begin
                            out_valid <= 1'b1;
                            out <= output_vector[out_cnt];
                            out_cnt <= out_cnt + 1;
                        end else begin
                            out_cnt <= 4'd1;
                            out_valid <= 1'b0;
                        end
                    end	
                end
                
            endcase
            
        end
    end
    
    // data preparation
    // give initial values so they won't be X after reset, but will be ready after reading all the input.
    genvar i, j;
    generate
        for(i = 0; i<16; i=i+1) begin
            always@(*) begin
                possible_nums[i] = row_possible[blank_row[i]] & col_possible[blank_col[i]] & box_possible[blank_box[i]] & cant_fill[i];
            end
        end
    endgenerate
    
    generate
        for(j = 0; j<16; j=j+1) begin
            always@(*) begin
                available_choices[j] = 	possible_nums[j][1] + possible_nums[j][2] + possible_nums[j][3] + 
                                        possible_nums[j][4] + possible_nums[j][5] + possible_nums[j][6] + 
                                        possible_nums[j][7] + possible_nums[j][8] + possible_nums[j][9];
            end
        end
    endgenerate
    
    // prepare the number that is going to be filled
    always@(*) begin
        if(possible_nums[blank_proc_ptr][1]) try_num = 4'd1;
        else if(possible_nums[blank_proc_ptr][2]) try_num = 4'd2;
        else if(possible_nums[blank_proc_ptr][3]) try_num = 4'd3;
        else if(possible_nums[blank_proc_ptr][4]) try_num = 4'd4;
        else if(possible_nums[blank_proc_ptr][5]) try_num = 4'd5;
        else if(possible_nums[blank_proc_ptr][6]) try_num = 4'd6;
        else if(possible_nums[blank_proc_ptr][7]) try_num = 4'd7;
        else if(possible_nums[blank_proc_ptr][8]) try_num = 4'd8;
        else if(possible_nums[blank_proc_ptr][9]) try_num = 4'd9;
        else try_num = 4'd0;
    end
    
  
endmodule
