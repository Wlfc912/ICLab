`timescale 1ns / 1ps


module mod_mult(
    input clk, rst_n, in_valid,
    input mode,
    input [8:0] data_in,
    output reg out_valid,
    output reg [8:0] data_out,
    output reg [2:0] output_counter
    );
    
    reg [8:0] mem_0 [5:0], mem_1 [5:0], mem_2 [5:0], mem_3 [5:0], mem_4 [5:0];
    reg local_rdy, mem_rdy = 1'b0;
    integer input_counter = 0;
    integer calc_counter = 0;
    integer round_counter = 0;
    integer i;
    
    reg rdy;
    reg [17:0] div;
    wire [8:0] mod_res;
    wire mod_out_valid;
    
    mod_operation MOD_MULT (
        .clk(clk),
        .rst_n(rst_n),
        .rdy(rdy),
        .dividend(div),
        .remainder(mod_res),
        .out_valid(mod_out_valid)
    );
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input_counter <= 0;
            for(i=0; i<5; i=i+1) begin
                mem_0[i] <= 9'b0;
                mem_1[i] <= 9'b0;
                mem_2[i] <= 9'b0;
                mem_3[i] <= 9'b0;
                mem_4[i] <= 9'b0;
            end
        end
        else begin
            if(in_valid) begin
                case(input_counter)
                    0: begin
                        mem_0[1] <= data_in;
                        mem_0[2] <= data_in;
                        mem_0[3] <= data_in;
                        mem_0[4] <= data_in;
                        mem_0[5] <= data_in;
                    end
                    
                    1: begin
                        mem_0[0] <= data_in;
                        mem_1[2] <= data_in;
                        mem_1[3] <= data_in;
                        mem_1[4] <= data_in;
                        mem_1[5] <= data_in;
                    end
                    
                    2: begin
                        mem_1[0] <= data_in;
                        mem_1[1] <= data_in;
                        mem_2[3] <= data_in;
                        mem_2[4] <= data_in;
                        mem_2[5] <= data_in;
                    end
                    
                    3: begin
                        mem_2[0] <= data_in;
                        mem_2[1] <= data_in;
                        mem_2[2] <= data_in;
                        mem_3[4] <= data_in;
                        mem_3[5] <= data_in;
                    end
                    
                    4: begin
                        mem_3[0] <= data_in;
                        mem_3[1] <= data_in;
                        mem_3[2] <= data_in;
                        mem_3[3] <= data_in;
                        mem_4[5] <= data_in;
                    end
                    
                    5: begin
                        mem_4[0] <= data_in;
                        mem_4[1] <= data_in;
                        mem_4[2] <= data_in;
                        mem_4[3] <= data_in;
                        mem_4[4] <= data_in;
                    end
                
                endcase
                
                if(input_counter==5) begin
                    input_counter <= 0;
                end else begin
                    input_counter <= input_counter + 1;
                end
            end
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        end
        else begin
            if(in_valid && input_counter == 5) begin
                mem_rdy <= 1'b1;
            end else if(out_valid) begin
                mem_rdy <= 1'b0;
            end
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_valid <= 0;
            data_out <= 9'b0;
            rdy <= 1'b0;
            output_counter <= 0;
        end
        else begin
            case (mode)
                1'b0: begin
                    if(in_valid) begin
                        data_out <= data_in;
                        out_valid <= 1'b1;
                    end else begin
                        data_out <= 9'b0;
                        out_valid <= 1'b0;
                    end    
                end
                
                1'b1: begin
                    case(round_counter)
                        0: begin
                            if(mem_rdy) begin
                                div <= mem_0[calc_counter] * mem_1[calc_counter];
                                calc_counter <= calc_counter+1;
                                rdy <= 1'b1;
                            end 
                        end
                        1: begin
                            if(mod_out_valid) begin
                                div <= mod_res * mem_2[calc_counter];
                                calc_counter <= calc_counter+1;
                                rdy <= 1'b1;
                            end
                            else begin
                                rdy <= 1'b0;
                            end
                        end
                        2: begin
                            if(mod_out_valid) begin
                                div <= mod_res * mem_3[calc_counter];
                                calc_counter <= calc_counter+1;
                                rdy <= 1'b1;
                            end
                            else begin
                                rdy <= 1'b0;
                            end
                        end
                        3: begin
                            if(mod_out_valid) begin
                                div <= mod_res * mem_4[calc_counter];
                                calc_counter <= calc_counter+1;
                                rdy <= 1'b1;
                            end
                            else begin
                                rdy <= 1'b0;
                            end
                        end
                        
                        4: begin
                            rdy <= 1'b0;
                            if(mod_out_valid) begin
                                out_valid <= 1'b1;
                                data_out <= mod_res;
                                output_counter <= output_counter + 1;
                            end
                        end
                        
                        default: begin
                        end
                    endcase
                    
                    
                    if(calc_counter == 6) begin
                        round_counter <= round_counter+1;
                        calc_counter <= 0;
                    end
                    
                    if(output_counter==6) begin
                        output_counter <= 0;
                        data_out <= 9'b0;
                        out_valid  <= 1'b0;
                        round_counter <= 0;
                    end
                end  
                
                
                default: begin
                    out_valid <= 1'b0;
                    rdy <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
