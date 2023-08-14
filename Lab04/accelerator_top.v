`timescale 1ns / 1ps

module accelerator_top #(
    parameter DATA_WIDTH = 32,
    parameter float_zero = 32'b0_0000_0000_00000000000000000000000,
    parameter float_one = 32'b0_0111_1111_00000000000000000000000,
    parameter learning_rate = 32'h3A83126F
)(
    input clk, rst_n,
    input in_valid_t, in_valid_d,
    input [DATA_WIDTH-1:0] target, data_point,
    
    input in_valid_w1, in_valid_w2,
    input [DATA_WIDTH-1:0] weight1, weight2,
    
    output reg out_valid,
    output reg [DATA_WIDTH-1:0] out
    );
    
    reg [DATA_WIDTH-1:0] data_point_reg [3:0];
    reg [DATA_WIDTH-1:0] target_reg;
    reg [DATA_WIDTH-1:0] weight1_reg [11:0];
    reg [DATA_WIDTH-1:0] weight2_reg [2:0];
    
    integer i, j;
    reg [3:0] State = 0;
    reg [4:0] op_counter = 0, op_counter_2 = 0;
    reg [3:0] out_counter = 0, out_counter_2 = 0;
    reg [1:0] data_counter = 0;
    reg [11:0] iteration = 0;
    reg fw_mult_l1_en, fw_acc_l1_en, fw_mult_l2_en, fw_acc_l2_en;
    
    reg mult_a_valid = 0, mult_b_valid = 0, acc_a_valid = 0, comp_a_valid = 0, comp_b_valid = 0, sub_a_valid = 0, sub_b_valid = 0;
    reg acc_last = 0;
    wire mult_res_valid, acc_res_valid, comp_res_valid, sub_res_valid;
    reg [DATA_WIDTH-1:0] mult_a, mult_b, acc_a, comp_a, comp_b, sub_a, sub_b;
    wire [DATA_WIDTH-1:0] mult_res, acc_res, sub_res;
    wire [7:0] comp_res;
    
    reg [DATA_WIDTH-1:0] forward_mult_l1 [11:0];
    reg [DATA_WIDTH-1:0] forward_acc_l1 [2:0];
    reg [DATA_WIDTH-1:0] relu_l1 [2:0];
    reg [DATA_WIDTH-1:0] forward_mult_l2 [2:0];
    reg [DATA_WIDTH-1:0] result;
    reg [DATA_WIDTH-1:0] err_l2;
    reg [DATA_WIDTH-1:0] err_l1 [2:0];
    reg [2:0] drelu;
    reg [DATA_WIDTH-1:0] eta_delta_2;
    reg [DATA_WIDTH-1:0] eta_delta_1 [2:0];
    reg [DATA_WIDTH-1:0] update_half_2 [2:0];
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_valid <= 0;
            out <= 0;
        end else begin
            case(State)
                4'd0: begin
                    out_valid <= 1'b0;
                    out <= float_zero;
                    
                    if(op_counter == 5'd16) begin
                        State <= 4'd1;
                        op_counter <= 0;
                    end else begin
                        if(in_valid_w1) begin
                            weight1_reg[op_counter] <= weight1;
                            op_counter <= op_counter + 1;
                        end
                        if(in_valid_w2) begin
                            weight2_reg[op_counter] <= weight2;
                        end
                        // first the weights, then the data and target
                        if(in_valid_d) begin
                            data_point_reg[op_counter-12] <= data_point;
                            op_counter <= op_counter + 1;
                        end
                        if(in_valid_t) begin
                            target_reg <= target;
                        end
                    end
                end
                
                4'd13: begin
                    out_valid <= 1'b0;
                    out <= float_zero;
                    
                    if(op_counter == 5'd4) begin
                        State <= 4'd1;
                        op_counter <= 0;
                    end else begin
                        if(in_valid_d) begin
                            data_point_reg[op_counter] <= data_point;
                            op_counter <= op_counter + 1;
                        end
                        if(in_valid_t) begin
                            target_reg <= target;
                        end
                    end
                end
                
                4'd1: begin
                    if(out_counter == 4'd12) begin
                        State <= 4'd2;
                        op_counter <= 0;
                        out_counter <= 0;
                        data_counter <= 0;
                    end else begin
                        if(op_counter < 5'd12) begin 
                            mult_a <= weight1_reg[op_counter];
                            mult_a_valid <= 1'b1;
                            mult_b <= data_point_reg[data_counter];
                            mult_b_valid <= 1'b1;
                            op_counter <= op_counter + 1;
                            data_counter <= data_counter + 1; //auto wrap
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            forward_mult_l1[out_counter] <= mult_res;
                            out_counter <= out_counter + 1;
                        end
                    end
                end
                
                // acc
                4'd2: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd3;
                        op_counter <= 0;
                        out_counter <= 0;
                        out_counter_2 <= 0;
                        data_counter <= 0;
                    end else begin
                        if(data_counter < 2'd3)  begin
                            if(op_counter == 5'd3) begin
                                op_counter <= 0;
                                data_counter <= data_counter + 1;
                                acc_a_valid <= 1'b1;
                                acc_last <= 1'b1;
                                acc_a <= forward_mult_l1[4*data_counter + op_counter];
                            end else begin
                                acc_a_valid <= 1'b1;
                                acc_last <= 1'b0;
                                acc_a <= forward_mult_l1[4*data_counter + op_counter];
                                op_counter <= op_counter + 1;
                            end
                        end else begin
                            acc_a_valid <= 1'b0;
                            acc_last <= 1'b0;
                        end
                        
                        if(acc_res_valid) begin
                            if(out_counter_2 == 3) begin
                                forward_acc_l1[out_counter] <= acc_res;
                                out_counter <= out_counter + 1;
                                out_counter_2 <= 0;
                            end else begin
                                out_counter_2 <= out_counter_2 + 1;
                            end
                            
                        end
                    end
                end
                
                // comp
                4'd3: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd4;
                        op_counter <= 0;
                        out_counter <= 0;
                        comp_a_valid <= 1'b0;
                        comp_b_valid <= 1'b0;
                    end else begin
                        if(op_counter < 5'd3) begin
                            comp_a_valid <= 1'b1;
                            comp_b_valid <= 1'b1;
                            comp_a <= forward_acc_l1[op_counter];
                            comp_b <= float_zero;
                            op_counter <= op_counter + 1;
                        end else begin
                            comp_a_valid <= 1'b0;
                            comp_b_valid <= 1'b0;
                        end
                        
                        if(comp_res_valid) begin
                            if(comp_res[0]) relu_l1[out_counter] <= forward_acc_l1[out_counter];
                            else relu_l1[out_counter] <= float_zero;
                            out_counter <= out_counter + 1;
                        end
                    end
                end
                
                4'd4: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd5;
                        op_counter <= 0;
                        out_counter <= 0;
                    end else begin
                        if(op_counter < 5'd3) begin 
                            mult_a <= weight2_reg[op_counter];
                            mult_a_valid <= 1'b1;
                            mult_b <= relu_l1[op_counter];
                            mult_b_valid <= 1'b1;
                            op_counter <= op_counter + 1;
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            forward_mult_l2[out_counter] <= mult_res;
                            out_counter <= out_counter + 1;
                        end
                    end
                end
                
                4'd5: begin
                    if(out_counter == 4'd2) begin
                        result <= acc_res;
                        op_counter <= 0;
                        out_counter <= 0;
                        State <= 4'd6;
                    end else begin
                        if (op_counter < 5'd3)  begin
                            if (op_counter == 5'd2)  begin
                                acc_last <= 1'b1; 
                            end else begin
                                acc_last <= 1'b0;              
                            end
                            acc_a_valid <= 1'b1;
                            acc_a <= forward_mult_l2[op_counter];
                            op_counter <= op_counter + 1;
                        end else begin
                            acc_a_valid <= 1'b0;
                            acc_last <= 1'b0;
                        end
                        
                        if(acc_res_valid) out_counter <= out_counter + 1;
                    end
                end
                
                // get d(relu) and error of layer 2 at the same time
                4'd6: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd7;
                        op_counter <= 0;
                        op_counter_2 <= 0;
                        out_counter <= 0;
                        comp_a_valid <= 1'b0;
                        comp_b_valid <= 1'b0;
                    end else begin
                        if(op_counter < 5'd3) begin
                            comp_a_valid <= 1'b1;
                            comp_b_valid <= 1'b1;
                            comp_a <= forward_acc_l1[op_counter];
                            op_counter <= op_counter + 1;
                        end else begin
                            comp_a_valid <= 1'b0;
                            comp_b_valid <= 1'b0;
                        end
                        
                        if(comp_res_valid) begin
                            if(comp_res[0]) drelu[out_counter] <= 1'b1;
                            else drelu[out_counter] <=1'b0;
                            out_counter <= out_counter + 1;
                        end
                    end
                    
                    if(sub_res_valid) begin
                        err_l2 <= sub_res;
                    end else begin
                        if (op_counter_2 < 5'd1)  begin
                            sub_a <= result;
                            sub_b <= target_reg;
                            sub_a_valid <= 1'b1;
                            sub_b_valid <= 1'b1;
                            op_counter_2 <= op_counter_2 + 1;
                        end else begin
                            sub_a_valid <= 1'b0;
                            sub_b_valid <= 1'b0;
                        end
                    end
                end

                 // backward layer 1
                4'd7: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd8;
                        op_counter <= 0;
                        out_counter <= 0;
                    end else begin
                        if(op_counter < 5'd3) begin 
                            if(drelu[op_counter]) mult_a <= weight2_reg[op_counter];
                            else mult_a <= float_zero;
                            
                            mult_a_valid <= 1'b1;
                            mult_b <= err_l2;
                            mult_b_valid <= 1'b1;
                            op_counter <= op_counter + 1;
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            err_l1[out_counter] <= mult_res;
                            out_counter <= out_counter + 1;
                        end
                    end
                end
                
                // delta_1_0*learning rate
                4'd8: begin
                    if(mult_res_valid) begin
                        eta_delta_2 <= mult_res;
                        op_counter <= 0;
                        State <= 4'd9;
                    end else begin
                        if (op_counter < 5'd1)  begin
                            mult_a <= learning_rate;
                            mult_b <= err_l2;
                            mult_a_valid <= 1'b1;
                            mult_b_valid <= 1'b1;
                            op_counter <= op_counter + 1;
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                    end
                end
                
                // update layer 2, multiply
                4'd9: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd10;
                        op_counter <= 0;
                        out_counter <= 0;
                    end else begin
                        if(op_counter < 5'd3) begin 
                            mult_a <= eta_delta_2;
                            mult_a_valid <= 1'b1;
                            mult_b <= relu_l1[op_counter];
                            mult_b_valid <= 1'b1;
                            op_counter <= op_counter + 1;
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            update_half_2[out_counter] <= mult_res;
                            out_counter <= out_counter + 1;
                        end
                    end
                end
                
                // update layer 2, subtract; process delta*learning_rate for layer 1
                4'd10: begin
                    if(out_counter == 4'd3) begin
                        State <= 4'd11;
                        op_counter <= 0;
                        out_counter <= 0;
                        out_counter_2 <= 0;
                    end else begin
                        if(op_counter < 5'd3) begin 
                            mult_a <= learning_rate;
                            mult_a_valid <= 1'b1;
                            mult_b <= err_l1[op_counter];
                            mult_b_valid <= 1'b1;
                            
                            sub_a <= weight2_reg[op_counter];
                            sub_b <= update_half_2[op_counter];
                            sub_a_valid <= 1'b1;
                            sub_b_valid <= 1'b1;
                            
                            op_counter <= op_counter + 1;
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                            sub_a_valid <= 1'b0;
                            sub_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            eta_delta_1[out_counter] <= mult_res;
                            out_counter <= out_counter + 1;
                        end
                        
                        if(sub_res_valid) begin
                            weight2_reg[out_counter_2] <= sub_res;
                            out_counter_2 <= out_counter_2 + 1;
                        end
                    end
                end
                
                4'd11: begin
                    if(out_counter_2 == 4'd12) begin
                        State <= 4'd12;
                        op_counter <= 0;
                        out_counter <= 0;
                        out_counter_2 <= 0;
                        data_counter <= 0;
                    end else begin
                        // eta_delta_1 * input data
                        if(data_counter==2'd3) begin
                            data_counter <= 0;
                            op_counter <= op_counter + 1;
                        end
                        
                        if(op_counter < 5'd3) begin
                            mult_a <= eta_delta_1[op_counter];
                            mult_b <= data_point_reg[data_counter];
                            mult_a_valid <= 1'b1;
                            mult_b_valid <= 1'b1;
                            data_counter <= data_counter + 1;
                            
                        end else begin
                            mult_a_valid <= 1'b0;
                            mult_b_valid <= 1'b0;
                        end
                        
                        if(mult_res_valid) begin
                            if (out_counter < 5'd12)  begin // count the mult output
                                sub_a <= weight1_reg[out_counter];
                                sub_b <= mult_res;
                                sub_a_valid <= 1'b1;
                                sub_b_valid <= 1'b1;
                                out_counter <= out_counter + 1;
                            end
                        end else begin
                            sub_a_valid <= 1'b0;
                            sub_b_valid <= 1'b0;
                        end
                        
                        if(sub_res_valid) begin
                            weight1_reg[out_counter_2] <= sub_res;
                            out_counter_2 <= out_counter_2 + 1;
                        end
                    end
                end
                
                // output
                4'd12: begin
                    out_valid <= 1'b1;
                    out <= result;
                    
                    if(iteration < 12'd2500) begin
                        State <= 4'd13;
                        iteration <= iteration + 1;
                        
                    end else begin
                        State <= 4'd0;
                        iteration <= 0;
                    end
                end
            endcase
        end
    end
    
    wire mult_a_tready, mult_b_tready, acc_a_tready, comp_a_tready, comp_b_tready, sub_a_tready, sub_b_tready;
    
    float_ip_mult MULT (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axis_a_tvalid(mult_a_valid),
        .s_axis_a_tdata(mult_a),
        .s_axis_b_tvalid(mult_b_valid),
        .s_axis_b_tdata(mult_b),
        
        .s_axis_a_tready(mult_a_tready),
        .s_axis_b_tready(mult_b_tready),
        .m_axis_result_tvalid(mult_res_valid),
        .m_axis_result_tdata(mult_res)
    );
    
    float_ip_acc ACC (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axis_a_tvalid(acc_a_valid),
        .s_axis_a_tdata(acc_a),
        .s_axis_a_tlast(acc_last),
        .m_axis_result_tready(1'b1),
        
        .s_axis_a_tready(acc_a_tready),
        .m_axis_result_tvalid(acc_res_valid),
        .m_axis_result_tdata(acc_res),
        .m_axis_result_tlast()
    );
    
    float_ip_comp COMP (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axis_a_tvalid(comp_a_valid),
        .s_axis_a_tdata(comp_a),
        .s_axis_b_tvalid(comp_b_valid),
        .s_axis_b_tdata(comp_b),
        .m_axis_result_tready(1'b1),
        
        .s_axis_a_tready(comp_a_tready),
        .s_axis_b_tready(comp_b_tready),
        .m_axis_result_tvalid(comp_res_valid),
        .m_axis_result_tdata(comp_res) // 8bit, LSB=1 when a>b is true
    );
    
    float_ip_sub SUB (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axis_a_tvalid(sub_a_valid),
        .s_axis_a_tdata(sub_a),
        .s_axis_b_tvalid(sub_b_valid),
        .s_axis_b_tdata(sub_b),
        .m_axis_result_tready(1'b1),
        
        .s_axis_a_tready(sub_a_tready),
        .s_axis_b_tready(sub_b_tready),
        .m_axis_result_tvalid(sub_res_valid),
        .m_axis_result_tdata(sub_res)
    );
    
endmodule
