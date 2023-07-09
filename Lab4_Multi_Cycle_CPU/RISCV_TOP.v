`include "RISCV_CTRL.v"
`include "RISCV_ALU.v"
`include "RISCV_BCOND.v"
`include "RISCV_DFF.v"
`include "RISCV_IM.v"

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
	output wire HALT,
	output reg [31:0] NUM_INST,
	output wire [31:0] OUTPUT_PORT
	);

	initial begin
		NUM_INST <= 0;
	end

	// TODO: implement
	reg [11:0] PC = 0;
	reg [31:0] oldInst = 0;
	reg signed [31:0] regWriteData = 0;
	reg signed [31:0] ALUoperandA = 0;
	reg signed [31:0] ALUoperandB = 0;
	reg haltReg = 0;
	reg [11:0] PC_next;
	reg backToIF;
	reg [31:0] OUTPUT_PORT_past;

	wire [11:0] PCplusFour;
	wire [19:0] PC_unused;
	wire [3:0] ALUOP;
	wire [31:0] ALUout;
	wire ALUsrcA;
	wire ALUsrcB;
	wire [2:0] Immsrc;
	wire MemWE;
	wire MemLD;
	wire [6:0] OPCODE;
	wire [2:0] WHATBRANCH;
	wire [1:0] isBranch;
	wire [2:0] bCond;
	wire [2:0] whatBranch;

	// Pipeline registers and wires : PC (12bit)
	wire [11:0] PC_next_pw;
	wire [11:0] PCplusFour_pw;
	wire [11:0] PCplusFour_pw2;
	wire [11:0] PCplusFour_pw3;
	wire [11:0] PC_pw;
	wire backToIF_pw;
	DFF_12 PC_next_pr (.D(PC_next), .CLK(!CLK & backToIF_pw), .Q(PC_next_pw));
	DFF_12 PCplusFour_pr (.D(PCplusFour), .CLK(CLK), .Q(PCplusFour_pw));
	DFF_12 PCplusFour_pr2 (.D(PCplusFour_pw), .CLK(CLK), .Q(PCplusFour_pw2));
	DFF_12 PCplusFour_pr3 (.D(PCplusFour_pw2), .CLK(CLK), .Q(PCplusFour_pw3));
	DFF_12 PC_pr (.D(PC), .CLK(CLK), .Q(PC_pw));
	// Pipeline registers and wires : The rest (32bit)
	wire [31:0] I_MEM_DI_pw;
	wire signed [31:0] ALUoperandA_pw;
	wire signed [31:0] ALUoperandB_pw;
	wire [31:0] RF_RD1_pw;
	wire [31:0] RF_RD2_pw;
	wire signed [31:0] ALUout_pw;
	wire [31:0] D_MEM_DI_pw;
	wire signed [31:0] immed;
	DFF I_MEM_DI_pr (.D(I_MEM_DI), .CLK(CLK), .Q(I_MEM_DI_pw));
	DFF ALUoperandA_pr (.D(ALUoperandA), .CLK(CLK), .Q(ALUoperandA_pw));
	DFF ALUoperandB_pr (.D(ALUoperandB), .CLK(CLK), .Q(ALUoperandB_pw));
	DFF RF_RD1_pr (.D(RF_RD1), .CLK(CLK), .Q(RF_RD1_pw));
	DFF RF_RD2_pr (.D(RF_RD2), .CLK(CLK), .Q(RF_RD2_pw));
	DFF ALUout_pr (.D(ALUout), .CLK(CLK), .Q(ALUout_pw));
	DFF D_MEM_DI_pr (.D(D_MEM_DI), .CLK(CLK), .Q(D_MEM_DI_pw));
	DFF OUTPUT_PORT_pr (.D(OUTPUT_PORT_past), .CLK(CLK), .Q(OUTPUT_PORT));

	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign RF_RA2 = I_MEM_DI_pw[24:20];
	assign RF_RA1 = I_MEM_DI_pw[19:15];
	assign RF_WA1 = I_MEM_DI_pw[11:7]; 
	assign RF_WD = regWriteData;
	assign D_MEM_WEN = ~MemWE;
	assign OPCODE = I_MEM_DI_pw[6:0];
	assign WHATBRANCH = I_MEM_DI_pw[14:12];
	assign D_MEM_BE = 4'b1111;
	assign D_MEM_DOUT = RF_RD2_pw;
	assign D_MEM_ADDR = ALUout_pw[11:0];
	assign HALT = haltReg;

	ALU pcPlusFour (
		.A(4),
		.B({{20{1'b0}}, PC}),
		.OP(4'b0000),
		.C({PC_unused, PCplusFour})
	);

	ALU alu (
		.A(ALUoperandA_pw),
		.B(ALUoperandB_pw),
		.OP(ALUOP),
		.C(ALUout)
	);

	BCOND bcond (
		.A(RF_RD1_pw),
		.B(RF_RD2_pw),
		.OPCODE(OPCODE),
		.WHATBRANCH(WHATBRANCH),
		.isBranch(isBranch)
	);

	CTRL control (
		.INST(I_MEM_DI_pw),
		.bCond(bCond),
		.CLK(CLK),
		.RSTn(RSTn),
		.RegWE(RF_WE),
		.ALUOP(ALUOP),
		.ALUsrcA(ALUsrcA),
		.ALUsrcB(ALUsrcB),
		.Immsrc(Immsrc),
		.MemWE(MemWE),
		.MemLD(MemLD),
		.PCsrc(PCsrc),
		.backToIF(backToIF_pw)
	);

	IMMED immed_produce (
		.INST(I_MEM_DI_pw),
		.Immsrc(Immsrc),
		.immed(immed)
	);

	always @ (posedge CLK) begin
		if (RSTn) begin
			PC <= PC_next_pw;
			oldInst <= I_MEM_DI_pw;
			backToIF <= backToIF_pw;
		end
	end

	always @ (negedge CLK) begin
		if (RSTn & backToIF) NUM_INST <= NUM_INST + 1; // backtoif: if stage로 돌아가는 것을 의미하는, control signal이 만든 무언가
	end

	always @(*) begin
		if (oldInst == 32'h00c00093 && I_MEM_DI_pw == 32'h00008067)
			haltReg = 1'b1;
		I_MEM_ADDR = PC;
		PC_next = (isBranch[0] | !PCsrc) ? {ALUout[11:1], 1'b0} : PCplusFour;

		ALUoperandA = (ALUsrcA) ? RF_RD1 : {{20{1'b0}}, PC_pw};
		ALUoperandB = (ALUsrcB) ? RF_RD2 : immed;

		if (MemLD)
			regWriteData = D_MEM_DI_pw;
		else if (!PCsrc) // when JAL or JALR
			regWriteData = {{20{1'b0}}, PCplusFour_pw3};
		else if (isBranch[1])
			regWriteData = (isBranch[0]) ? 1 : 0;  // 1 if branch taken, 0 if branch not taken (pc=pc+4)
		else
			regWriteData = ALUout_pw;
			
		OUTPUT_PORT_past = regWriteData;
	end
	
endmodule