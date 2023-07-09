module DFF #(parameter SIZE = 1) (
	input wire [SIZE-1:0] D,
	input wire CLK,
	input wire wrong,
	input wire stall,
	output reg [SIZE-1:0] Q=0
	);

	always @(posedge CLK) begin
		if (!stall) begin
			if(wrong) begin
				Q <= {SIZE{1'b0}};
			end
			else Q <= D; 
		end
	end 
endmodule

module DFF_neg #(parameter SIZE = 1) (
	input wire [SIZE-1:0] D,
	input wire CLK,
	input wire wrong,
	input wire stall,
	output reg [SIZE-1:0] Q=0
	);

	always @(posedge CLK) begin
		if (!stall) begin
			if(wrong) begin
				Q <= {SIZE{1'b1}};
			end
			else Q <= D; 
		end
	end 
endmodule