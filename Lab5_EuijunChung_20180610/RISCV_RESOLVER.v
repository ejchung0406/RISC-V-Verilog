module RESOLVER(
	input wire taken_pw_pw,
	input wire [1:0] isBranch_pw,
	input wire PCsrc_pw,
	input wire CLK,
	output reg wrong=1'b0
	);

	reg w;
	
	always @(negedge CLK) begin
		if(w) wrong <= 1'b1;
		else wrong <= 1'b0;
	end

	always @(*) begin
		// branch 일때, taken 이랑 isbranch가 일치하면 w=0, 다르면 1
		// jump일때, taken 안했으면 w = 1이 되어야 함 
		if(isBranch_pw[1])
			w = (taken_pw_pw == isBranch_pw[0]) ? 0 : 1;
		else
			w = (!PCsrc_pw && !taken_pw_pw) ? 1 : 0;
	end 
endmodule
