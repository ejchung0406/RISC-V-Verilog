`include "RISCV_CTRL.v"
`include "RISCV_ALU.v"
`include "RISCV_BCOND.v"

module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,                   // if set, terminate program

	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

	assign OUTPUT_PORT = RF_WD;

	initial begin
		NUM_INST <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

	// TODO: implement
	reg [11:0] PC = 0;
	reg [31:0] oldInst = 0;

	wire [11:0] PCplusFour;
	wire [19:0] PC_unused;
	reg [11:0] PC_next;

	wire [3:0] ALUOP;
	wire [31:0] ALUout;
	wire ALUsrcA;
	wire ALUsrcB;
	wire [2:0] Immsrc;
	wire MemWE;
	wire MemLD;

	reg signed [31:0] regWriteData = 0;

	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_WA1 = I_MEM_DI[11:7]; 
	assign RF_WD = regWriteData;
	
	assign D_MEM_WEN = ~MemWE;

	reg signed [31:0] ALUoperandA = 0;
	reg signed [31:0] ALUoperandB = 0;
	reg signed [31:0] immed = 0;
	wire [3:0] byteEnable;
	reg haltReg = 0;

	assign D_MEM_BE = byteEnable;
	assign D_MEM_DOUT = RF_RD2;
	assign D_MEM_ADDR = ALUout;
	assign HALT = haltReg;

	wire [2:0] bCond;
	wire [2:0] whatBranch;

	ALU pcPlusFour (
		.A(4),
		.B({{20{1'b0}}, PC}),
		.OP(4'b0000),
		.C({PC_unused, PCplusFour})
	);

	ALU alu (
		.A(ALUoperandA),
		.B(ALUoperandB),
		.OP(ALUOP),
		.C(ALUout)
	);

	BCOND bcond (
		.A(RF_RD1),
		.B(RF_RD2),
		.Cout(bCond)
	);

	CTRL control (
		.INST(I_MEM_DI),
		.bCond(bCond),
		.RegWE(RF_WE),
		.ALUOP(ALUOP),
		.ALUsrcA(ALUsrcA),
		.ALUsrcB(ALUsrcB),
		.Immsrc(Immsrc),
		.MemWE(MemWE),
		.MemLD(MemLD),
		.PCsrc(PCsrc),
		.isBranch(isBranch),
		.byteEnable(byteEnable)
	);

	always @ (posedge CLK) begin
		if (RSTn)
			PC <= PC_next;
			oldInst <= I_MEM_DI;
	end

	always @(*) begin
		if (oldInst == 32'h00c00093 && I_MEM_DI == 32'h00008067)
			haltReg = 1'b1;

		PC_next = (isBranch | !PCsrc) ? {ALUout[31:1], 1'b0} : PCplusFour;

		I_MEM_ADDR = PC;

		case (Immsrc) 
			3'b000: immed = {{20{I_MEM_DI[31]}}, I_MEM_DI[31:20]}; // I-type, Load, JALR
			3'b001: immed = {{20{I_MEM_DI[31]}}, I_MEM_DI[31:25], I_MEM_DI[11:7]}; // Store
			3'b010:	immed = {{19{I_MEM_DI[31]}}, I_MEM_DI[31], I_MEM_DI[7], I_MEM_DI[30:25], I_MEM_DI[11:8], 1'b0}; // Branch
			3'b011:	immed = {{12{I_MEM_DI[31]}}, I_MEM_DI[31], I_MEM_DI[19:12], I_MEM_DI[20], I_MEM_DI[30:21], 1'b0}; // JAL
			3'b100:	immed = {I_MEM_DI[31:12], {12{1'b0}}}; // LUI, AUIPC
			default: immed = {{20{I_MEM_DI[31]}}, I_MEM_DI[31:20]}; // Default.. 
		endcase

		ALUoperandA = (ALUsrcA) ? RF_RD1 : PC;
		ALUoperandB = (ALUsrcB) ? RF_RD2 : immed;

		if (MemLD) begin
			case (I_MEM_DI[14:12])
				3'b000: regWriteData = {{24{D_MEM_DI[7]}}, D_MEM_DI[7:0]}; // LB
				3'b001: regWriteData = {{16{D_MEM_DI[15]}}, D_MEM_DI[15:0]}; // LH
				3'b010: regWriteData = D_MEM_DI; // LW
				3'b100: regWriteData = {{24{1'b0}}, D_MEM_DI[7:0]}; // LBU
				3'b101: regWriteData = {{16{1'b0}}, D_MEM_DI[15:0]}; // LHU
				default: regWriteData = D_MEM_DI;
			endcase
		end
		else if (!PCsrc) // when JAL or JALR
			regWriteData = PCplusFour;
		else if (I_MEM_DI[6:0] == 7'b1100011)
			regWriteData = (isBranch) ? 1 : 0;  // 1 if branch taken, 0 if branch not taken (pc=pc+4)
		else
			regWriteData = ALUout;
	end
	
endmodule
