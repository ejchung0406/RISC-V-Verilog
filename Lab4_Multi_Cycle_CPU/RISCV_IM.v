`timescale 1ns / 100ps

module IMMED(
	input wire [31:0] INST,
	input wire [2:0] Immsrc,
	output reg signed [31:0] immed
	);

	always @(*) begin
		case (Immsrc)
			3'b000: immed = {{20{INST[31]}}, INST[31:20]}; // I-type, Load, JALR
			3'b001: immed = {{20{INST[31]}}, INST[31:25], INST[11:7]}; // Store
			3'b010:	immed = {{19{INST[31]}}, INST[31], INST[7], INST[30:25], INST[11:8], 1'b0}; // Branch
			3'b011:	immed = {{12{INST[31]}}, INST[31], INST[19:12], INST[20], INST[30:21], 1'b0}; // JAL
			3'b100:	immed = {INST[31:12], {12{1'b0}}}; // LUI, AUIPC
			default: immed = {{20{INST[31]}}, INST[31:20]}; // Default.. 
		endcase
	end 
endmodule