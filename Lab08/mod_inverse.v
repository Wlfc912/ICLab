`timescale 1ns / 1ps


module mod_inverse(
    input clk, rst_n, in_valid,
    input mode,
    input [8:0] data_in,
    
    output reg [8:0] data_out,
    output reg global_valid,
    output reg [3:0] round_counter
    );
    
    localparam p = 9'b1111_1101_1; // 507 in decimal
    integer i;
    integer input_count = 0;
    
    reg [8:0] pipe_a [8:0];
    reg [8:0] pipe_b [8:0];
    reg rdy_a, rdy_b;
    reg [17:0] div_a, div_b;
    
    wire [8:0] mod_a, mod_b;
    wire out_valid_a, out_valid_b;
    
    wire [8:0] input_mod;
    assign input_mod = data_in >= 509 ? data_in-p : data_in;
    
    mod_operation MOD_PIPE_A (
        .clk(clk),
        .rst_n(rst_n),
        .rdy(rdy_a),
        .dividend(div_a),
        .remainder(mod_a),
        .out_valid(out_valid_a)
    );
    
    mod_operation MOD_PIPE_B (
        .clk(clk),
        .rst_n(rst_n),
        .rdy(rdy_b),
        .dividend(div_b),
        .remainder(mod_b),
        .out_valid(out_valid_b)
    );
    
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        // reset
            global_valid <= 1'b0;
            data_out <= 9'b0;
            input_count <= 0;
            round_counter <= 0;
            rdy_a <= 1'b0;
            rdy_b <= 1'b0;
        end
        else begin
            case (mode)
                1'b0: begin
                    if(in_valid) begin
                        data_out <= data_in;
                        global_valid <= 1'b1;
                    end else begin
                        data_out <= 9'b0;
                        global_valid <= 1'b0;
                    end 
                end
                
                
                1'b1: begin
                    if(in_valid) begin 
                        div_a <= input_mod;
                        div_b <= input_mod*input_mod;
                        rdy_a <= 1'b1;
                        rdy_b <= 1'b1;
                        input_count <= input_count + 1;
                    end
                    else if(out_valid_a && out_valid_b) begin
                        if(round_counter == 4'd9) begin
                            global_valid <= 1'b1;
                            data_out <= mod_a;
                            input_count <= input_count + 1;
                        end
                        
                        else begin
                            if(p[round_counter]) begin
                                div_a <= mod_a * mod_b;
                            end else begin
                                div_a <= mod_a;
                            end
                            div_b <= mod_b*mod_b;
                            input_count <= input_count + 1;
                            rdy_a <= 1'b1;
                            rdy_b <= 1'b1;
                            global_valid <= 1'b0;
                        end
                    end
                    else begin
                        rdy_a <= 1'b0;
                        rdy_b <= 1'b0;
                    end
                    
                    if(input_count == 6) begin
                        round_counter <= round_counter+1;
                        input_count <= 0;
                        if(round_counter == 4'd9) begin
                            global_valid <= 1'b0;
                            data_out <= 9'b0;
                            round_counter <= 0;
                        end
                    end
                end
                
                default: begin
                    data_out <= 0;
                end
            endcase
 
        end
    end
endmodule