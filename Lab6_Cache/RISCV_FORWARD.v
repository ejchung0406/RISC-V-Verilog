module FORWARD(
	input wire [4:0] RF_RA1, // address of register 1
	input wire [4:0] RF_RA2, // address of register 2
	input wire ALUsrcA, // does it use register 1?
	input wire ALUsrcB, // does it use register 2?
	input wire [4:0] RF_WA1_pw, // dest register address of ex stage's instruction
	input wire [4:0] RF_WA1_pw_pw, // dest register address of mem stage's instruction
	input wire [4:0] RF_WA1_pw3, // dest register address of wb stage's instruction
	input wire RegWE_pw, // does ex stage's instruction write to dest reg?
	input wire RegWE_pw_pw, // does mem stage's instruction write to dest reg?
	input wire RegWE_pw3, // does wb stage's instruction write to dest reg?

	input wire [6:0] OPCODE,
	input wire CLK,
	input wire isInst_pw,
	input wire isInst_pw_pw,
	input wire isInst_pw3,
	input wire stall,

	output reg [1:0] fwdA,
	output reg [1:0] fwdB,
	output reg [1:0] fwdAA,
	output reg [1:0] fwdBB,
	output reg fwdstall // ld 이후 raw 면 stall
	);

	initial begin
		fwdstall = 0;
	end

	reg [6:0] OPCODE_past;

	always @(posedge CLK) begin
		OPCODE_past <= OPCODE;
		if (!stall) begin
			if(fwdstall) fwdstall <= 1'b0;
		end
	end

	always @(*) begin
		if(RegWE_pw && RF_RA1 == RF_WA1_pw && ALUsrcA && isInst_pw) fwdA = 2'b01;
		else if(RegWE_pw_pw && RF_RA1 == RF_WA1_pw_pw && ALUsrcA && isInst_pw_pw) fwdA = 2'b10;
		else if(RegWE_pw3 && RF_RA1 == RF_WA1_pw3 && ALUsrcA && isInst_pw3) fwdA = 2'b11;
		else fwdA = 2'b00;

		if(RegWE_pw && RF_RA2 == RF_WA1_pw && ALUsrcB && isInst_pw) fwdB = 2'b01;
		else if(RegWE_pw_pw && RF_RA2 == RF_WA1_pw_pw && ALUsrcB && isInst_pw_pw) fwdB = 2'b10;
		else if(RegWE_pw3 && RF_RA2 == RF_WA1_pw3 && ALUsrcB && isInst_pw3) fwdB = 2'b11;
		else fwdB = 2'b00;

		if(RegWE_pw && RF_RA1 == RF_WA1_pw && isInst_pw) fwdAA = 2'b01;
		else if(RegWE_pw_pw && RF_RA1 == RF_WA1_pw_pw && isInst_pw_pw) fwdAA = 2'b10;
		else if(RegWE_pw3 && RF_RA1 == RF_WA1_pw3 && isInst_pw3) fwdAA = 2'b11;
		else fwdAA = 2'b00;

		if(RegWE_pw && RF_RA2 == RF_WA1_pw && isInst_pw) fwdBB = 2'b01;
		else if(RegWE_pw_pw && RF_RA2 == RF_WA1_pw_pw && isInst_pw_pw) fwdBB = 2'b10;
		else if(RegWE_pw3 && RF_RA2 == RF_WA1_pw3 && isInst_pw3) fwdBB = 2'b11;
		else fwdBB = 2'b00;

		if ((fwdA == 2'b01 || fwdB == 2'b01 || fwdAA == 2'b01 || fwdBB == 2'b01) && OPCODE_past == 7'b0000011) fwdstall = 1'b1;
	end 
endmodule
