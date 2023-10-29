//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
//`include "SME.v"
`define CYCLE_TIME 5.0

module tb_SME();
    reg clk,rst_n,isstring,ispattern;
	reg [7:0] chardata;
	wire out_valid,match;
	wire [4:0] match_index;
	
	SME uut(
		.clk(clk),
		.rst_n(rst_n),
		.ispattern(ispattern),
		.isstring(isstring),
		.chardata(chardata),
		
		.out_valid(out_valid),
		.match(match),
		.match_index(match_index)
    );

	

	//================================================================
	// wires & registers
	//================================================================
	reg [255:0] in_str;
	reg [63:0]  in_pat;
	reg [4:0] golden_index;
	reg golden_match;
	//================================================================
	// parameters & integer
	//================================================================
	parameter MAX_STR = 32;
	parameter MAX_PAT = 8;

	integer PATNUM;
	integer pattern_num;
	integer total_pat;
	integer total_cycles;
	integer patcount;
	integer cycles;
	integer a, bb, c, i, p, pat_file, out, out2;
	integer color_stage = 0, color, r = 5, g = 0, b = 0;
	integer scnum, pcnum, gap;
	//================================================================
	// clock
	//================================================================
	always	#(`CYCLE_TIME/2.0) clk = ~clk;
	initial	clk = 0;
	//================================================================
	// initial
	//================================================================
	initial begin
		pat_file = $fopen("/mnt/ssd01/home/sung/work/ICLAB/Lab02/Lab02.srcs/sim_1/new/pat.txt", "r");
		out = $fopen("data_out.txt", "w");
		//out2 = $fopen(".02_play", "w");
		a = $fscanf(pat_file,"%d\n",PATNUM);
		ispattern = 0;
		isstring  = 0;
		chardata = 8'bx;
		golden_index = 0;
		golden_match = 0;
		rst_n = 1;

		force clk = 0;
		reset_task;
		total_cycles = 0;
		total_pat = 0;

		@(negedge clk);

		for (patcount=0;patcount<PATNUM;patcount=patcount+1)begin
			string_task;
			delay_task;
			a = $fscanf(pat_file,"%d\n",pattern_num);
			total_pat = total_pat + pattern_num;
			for(p=0;p<pattern_num;p=p+1)begin
				pattern_task;
				wait_outvalid;
				check_ans;
				delay_task;
			end
			case(color_stage)
				0: begin
					r = r - 1;
					g = g + 1;
					if(r == 0) color_stage = 1;
				end
				1: begin
					g = g - 1;
					b = b + 1;
					if(g == 0) color_stage = 2;
				end
				2: begin
					b = b - 1;
					r = r + 1;
					if(b == 0) color_stage = 0;
				end
			endcase
			color = 16 + r*36 + g*6 + b;
			if(color < 100) $display("\033[38;5;%2dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
			else $display("\033[38;5;%3dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
		end
		#(1000);
		YOU_PASS_task;
		$finish;
	end
	//================================================================
	// env task
	//================================================================
	task reset_task ; begin
		#(0.5); rst_n = 0;

		#(2.0);
		if((match !== 0) || (match_index !== 0) || (out_valid !== 0)) begin
			fail;
			$fwrite ( out, "--------------------------------------------------------------------------------------------------------------------------------------------\n");
			$fwrite ( out, "                                                                        FAIL!                                                               \n");
			$fwrite ( out, "                                                  Output signal should be 0 after initial RESET at %8t                                      \n",$time);
			$fwrite ( out, "--------------------------------------------------------------------------------------------------------------------------------------------\n");
	//		$fwrite ( out2, "cd .play/; python play.py");
			#(100);
			$finish ;
		end
		
		#(1.0); rst_n = 1 ;
		#(3.0); release clk;
	end endtask

	task delay_task ; begin
		gap = $urandom_range(1, 5);
		repeat(gap)@(negedge clk);
	end endtask
	//================================================================
	// input task
	//================================================================
	task string_task ; begin
		isstring = 1;
		in_str = 'dx;
		a = $fscanf(pat_file,"%d\n",scnum);
		for(i=0;i<scnum;i=i+1)begin
			a = $fscanf(pat_file,"%d\n",chardata);
			in_str[(MAX_STR-i-1)*8+:8] = chardata;
			@(negedge clk);
		end
		isstring = 0;
		chardata = 8'bx;
	end endtask

	task pattern_task ; begin
		ispattern = 1;	
		in_pat = 'dx;
		bb = $fscanf(pat_file ,"%d",pcnum);
		for(i=0;i<pcnum;i=i+1)begin
			bb = $fscanf(pat_file ,"%d",chardata);
			in_pat[(MAX_PAT-i-1)*8+:8] = chardata;
			@(negedge clk);
		end
		golden_match=0;
		golden_index=0;

		ispattern = 0;
		chardata = 8'bx;
	end endtask
	//================================================================
	// ans task
	//================================================================
	task wait_outvalid ; begin
		cycles = 0;
		while(out_valid === 0)begin
			cycles = cycles + 1;
			if(cycles == 400) begin
				fail;
				$fwrite (out, "--------------------------------------------------------------------------------------------------------------------------------------------\n");
				$fwrite (out, "                                                                                                                                            \n");
				$fwrite (out, "                                                     The execution latency are over 400 cycles                                              \n");
				$fwrite (out, "                                                                                                                                            \n");
				$fwrite (out, "--------------------------------------------------------------------------------------------------------------------------------------------\n");
	//			$fwrite ( out2, "cd .play/; python play.py");
				repeat(2)@(negedge clk);
				$finish;
			end
		@(negedge clk);
		end
		total_cycles = total_cycles + cycles;
	end endtask

	task check_ans ; begin
		if(out_valid === 1) begin
			c = $fscanf(pat_file,"%d%d",golden_match,golden_index);
			if(	(match !== golden_match) || (match_index !== golden_index)) begin
				fail;
				$display (out, "--------------------------------------------------------------------------------------------------------------------------------------\n");
				$display (out, "                                                                     FAIL!                                                            \n");
				$display (out, "                                                             Pattern NO.%03d - %03d                                                   \n", patcount, p);
				$display (out, "                                                      Input Str -> Char Num: %2d, %s                                  \n", scnum, in_str);
				$display (out, "                                                      Input Pat -> Char Num: %2d, %s                                \n", pcnum, in_pat);
				$display (out, "                                                    Your output -> Match: %d,  Index: %d                                              \n", match, match_index);
				$display (out, "                                                    Golden output -> Match: %d,  Index: %d                                              \n", golden_match, golden_index);
				$display (out, "--------------------------------------------------------------------------------------------------------------------------------------\n");
	//			$fwrite ( out2, "cd .play/; python play.py");
				@(negedge clk);
				$finish;
			end
		end
	end endtask

	task YOU_PASS_task;begin
	//image_.success;
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						             ");
	$display ("                                           You have passed all patterns!          						             ");
	$display ("                                                                                 						             ");
	$display ("                                        Your execution cycles   = %5d cycles      						             ", total_cycles);
	$display ("                                        Your clock period       = %.1f ns        					                 ", `CYCLE_TIME);
	$display ("                                        Total latency           = %.1f ns             						         ", (total_cycles + total_pat)*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");

	$finish;	
	end endtask

	task fail; begin

	//fail_.fail;
	end endtask

endmodule
