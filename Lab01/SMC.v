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

    //wire [9:0] unsorted_id [5:0];
    //wire [9:0] unsorted_gm [5:0];
    
    wire [9:0] sort_in [5:0];
    
    wire [9:0] sorted [5:0];
    wire [9:0] out_elements [2:0];
	
	wire [2:0] W [0:5];
	assign W[0] = W_0;
	assign W[1] = W_1;
	assign W[2] = W_2;
	assign W[3] = W_3;
	assign W[4] = W_4;
	assign W[5] = W_5;
	
	wire [2:0] V_GS [0:5];
	assign V_GS[0] = V_GS_0;
	assign V_GS[1] = V_GS_1;
	assign V_GS[2] = V_GS_2;
	assign V_GS[3] = V_GS_3;
	assign V_GS[4] = V_GS_4;
	assign V_GS[5] = V_GS_5;
	
	wire [2:0] V_DS [0:5];
	assign V_DS[0] = V_DS_0;
	assign V_DS[1] = V_DS_1;
	assign V_DS[2] = V_DS_2;
	assign V_DS[3] = V_DS_3;
	assign V_DS[4] = V_DS_4;
	assign V_DS[5] = V_DS_5;
	
	wire [5:0] is_Triode;
	//wire [2:0] gm_op1 [5:0];
	wire [2:0] shared_op [5:0];
	wire [3:0] id_op [5:0];
	
	//wire [2:0] op1 [5:0];
	//wire [2:0] op2 [5:0];
	wire [3:0] op3 [5:0];
	genvar idx;
    
	generate
		for( idx=0 ; idx<6 ; idx=idx+1 ) begin
			assign is_Triode[idx] = (V_GS[idx]-1 > V_DS[idx]) ? 1'b1 : 1'b0;
		end
	endgenerate
	
	generate
		for( idx=0 ; idx<6 ; idx=idx+1 ) begin
			assign shared_op[idx] = is_Triode[idx] ? V_DS[idx] : V_GS[idx]-1; // gm and id share V_DS*W and W*(V_GS-1)
			assign id_op[idx] = is_Triode[idx] ? (2*V_GS[idx]-V_DS[idx]-2) : V_GS[idx]-1;
		end
	endgenerate
	
	generate
		for( idx=0 ; idx<6 ; idx=idx+1 ) begin
			assign op3[idx] = mode[0] ? id_op[idx]: 2'd2;
		end
	endgenerate
	
	generate
		for( idx=0 ; idx<6 ; idx=idx+1 ) begin
			assign sort_in[idx] = W[idx] * shared_op[idx] * op3[idx] / 3;
		end
	endgenerate

    
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
