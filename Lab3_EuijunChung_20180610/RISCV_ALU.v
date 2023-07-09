`timescale 1ns / 100ps

module ALU(
	input wire signed [31:0] A,
	input wire signed [31:0] B,
	input wire [3:0] OP,
	output reg [31:0] C
	);

	// Arithmetic
	`define	OP_ADD	4'b0000
	`define	OP_SUB	4'b1000
	// Bitwise Boolean operation
	`define	OP_AND	4'b0111
	`define	OP_OR 	4'b0110
	// `define	OP_NAND	4'b0100
	// `define	OP_NOR	4'b0101
	`define	OP_XOR	4'b0100
	// `define	OP_XNOR	4'b0111
	// Logic
	// `define	OP_ID	4'b1000
	// `define	OP_NOT  4'b1001
	// Shift
	`define	OP_LRS	4'b0101
	`define	OP_ARS	4'b1101
	// `define	OP_RR	4'b1100
	`define	OP_LLS	4'b0001
	// `define	OP_ALS	4'b1110
	// `define	OP_RL	4'b1111
	// Compare
	`define OP_LT 4'b0010
	`define OP_LTU 4'b0011
	// Custom
	`define OP_MUL 4'b1110
	`define OP_MOD 4'b1111
	`define OP_ISEVEN 4'b1100
	// For convenience
	`define OP_printB 4'b1001
	// 1010
	// 1011

	initial begin
    end

    always @(*) begin
        case (OP)
			`OP_ADD: begin
				C=A+B;
			end

			`OP_SUB: begin
				C=A-B;
			end

			`OP_AND: begin
				C = A&B;
			end

			`OP_OR: begin
				C = A|B;
			end

			// `OP_NAND: begin
			// 	C = ~(A&B);
			// 	Cout = 0;
			// end

			// `OP_NOR: begin
			// 	C = ~(A|B);
			// 	Cout = 0;
			// end

			`OP_XOR: begin
				C = A^B;
			end

			// `OP_XNOR: begin
			// 	C = ~(A^B);
			// 	Cout = 0;
			// end

			// `OP_ID: begin
			// 	C = A;
			// 	Cout = 0;
			// end

			// `OP_NOT: begin
			// 	C = ~A;
			// 	Cout = 0;
			// end

			`OP_LRS: begin
				C = A >> B[4:0];
			end

			`OP_ARS: begin
				C = A >>> B[4:0];
			end

			// `OP_RR: begin
			// 	C = {A[0], A[15:1]};
			// 	Cout = 0;
			// end

			`OP_LLS: begin
				C = A << B[4:0];
			end

			// `OP_ALS: begin
			// 	C = A <<< 1;
			// 	Cout = 0;
			// end

			// `OP_RL: begin
			// 	C = {A[14:0], A[15]};
			// 	Cout = 0;
			// end

			`OP_LT: begin
				C = (A < B) ? 1 : 0;
			end

			`OP_LTU: begin
				C = ({1'b0, A} < {1'b0, B}) ? 1 : 0;
			end

			`OP_MUL: begin
				C = A * B;
			end

			`OP_MOD: begin
				C = A % B;
			end

			`OP_ISEVEN: begin
				C = (A % 2 == 0) ? 1 : 0;
			end

			`OP_printB: begin
				C = B;
			end

			default: begin
				C=0;
			end
		endcase
    end
	
endmodule
