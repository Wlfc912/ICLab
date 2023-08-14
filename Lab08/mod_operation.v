`timescale 1ns / 1ps


module mod_operation(
    input clk, rst_n,
    input rdy,
    input [17:0] dividend,
    output reg [8:0] remainder,
    output reg out_valid
    );
    
    localparam [8:0] divisor = 9'd509;
    
    reg [17:0] r_remainder [10:0];
    reg [17:0] shift_dividend [10:0];
    reg r_outvalid [10:0];
    
    integer i,j;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        // reset
            out_valid <= 1'b0;
            for(j=0;j<=10;j=j+1) begin
                r_remainder[i] <= 18'b0;
                shift_dividend[i] <= 18'b0;
                r_outvalid[i] <= 9'b0;
            end            
        end
        
        else begin
            if(rdy) begin
                r_remainder[10] <= dividend;
                shift_dividend[10] <= {divisor, 9'b0};
                r_outvalid[10] <= 1'b1;
            end else begin
                r_outvalid[10] <= 1'b0;
            end
            
            for(i=9; i>=0; i = i-1) begin
                if(shift_dividend[i+1] <= r_remainder[i+1]) begin
                    r_remainder[i] <= r_remainder[i+1] - shift_dividend[i+1];
                end else begin
                    r_remainder[i] <= r_remainder[i+1];
                end
                
                shift_dividend[i] <= shift_dividend[i+1] >> 1;
                r_outvalid[i] <= r_outvalid[i+1];
            end
            
            if(r_outvalid[0]) begin
                remainder <= r_remainder[0][8:0];
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
            
        end
    end
    
    
    
    
endmodule
