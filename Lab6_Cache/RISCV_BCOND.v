`timescale 1ns / 100ps

module BCOND(
	input wire signed [31:0] A,
	input wire signed [31:0] B,
	input wire [6:0] OPCODE, //6:0
	input wire [2:0] WHATBRANCH, // 14:12
	output reg [1:0] isBranch // first bit: determined by opcode, second bit: 1 when branch taken
	);

	reg [2:0] bCond;

	initial begin
		// isBranch = 2'b0;
    end

    always @(*) begin
		// First bit: whether equal (1) or not equal (0)
		// Second bit: whether A is bigger (1) or B is bigger (0) in signed number
		// Third bit: whether A is bigger (1) or B is bigger (0) in unsigned number
		bCond[2] = (A == B) ? 1 : 0;
		bCond[1] = (A > B) ? 1 : 0;
		bCond[0] = ({1'b0, A} > {1'b0, B}) ? 1 : 0;

		if (OPCODE == 7'b1100011) begin
			case (WHATBRANCH)
				3'b000: isBranch[0] = (bCond[2] == 1'b1);
				3'b001: isBranch[0] = (bCond[2] == 1'b0);
				3'b100: isBranch[0] = (bCond[1] == 1'b0 & bCond[2] == 1'b0);
				3'b101: isBranch[0] = (bCond[1] == 1'b1 | bCond[2] == 1'b1);
				3'b110: isBranch[0] = (bCond[0] == 1'b0 & bCond[2] == 1'b0);
				3'b111: isBranch[0] = (bCond[0] == 1'b1 | bCond[2] == 1'b1);
				default: isBranch[0] = 0;
			endcase
			isBranch[1] = 1;
			// isBranch[0] = 1;
		end
		else
			isBranch = 2'b0;
    end
	
endmodule
