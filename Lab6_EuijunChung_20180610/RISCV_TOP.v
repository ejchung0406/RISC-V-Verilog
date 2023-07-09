`include "RISCV_CTRL.v"
`include "RISCV_ALU.v"
`include "RISCV_BCOND.v"
`include "RISCV_DFF.v"
`include "RISCV_IM.v"
`include "RISCV_BP.v"
`include "RISCV_FORWARD.v"
`include "RISCV_RESOLVER.v"
`include "RISCV_MUX.v"
`include "RISCV_CACHE.v"

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
	input wire [127:0] D_MEM_DI,
	output wire [127:0] D_MEM_DOUT,
	output wire [9:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	// output wire [3:0] D_MEM_BE,

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
	reg haltReg = 0;
	reg isInst_if = 0;

	wire signed [31:0] regWriteData;
	wire signed [31:0] Muxout;
	wire signed [31:0] ALUoperandA; wire signed [31:0] ALUoperandB;
	wire [11:0] PC_next; wire [11:0] PCplusFour; wire [19:0] PC_unused;
	wire [3:0] ALUOP; wire [31:0] ALUout; wire ALUsrcA; wire ALUsrcB;
	wire [2:0] Immsrc;
	wire MemWE; wire MemLD;
	wire [6:0] OPCODE;
	wire [2:0] WHATBRANCH;
	wire [1:0] isBranch;
	wire [1:0] fwdA; wire [1:0] fwdB; wire [1:0] fwdAA; wire [1:0] fwdBB;
	wire wrong; wire fwdstall; wire isInst;
	wire memstall;
	wire stall = fwdstall || memstall;

	// Pipeline registers and wires : Control signals (1bit)
	wire taken_pw; wire taken_pw_pw; 
	wire isInst_pw; wire isInst_pw_pw; wire isInst_pw3;
	wire PCsrc_pw; wire PCsrc_pw_pw;
	wire MemLD_pw; wire MemLD_pw_pw;
	wire MemWE_pw; wire MemWE_pw_pw; 
	wire RegWE_pw; wire RegWE_pw_pw; wire RegWE_pw3; 
	wire [1:0] isBranch_pw; wire [1:0] isBranch_pw_pw;
	wire [3:0] ALUOP_pw;
	wire [4:0] RF_WA1_pw; wire [4:0] RF_WA1_pw_pw; wire [4:0] RF_WA1_pw3;
	wire [11:0] PCplusFour_pw;
	wire [11:0] PCplusFour_pw_pw;
	wire [11:0] PCplusFour_pw3;
	wire [11:0] PC_pw;
	wire [11:0] PC_pw_pw;
	wire [31:0] I_MEM_DI_pw;
	wire signed [31:0] ALUoperandA_pw;
	wire signed [31:0] ALUoperandB_pw;
	wire [31:0] RF_RD1_pw;
	wire signed [31:0] RF_RD1_mux;
	wire signed [31:0] RF_RD2_mux;
	wire signed [31:0] RF_RD2_pw; 
	wire signed [31:0] RF_RD2_pw_pw;
	wire signed [31:0] ALUout_pw;
	wire signed [31:0] regWriteData_pw; wire signed [31:0] regWriteData_pw_pw;
	wire signed [31:0] immed;
	wire [31:0] oldInst_pw;
	wire [31:0] oldInst_pw_pw;
	wire [31:0] oldInst_pw3;

	// Cache wires
	wire [127:0] cache_Dwrite;
	wire [31:0] cache_Dout;
	wire cache_RW;
	wire cache_DWE;
	wire [31:0] read_hit; wire [31:0] read_miss; wire [31:0] write_hit; wire [31:0] write_miss; 
	
	DFF #(.SIZE(1)) taken_pr (.D(taken), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(taken_pw));
	DFF #(.SIZE(1)) taken_pr_pr (.D(taken_pw), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(taken_pw_pw));
	DFF #(.SIZE(1)) isInst_if_pr (.D(isInst_if), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(isInst));
	DFF #(.SIZE(1)) isInst_pr (.D(isInst), .CLK(CLK), .wrong(wrong | stall), .stall(memstall), .Q(isInst_pw));
	DFF #(.SIZE(1)) isInst_pr_pr (.D(isInst_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(isInst_pw_pw));
	DFF #(.SIZE(1)) isInst_pr3 (.D(isInst_pw_pw), .CLK(CLK), .wrong(memstall), .stall(1'b0), .Q(isInst_pw3));
	DFF_neg #(.SIZE(1)) PCsrc_pr (.D(PCsrc), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(PCsrc_pw));
	DFF #(.SIZE(1)) PCsrc_pr_pr (.D(PCsrc_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(PCsrc_pw_pw));
	DFF #(.SIZE(1)) MemLD_pr (.D(MemLD), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(MemLD_pw));
	DFF #(.SIZE(1)) MemLD_pr_pr (.D(MemLD_pw), .CLK(CLK), .wrong(wrong), .stall(memstall), .Q(MemLD_pw_pw));
	DFF #(.SIZE(1)) MemWE_pr (.D(MemWE), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(MemWE_pw));
	DFF #(.SIZE(1)) MemWE_pr_pr (.D(MemWE_pw), .CLK(CLK), .wrong(wrong), .stall(memstall), .Q(MemWE_pw_pw));
	DFF #(.SIZE(1)) RegWE_pr (.D(RegWE), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(RegWE_pw));
	DFF #(.SIZE(1)) RegWE_pr_pr (.D(RegWE_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RegWE_pw_pw));
	DFF #(.SIZE(1)) RegWE_pr3 (.D(RegWE_pw_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RegWE_pw3));

	// Pipeline registers and wires : Branch signals (2bit)
	DFF #(.SIZE(2)) isBranch_pr (.D(isBranch), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(isBranch_pw));
	DFF #(.SIZE(2)) isBranch_pr_pr (.D(isBranch_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(isBranch_pw_pw));

	// Pipeline registers and wires : ALU operations (4bit)
	DFF #(.SIZE(4)) ALUOP_pr (.D(ALUOP), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(ALUOP_pw));

	// Pipeline registers and wires : REG_destination address (5bit)
	DFF #(.SIZE(5)) RF_WA1_pr (.D(I_MEM_DI_pw[11:7]), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(RF_WA1_pw));
	DFF #(.SIZE(5)) RF_WA1_pr_pr (.D(RF_WA1_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RF_WA1_pw_pw));
	DFF #(.SIZE(5)) RF_WA1_pr3 (.D(RF_WA1_pw_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RF_WA1_pw3));

	// Pipeline registers and wires : PC (12bit)
	DFF #(.SIZE(12)) PCplusFour_pr (.D(PCplusFour), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(PCplusFour_pw));
	DFF #(.SIZE(12)) PCplusFour_pr_pr (.D(PCplusFour_pw), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(PCplusFour_pw_pw));
	DFF #(.SIZE(12)) PCplusFour_pr3 (.D(PCplusFour_pw_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(PCplusFour_pw3));
	DFF #(.SIZE(12)) PC_pr (.D(PC), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(PC_pw));
	DFF #(.SIZE(12)) PC_pr_pr (.D(PC_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(PC_pw_pw));

	// Pipeline registers and wires : The rest (32bit)
	DFF #(.SIZE(32)) I_MEM_DI_pr (.D(I_MEM_DI), .CLK(CLK), .wrong(wrong), .stall(stall), .Q(I_MEM_DI_pw));
	DFF #(.SIZE(32)) ALUoperandA_pr (.D(ALUoperandA), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(ALUoperandA_pw));
	DFF #(.SIZE(32)) ALUoperandB_pr (.D(ALUoperandB), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(ALUoperandB_pw));
	DFF #(.SIZE(32)) RF_RD1_pr (.D(RF_RD1), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RF_RD1_pw));
	DFF #(.SIZE(32)) RF_RD2_pr (.D(RF_RD2_mux), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RF_RD2_pw));
	DFF #(.SIZE(32)) RF_RD2_pr_pr (.D(RF_RD2_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(RF_RD2_pw_pw));
	DFF #(.SIZE(32)) ALUout_pr (.D(ALUout), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(ALUout_pw));
	DFF #(.SIZE(32)) regWriteData_pr (.D(regWriteData), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(regWriteData_pw));
	DFF #(.SIZE(32)) regWriteData_pr_pr (.D(regWriteData_pw), .CLK(CLK), .wrong(1'b0), .stall(1'b0), .Q(regWriteData_pw_pw));
	DFF #(.SIZE(32)) oldInst_pr (.D(I_MEM_DI_pw), .CLK(CLK), .wrong(1'b0), .stall(stall), .Q(oldInst_pw));
	DFF #(.SIZE(32)) oldInst_pr_pr (.D(oldInst_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(oldInst_pw_pw));
	DFF #(.SIZE(32)) oldInst_pr3 (.D(oldInst_pw_pw), .CLK(CLK), .wrong(1'b0), .stall(memstall), .Q(oldInst_pw3));

	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = cache_RW;
	assign RF_RA2 = I_MEM_DI_pw[24:20];
	assign RF_RA1 = I_MEM_DI_pw[19:15];
	assign RF_WA1 = RF_WA1_pw3; 
	assign RF_WD = regWriteData_pw;
	assign D_MEM_WEN = ~cache_DWE;
	assign OPCODE = I_MEM_DI_pw[6:0];
	assign WHATBRANCH = I_MEM_DI_pw[14:12];
	// assign D_MEM_BE = 4'b1111;
	assign D_MEM_DOUT = cache_Dwrite; 
	assign D_MEM_ADDR = ALUout_pw[11:2];
	assign HALT = haltReg;
	assign OUTPUT_PORT = regWriteData_pw_pw;
	assign RF_WE = RegWE_pw3;

	ALU pcPlusFour (.A(4), .B({{20{1'b0}}, PC}), .OP(4'b0000), .C({PC_unused, PCplusFour}));
	ALU alu (.A(ALUoperandA_pw), .B(ALUoperandB_pw), .OP(ALUOP_pw), .C(ALUout));
	BCOND bcond (.A(RF_RD1_mux), .B(RF_RD2_mux), .OPCODE(OPCODE), .WHATBRANCH(WHATBRANCH), .isBranch(isBranch));
	CTRL control (.INST(I_MEM_DI_pw), .CLK(CLK), .wrong(wrong), .stall(stall), .RSTn(RSTn), .RegWE(RegWE), .ALUOP(ALUOP),
		.ALUsrcA(ALUsrcA), .ALUsrcB(ALUsrcB), .Immsrc(Immsrc), .MemWE(MemWE), .MemLD(MemLD), .PCsrc(PCsrc));
	IMMED immed_produce (.INST(I_MEM_DI_pw), .Immsrc(Immsrc), .immed(immed));
	BRANCH_PREDICTOR_new branch_predictor (.PCfromALU({ALUout[11:1], 1'b0}),  // BTB BP
		.PCold(PC_pw_pw), .PCplusFour(PCplusFour), .PColdplusFour(PCplusFour_pw_pw), .PC(PC), 
		.taken_pw_pw(taken_pw_pw), .wrong(wrong), .OPCODE(I_MEM_DI[6:0]), 
		.CLK(CLK), .stall(stall), .taken(taken), .PC_next(PC_next));
	// BRANCH_PREDICTOR branch_predictor (.PCfromALU({ALUout[11:1], 1'b0}),  // Always Non-taken BP
	// 	.PCplusFour(PCplusFour), .wrong(wrong),
	// 	.taken(taken), .PC_next(PC_next));
	RESOLVER resolver (.taken_pw_pw(taken_pw_pw), .isBranch_pw(isBranch_pw), 
		.PCsrc_pw(PCsrc_pw), .CLK(CLK), .stall(stall), .wrong(wrong));
	FORWARD forward (.RF_RA1(I_MEM_DI_pw[19:15]), .RF_RA2(I_MEM_DI_pw[24:20]), 
		.ALUsrcA(ALUsrcA), .ALUsrcB(ALUsrcB), 
		.RF_WA1_pw(RF_WA1_pw), .RF_WA1_pw_pw(RF_WA1_pw_pw), .RF_WA1_pw3(RF_WA1_pw3), 
		.RegWE_pw(RegWE_pw), .RegWE_pw_pw(RegWE_pw_pw), .RegWE_pw3(RegWE_pw3), 
		.OPCODE(I_MEM_DI_pw[6:0]), .CLK(CLK), 
		.isInst_pw(isInst_pw), .isInst_pw_pw(isInst_pw_pw), .isInst_pw3(isInst_pw3), .stall(memstall),
		.fwdA(fwdA), .fwdB(fwdB), .fwdAA(fwdAA), .fwdBB(fwdBB), .fwdstall(fwdstall));
	TWO_MUX two_mux_ld (.A(Muxout), .B(cache_Dout), .ctrl(MemLD_pw_pw), .out(regWriteData));
	FOUR_MUX four_mux_a (.A((ALUsrcA) ? RF_RD1 : {{20{1'b0}}, PC_pw}), 
		.B(ALUout), .C(regWriteData), .D(regWriteData_pw), 
		.ctrl(fwdA), .out(ALUoperandA));
	FOUR_MUX four_mux_b (.A((ALUsrcB) ? RF_RD2 : immed), 
		.B(ALUout), .C(regWriteData), .D(regWriteData_pw), 
		.ctrl(fwdB), .out(ALUoperandB));
	FOUR_MUX four_mux_aa (.A(RF_RD1), .B(ALUout), .C(regWriteData), .D(regWriteData_pw), 
		.ctrl(fwdAA), .out(RF_RD1_mux));
	FOUR_MUX four_mux_bb (.A(RF_RD2), .B(ALUout), .C(regWriteData), .D(regWriteData_pw), 
		.ctrl(fwdBB), .out(RF_RD2_mux));
	FOUR_MUX four_mux_mem (.A((PCsrc_pw_pw) ? ALUout_pw : {{20{1'b0}}, PCplusFour_pw3}), 
		.B((PCsrc_pw_pw) ? ALUout_pw : {{20{1'b0}}, PCplusFour_pw3}), .C(0), .D(1), 
		.ctrl(isBranch_pw_pw), .out(Muxout));
	CACHE cache (.ADDR(ALUout_pw[11:2]), .BO(ALUout_pw[1:0]), .DI(RF_RD2_pw_pw), .Dread(D_MEM_DI),
		.RSTn(RSTn), .MemLD(MemLD_pw_pw), .MemWE(MemWE_pw_pw), .CLK(CLK), .isInst(isInst_pw_pw),
		.Dwrite(cache_Dwrite), .Dout(cache_Dout), .memstall(memstall), .RW(cache_RW), .DWE(cache_DWE),
		.read_hit(read_hit), .read_miss(read_miss), .write_hit(write_hit), .write_miss(write_miss));

	always @ (posedge CLK) begin
		if (RSTn) begin
			if (!stall) PC <= PC_next;
			if (isInst_pw3) NUM_INST <= NUM_INST + 1;
			if (oldInst_pw3 == 32'h00c00093 && oldInst_pw_pw == 32'h00008067) begin
				$display("%d, %d, %d, %d", read_hit, read_miss, write_hit, write_miss);
				haltReg <= 1'b1;
			end
		end
	end

	always @(*) begin
		I_MEM_ADDR = PC;
		isInst_if = !I_MEM_CSN && !wrong;
	end
	
endmodule