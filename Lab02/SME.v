module SME(
	input clk, rst_n,
	input ispattern, isstring,
	input [7:0] chardata,
	
	output reg out_valid,
	output reg match,
	output reg [4:0] match_index
);
	
	reg [7:0] in_string [33:0];
	reg [7:0] in_pattern [7:0];
	reg [5:0] str_cnt, str_cnt_restore;
	reg [3:0] pat_cnt, preprocess_cnt;
	reg [5:0] comp_str_front1, comp_str_front2;
	
	reg [1:0] state_preprocess;
	reg has_star;
	reg [2:0] star_type; // 0: no star; 1: star at the end; 2: star at the front; 3: star in the middle; 4: default for reset
	reg [2:0] star_pos;
	reg [2:0] pat1_start, pat2_start; // starting position of 2 patterns
	reg [2:0] pat1_len, pat2_len;
	reg [7:0] output_bus, output_bus2;
	
	// for the output state
	reg has_sol, local_match;
	reg [4:0] local_match_index;
	
	localparam  Wait_str = 3'd0,
				Str_in = 3'd1,
				Wait_pat = 3'd2,
				Pat_in = 3'd3,
				Pat_preprocess = 3'd4,
				Onepat = 3'd5,
				Twopats = 3'd6,
				Output = 3'd7;
	reg [2:0] curr_state = Wait_str;
	reg [2:0] next_state = Wait_str;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) curr_state <= Wait_str;
		else curr_state <= next_state;
	end
	
	always@(*) begin
		case(curr_state)
			Wait_str: begin
				if(ispattern) next_state = Pat_in;
				else if(isstring) next_state = Str_in;
				else next_state = Wait_str;
			end
			
			Str_in: begin
				if(!isstring) next_state = Wait_pat;
				else next_state = Str_in;
			end
			
			Wait_pat: begin
				if(ispattern) next_state = Pat_in;
				else next_state = Wait_pat;
				
				str_cnt_restore = str_cnt;
			end
			
			Pat_in: begin				
				if(!ispattern) next_state = Pat_preprocess;
				else next_state = Pat_in;
			end
			
			Pat_preprocess: begin
			    if(state_preprocess==2'd2) begin
                    if(star_type == 3'd3) next_state = Twopats;
                    else next_state = Onepat;
				end else next_state = Pat_preprocess;
			end
			
			Onepat: begin
				if(has_sol) next_state = Output; // find match
				else if(comp_str_front1+pat_cnt == str_cnt+3) next_state = Output; // reach the end
				else next_state = Onepat; // continue
			end
			Twopats: begin
				if(has_sol) next_state = Output; // find match
				else if(comp_str_front2+pat2_len == str_cnt+3) next_state = Output; // reach the end
				else next_state = Twopats; // continue
			end
			
			Output: begin
				next_state = Wait_str; // only 1 cycle output
			end
		endcase
	end
	
	integer i, j;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			str_cnt <= 0;
			in_string[0] <= 8'd32; // space
			in_string[33] <= 8'd32;
			for(i=0; i<32; i=i+1) begin
				in_string[i] <= 8'd32;
			end
			
			preprocess_cnt <= 4'd0;
			pat_cnt <= 4'd0;
			preprocess_cnt <= 4'd0; 
			has_star <= 1'b0;
			star_pos <= 3'd0;
			for(j=0; j<8; j=j+1) begin
				in_pattern[j] <= 8'd32;
			end
			
			comp_str_front1 <= 5'd0;
			comp_str_front2 <= 5'd0;
			has_sol <= 1'b0;
			local_match <= 1'b0;
			local_match_index <= 5'd0;
			
			state_preprocess <= 2'd0;
			out_valid <= 1'b0;
			match <= 1'b0;
			match_index <= 5'd0;
		end else begin
			case(next_state)
				Wait_str: begin
					str_cnt <= 0;
					preprocess_cnt <= 4'd0;
					pat_cnt <= 4'd0; 
					preprocess_cnt <= 4'd0;
					has_star <= 1'b0;
					comp_str_front1 <= 5'd0;
					comp_str_front2 <= 5'd0;
					out_valid <= 1'b0;
					match <= 1'b0;
					match_index <= 5'd0;
					has_sol <= 1'b0;
					local_match <= 1'b0;
					local_match_index <= 5'd0;
					state_preprocess <= 2'd0;
				end
				
				Str_in: begin
					str_cnt <= str_cnt + 1;
					in_string[str_cnt+1] <= chardata;
				end
				
				Wait_pat: begin
				end
				
				Pat_in: begin
					in_pattern[preprocess_cnt] <= chardata;
					preprocess_cnt <= preprocess_cnt + 1;
					str_cnt <= str_cnt_restore;
				end
				
				Pat_preprocess: begin
				    if(state_preprocess<2) state_preprocess <= state_preprocess+1;
				    
				    for(i=0; i<preprocess_cnt; i=i+1) begin
				        if(in_pattern[i] == 8'd42) begin
				            has_star <= 1'b1;
							star_pos <= i;
				        end
				    end
				    
					pat_cnt <= preprocess_cnt;
					in_string[str_cnt+1] <= 8'd32;
					comp_str_front1 <= comp_str_front1;
                    comp_str_front2 <= comp_str_front1+pat1_len;
				end
				
				Onepat: begin
					if(&output_bus) begin 
						has_sol <= 1'b1;
						local_match <= 1'b1;
						
						if(star_type == 3'd2) local_match_index <= 0;
						else if(in_pattern[0] == 8'd94) local_match_index <= comp_str_front1;
						else local_match_index <= comp_str_front1-1;
					end else begin
						local_match <= 1'b0;
						local_match_index <= 1'b0;
						comp_str_front1 <= comp_str_front1 + 1;
					end
				end
				
				Twopats: begin
					if(&output_bus) begin
						if(&output_bus2) begin
							has_sol <= 1'b1;
							local_match <= 1'b1;
							
							if(in_pattern[0] == 8'd94) local_match_index <= comp_str_front1;
						    else local_match_index <= comp_str_front1-1;
						end else begin
							local_match <= 1'b0;
							local_match_index <= 1'b0;
							comp_str_front2 <= comp_str_front2 + 1;
						end
					end else begin
						local_match <= 1'b0;
						local_match_index <= 1'b0;
						comp_str_front1 <= comp_str_front1 + 1;
						comp_str_front2 <= comp_str_front1+pat1_len+1;
					end
				end
				
				Output: begin
					// provide output
					out_valid <= 1'b1;
					match <= local_match;
					match_index <= local_match_index;
				end
			endcase
		end
	end
	
	// will be available when pattern ggf. string input is complete
	always@(*) begin
		if(curr_state == Wait_str) begin
			star_type = 3'd4;
		end else begin
			if(has_star) begin
				case(star_pos)
					2'd0: begin // at the front
						// comparison starts from in_pattern[1], if match, match index = 0
						star_type = 3'd2;
						pat1_len = pat_cnt-1;
					end
					
					pat_cnt-1: begin // at the end
						star_type = 3'd1;
						pat1_len = pat_cnt-1;
					end
					
					default: begin // in the middle
						star_type = 3'd3;
						pat1_len = star_pos;
						pat2_len = pat_cnt-pat1_len-1;
					end
				endcase
			end else begin // no star
				star_type = 3'd0;
				pat1_len = pat_cnt;
			end
		end
		
	end
	
	wire peek;
	assign peek = in_string[0] == in_pattern[0];
	
	integer k, l;
	always@(*) begin
	       case(star_type)
			3'd0: begin
				for(k=0; k<pat_cnt; k=k+1) begin
				    case(in_pattern[k])
				        // point at front and end
				        8'd46: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = 1'b1;
				        end
				        
				        8'd36, 8'd94: output_bus[k] = in_string[comp_str_front1+k] == 8'd32;
				        
				        // space at front and end, ignore spaces that are actually ^ and $
				        8'd32: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				        end
				        
				        default: output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				    endcase
				end
			end
			
			3'd1: begin // star at the end, compare till in_pattern[pat_cnt-2]
				for(k=0; k<pat_cnt-1; k=k+1) begin
					case(in_pattern[k])
				        8'd46: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = 1'b1;
				        end
				        
				        8'd36, 8'd94: output_bus[k] = in_string[comp_str_front1+k] == 8'd32;
				        
				        8'd32: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				        end
				        
				        default: output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				    endcase
				end
			end
			
			3'd2: begin // star at the front, compare from in_pattern[1]
				for(k=1; k<pat_cnt; k=k+1) begin
					case(in_pattern[k])
				        8'd46: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = 1'b1;
				        end
				        
				        8'd36, 8'd94: output_bus[k] = in_string[comp_str_front1+k] == 8'd32;
				        
				        8'd32: begin
				            if((comp_str_front1==0 && k==0) || (k==pat_cnt-1 && comp_str_front1 == str_cnt-pat1_len+2)) output_bus[k] = 1'b0;
				            else output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				        end
				        
				        default: output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				    endcase
				end
			end
			
			3'd3: begin // star in the middle, compare 2 patterns, match_idx_1 + pat1_len <= match_idx_2
				for(k=0; k<pat1_len; k=k+1) begin
					case(in_pattern[k])
				        8'd46: begin
				            if(comp_str_front1==0 && k==0) output_bus[k] = 1'b0;
				            else output_bus[k] = 1'b1;
				        end
				        
				        8'd36, 8'd94: output_bus[k] = in_string[comp_str_front1+k] == 8'd32;
				        
				        8'd32: begin
				            if(comp_str_front1==0 && k==0) output_bus[k] = 1'b0;
				            else output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				        end
				        
				        default: output_bus[k] = in_string[comp_str_front1+k] == in_pattern[k];
				    endcase
				end
				
				for(l=0; l<pat2_len; l=l+1) begin
					case(in_pattern[l+pat1_len+1])
				        8'd46: begin
				            if(comp_str_front2 == str_cnt-pat2_len+2 && l==pat2_len-1) output_bus2[l] = 1'b0;
				            else output_bus2[l] = 1'b1;
				        end
				        
				        8'd36, 8'd94: output_bus2[l] = in_string[comp_str_front2+l] == 8'd32;
				        
				        8'd32: begin
				            if(comp_str_front2 == str_cnt-pat2_len+2 && l==pat2_len-1) output_bus2[l] = 1'b0;
				            else output_bus2[l] = in_string[comp_str_front2+l] == in_pattern[l+pat1_len+1];
				        end
				        
				        default: output_bus2[l] = in_string[comp_str_front2+l] == in_pattern[l+pat1_len+1];
				    endcase
				end
			end
			
			default: begin
				output_bus = 8'b1111_1111;
				output_bus2 = 8'b1111_1111;
			end
				
		  endcase
	end

endmodule
