`timescale 1ns / 1ps

module SMC(
    input [1:0] mode,
    input [2:0] W_0, V_GS_0, V_DS_0,
    input [2:0] W_1, V_GS_1, V_DS_1,
    input [2:0] W_2, V_GS_2, V_DS_2,
    input [2:0] W_3, V_GS_3, V_DS_3,
    input [2:0] W_4, V_GS_4, V_DS_4,
    input [2:0] W_5, V_GS_5, V_DS_5,

    output [9:0] out_n
);

    wire [9:0] unsorted_id [5:0];
    wire [9:0] unsorted_gm [5:0];
    
    wire [9:0] sort_in [5:0];
    
    wire [9:0] sorted [5:0];
    wire [9:0] out_elements [2:0];
     
    assign unsorted_id[0] = (V_GS_0-1 > V_DS_0) ? V_DS_0*W_0*(2*V_GS_0-V_DS_0-2)/3 : W_0*(V_GS_0-1)*(V_GS_0-1)/3;
    assign unsorted_id[1] = (V_GS_1-1 > V_DS_1) ? V_DS_1*W_1*(2*V_GS_1-V_DS_1-2)/3 : W_1*(V_GS_1-1)*(V_GS_1-1)/3;
    assign unsorted_id[2] = (V_GS_2-1 > V_DS_2) ? V_DS_2*W_2*(2*V_GS_2-V_DS_2-2)/3 : W_2*(V_GS_2-1)*(V_GS_2-1)/3;
    assign unsorted_id[3] = (V_GS_3-1 > V_DS_3) ? V_DS_3*W_3*(2*V_GS_3-V_DS_3-2)/3 : W_3*(V_GS_3-1)*(V_GS_3-1)/3;
    assign unsorted_id[4] = (V_GS_4-1 > V_DS_4) ? V_DS_4*W_4*(2*V_GS_4-V_DS_4-2)/3 : W_4*(V_GS_4-1)*(V_GS_4-1)/3;
    assign unsorted_id[5] = (V_GS_5-1 > V_DS_5) ? V_DS_5*W_5*(2*V_GS_5-V_DS_5-2)/3 : W_5*(V_GS_5-1)*(V_GS_5-1)/3;
    
    assign unsorted_gm[0] = (V_GS_0-1 > V_DS_0) ? 2*W_0*V_DS_0/3 : 2*W_0*(V_GS_0-1)/3;
    assign unsorted_gm[1] = (V_GS_1-1 > V_DS_1) ? 2*W_1*V_DS_1/3 : 2*W_1*(V_GS_1-1)/3;
    assign unsorted_gm[2] = (V_GS_2-1 > V_DS_2) ? 2*W_2*V_DS_2/3 : 2*W_2*(V_GS_2-1)/3;
    assign unsorted_gm[3] = (V_GS_3-1 > V_DS_3) ? 2*W_3*V_DS_3/3 : 2*W_3*(V_GS_3-1)/3;
    assign unsorted_gm[4] = (V_GS_4-1 > V_DS_4) ? 2*W_4*V_DS_4/3 : 2*W_4*(V_GS_4-1)/3;
    assign unsorted_gm[5] = (V_GS_5-1 > V_DS_5) ? 2*W_5*V_DS_5/3 : 2*W_5*(V_GS_5-1)/3;

    assign sort_in[0] = mode[0] ? unsorted_id[0] : unsorted_gm[0];
    assign sort_in[1] = mode[0] ? unsorted_id[1] : unsorted_gm[1];
    assign sort_in[2] = mode[0] ? unsorted_id[2] : unsorted_gm[2];
    assign sort_in[3] = mode[0] ? unsorted_id[3] : unsorted_gm[3];
    assign sort_in[4] = mode[0] ? unsorted_id[4] : unsorted_gm[4];
    assign sort_in[5] = mode[0] ? unsorted_id[5] : unsorted_gm[5];
    
    sort SORT (
        .sort_in_0(sort_in[0]), 
        .sort_in_1(sort_in[1]), 
        .sort_in_2(sort_in[2]), 
        .sort_in_3(sort_in[3]), 
        .sort_in_4(sort_in[4]), 
        .sort_in_5(sort_in[5]),
        .sort_out_0(sorted[0]),
        .sort_out_1(sorted[1]), 
        .sort_out_2(sorted[2]), 
        .sort_out_3(sorted[3]), 
        .sort_out_4(sorted[4]), 
        .sort_out_5(sorted[5])
    );
    
    assign out_elements[0] = mode[1] ? sorted[0] : sorted[3];
    assign out_elements[1] = mode[1] ? sorted[1] : sorted[4];
    assign out_elements[2] = mode[1] ? sorted[2] : sorted[5];
    
    assign out_n = mode[0] ? 3*out_elements[0] + 4*out_elements[1] + 5*out_elements[2] : out_elements[0] + out_elements[1] + out_elements[2];

endmodule

module sort(
    input [9:0] sort_in_0, sort_in_1, sort_in_2, sort_in_3, sort_in_4, sort_in_5,
    output [9:0] sort_out_0, sort_out_1, sort_out_2, sort_out_3, sort_out_4, sort_out_5
);
    wire [9:0] a[1:0], b[2:0], c[1:0], d[2:0], e[3:0], f[1:0];
    // a for the larger in a pair, b for the smaller
    assign a[0] = sort_in_0 >= sort_in_1 ? sort_in_0 : sort_in_1;
    assign a[1] = sort_in_0 >= sort_in_1 ? sort_in_1 : sort_in_0;
    
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
