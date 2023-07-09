`timescale 1ns / 100ps

module BCOND(
	input wire signed [31:0] A,
	input wire signed [31:0] B,
	output reg [2:0] Cout
	);

	initial begin
    end

    always @(*) begin
		// First bit: whether equal (1) or not equal (0)
		// Second bit: whether A is bigger (1) or B is bigger (0) in signed number
		// Third bit: whether A is bigger (1) or B is bigger (0) in unsigned number
		Cout[2] = (A == B) ? 1 : 0;
		Cout[1] = (A > B) ? 1 : 0;
		Cout[0] = ({1'b0, A} > {1'b0, B}) ? 1 : 0;
    end
	
endmodule
