`timescale 1ns / 1ps


module sort(
     input [9:0] sort_in_0, sort_in_1, sort_in_2, sort_in_3, sort_in_4, sort_in_5,
    output [9:0] sort_out_0, sort_out_1, sort_out_2, sort_out_3, sort_out_4, sort_out_5
    );
    
    wire [9:0] a[1:0], b[2:0], c[1:0], d[2:0], e[3:0], f[1:0];
    // a for the larger in a pair, b for the smaller
    assign a[0] = sort_in_0 >= sort_in_1 ? sort_in_0 : sort_in_1;
    assign a[1] = sort_in_0 >= sort_in_1 ? sort_in_1: sort_in_0;
    
    assign b[0] = sort_in_2 >= a[0] ? sort_in_2 : a[0];
    assign b[1] = sort_in_2 >= a[0] ? a[0] : sort_in_2 >= a[1] ? sort_in_2 : a[1];
    assign b[2] = sort_in_2 < a[1] ? sort_in_2 : a[1];
    
    assign c[0] = sort_in_3 >= sort_in_4 ? sort_in_3 : sort_in_4;
    assign c[1] = sort_in_3 >= sort_in_4 ? sort_in_4 : sort_in_3;
    
    assign d[0] = sort_in_5 >= c[0] ? sort_in_5 : c[0];
    assign d[1] = sort_in_5 >= c[0] ? c[0] : sort_in_5 >= c[1] ? sort_in_5 : c[1];
    assign d[2] = sort_in_5 < c[1] ? sort_in_5 : c[1];
    
    assign sort_out_0 = d[0] >= b[0] ? d[0] : b[0];
    assign sort_out_5 = d[2] >= b[2] ? b[2] : d[2];
    
    assign e[0] = d[0] >= b[0] ? b[0] : d[0]; //the smaller of the largest two
    assign e[1] = d[1] >= b[1] ? d[1] : b[1]; //the larger of the middle two
    assign e[2] = d[1] >= b[1] ? b[1] : d[1]; //the smaller of the middle two
    assign e[3] = d[2] >= b[2] ? d[2] : b[2]; //the larger of the smallest two
    
    assign sort_out_1 = e[0] >= e[1] ? e[0] : e[1];
    assign sort_out_4 = e[3] < e[2]  ? e[3] : e[2];
    
    assign f[0] = e[0] >= e[1] ? e[1] : e[0]; 
    assign f[1] = e[3] < e[2]  ? e[2] : e[3]; //the remaining two still need to be compared
    
    assign sort_out_2 = f[0] >= f[1] ? f[0] : f[1];
    assign sort_out_3 = f[0] >= f[1] ? f[1] : f[0];
   
endmodule