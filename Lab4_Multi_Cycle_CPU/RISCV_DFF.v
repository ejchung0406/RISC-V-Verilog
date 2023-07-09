`timescale 1ns / 100ps

module DFF_12(
	input wire [11:0] D,
	input wire CLK,
	output reg [11:0] Q=0
	);

	always @(posedge CLK) begin
		Q <= D; 
	end 
endmodule

module DFF(
	input wire [31:0] D,
	input wire CLK,
	output reg [31:0] Q=0
	);

	always @(posedge CLK) begin
		Q <= D; 
	end 
endmodule
