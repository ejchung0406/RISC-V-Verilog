`timescale 1ns/10ps
`define NUM_TEST 40
`define TESTID_SIZE 5

`include "REG_FILE.v"
`include "RISCV_CLKRST.v"
`include "RISCV_TOP.v"
`include "Mem_Model.v"
`include "D_Mem_Model.v"

module TB_RISCV_sort();
	//General Signals
	wire CLK;
	wire RSTn;
	//Memory Signals
	wire I_MEM_CSN;
	wire [31:0] I_MEM_DOUT;
	wire [11:0] I_MEM_ADDR;
	wire D_MEM_CSN;
	wire D_MEM_WEN;
	//wire [3:0] D_MEM_BE; // Cache Lab
	wire [127:0] D_MEM_DOUT; // Cache Lab
	wire [127:0] D_MEM_DI; // Cache Lab
	wire [9:0] D_MEM_ADDR; // Cache Lab
	wire RF_WE;
	wire [4:0] RF_RA1;
	wire [4:0] RF_RA2;
	wire [4:0] RF_WA;
	wire [31:0] RF_RD1;
	wire [31:0] RF_RD2;
	wire [31:0] RF_WD;
	wire HALT;
	wire [31:0] NUM_INST;
	wire [31:0] OUTPUT_PORT;

	//Clock Reset Generator
	RISCV_CLKRST riscv_clkrst1 (
		.CLK           (CLK),
		.RSTn          (RSTn)
	);

	//CPU Core top
	RISCV_TOP riscv_top1 (
		//General Signals
		.CLK          (CLK),
		.RSTn         (RSTn),
		//I-Memory Signals
		.I_MEM_CSN    (I_MEM_CSN),
		.I_MEM_DI     (I_MEM_DOUT),
		.I_MEM_ADDR   (I_MEM_ADDR),
		//D-Memory Signals
		.D_MEM_CSN    (D_MEM_CSN),
		.D_MEM_DI     (D_MEM_DOUT),
		.D_MEM_DOUT   (D_MEM_DI),
		.D_MEM_ADDR   (D_MEM_ADDR),
		.D_MEM_WEN    (D_MEM_WEN),
		//.D_MEM_BE     (D_MEM_BE), // Cache Lab
		//RegFile Signals
		.RF_WE        (RF_WE),
		.RF_RA1       (RF_RA1),
		.RF_RA2       (RF_RA2),
		.RF_WA1       (RF_WA),
		.RF_RD1       (RF_RD1),
		.RF_RD2       (RF_RD2),
		.RF_WD       (RF_WD),
		.HALT		(HALT),
		.NUM_INST (NUM_INST),
		.OUTPUT_PORT (OUTPUT_PORT)
	);

	//I-Memory
	SP_SRAM #(
		.ROMDATA ("C:\\ee312\\Lab6\\template\\sort.hex"), //Initialize I-Memory
		.AWIDTH  (10),
		.SIZE    (1024)
	) i_mem1 (
		.CLK    (CLK),
		.CSN    (I_MEM_CSN),
		.DI		(32'bz),
		.DOUT   (I_MEM_DOUT),
		.ADDR   (I_MEM_ADDR[11:2]),
		.WEN    (1'b1),
		.BE     (4'b0000)
	);

	//D-Memory
	SP_DRAM #(
		.AWIDTH  (10),
		.SIZE    (1024)
	) d_mem1 (
		.CLK    (CLK),
		.CSN    (D_MEM_CSN),
		.DI     (D_MEM_DI),
		.DOUT   (D_MEM_DOUT),
		.ADDR   (D_MEM_ADDR),
		.WEN    (D_MEM_WEN)
		//.BE     (D_MEM_BE) // Cache Lab
	);

	//Reg File
	REG_FILE #(
		.DWIDTH (32),
		.MDEPTH (32),
		.AWIDTH (5)
	) reg_file1 (
		.RSTn	(RSTn),
		.CLK    (CLK),
		.WE     (RF_WE),
		.RA1    (RF_RA1),
		.RA2    (RF_RA2),
		.WA     (RF_WA),
		.RD1    (RF_RD1),
		.RD2    (RF_RD2),
		.WD     (RF_WD)
	);

	reg [31:0] cycle;
	reg verify;

	initial begin
		cycle <= 0;
		#10000000 $finish();
	end

	reg [`TESTID_SIZE*8-1:0] TestID[`NUM_TEST-1:0];
	reg [31:0] TestNumInst [`NUM_TEST-1:0];
	reg [31:0] TestAns[`NUM_TEST-1:0];
	reg TestPassed[`NUM_TEST-1:0];
	reg [31:0] i;

	initial begin
		TestID[0] <= "1";		TestNumInst[0] <= 16'h0004;		TestAns[0] <= 16'h0f00;		TestPassed[0] <= 1'b0; //ADDI
		TestID[1] <= "2";		TestNumInst[1] <= 16'h0006;		TestAns[1] <= 16'h0018;		TestPassed[1] <= 1'b0; //JAL
		TestID[2] <= "3";		TestNumInst[2] <= 16'h0008;		TestAns[2] <= 16'h001d;		TestPassed[2] <= 1'b0; //ADDI
		TestID[3] <= "4";		TestNumInst[3] <= 16'h000a;		TestAns[3] <= 16'h001e;		TestPassed[3] <= 1'b0; //ADDI
		TestID[4] <= "5";		TestNumInst[4] <= 16'h000c;		TestAns[4] <= 16'h001e;		TestPassed[4] <= 1'b0; //SUB
		TestID[5] <= "6";		TestNumInst[5] <= 16'h000e;		TestAns[5] <= 16'h0000;		TestPassed[5] <= 1'b0; //SLLI
		TestID[6] <= "7";		TestNumInst[6] <= 16'h0010;		TestAns[6] <= 16'h0ef0;		TestPassed[6] <= 1'b0; //ADD
		TestID[7] <= "8";		TestNumInst[7] <= 16'h0012;		TestAns[7] <= 16'h0000;		TestPassed[7] <= 1'b0; //LW
		TestID[8] <= "9";		TestNumInst[8] <= 16'h0014;		TestAns[8] <= 16'h0eec;		TestPassed[8] <= 1'b0; //SW
		TestID[9] <= "10";		TestNumInst[9] <= 16'h0016;		TestAns[9] <= 16'h001d;		TestPassed[9] <= 1'b0; //ADDI

		TestID[10] <= "11";		TestNumInst[10] <= 16'h0021;	TestAns[10] <= 16'h0002;	TestPassed[10] <= 1'b0; //ADDI
		TestID[11] <= "12";		TestNumInst[11] <= 16'h002b;	TestAns[11] <= 16'h0ef0;	TestPassed[11] <= 1'b0; //ADDI
		TestID[12] <= "13";		TestNumInst[12] <= 16'h0031;	TestAns[12] <= 16'h0003;	TestPassed[12] <= 1'b0; //LW
		TestID[13] <= "14";		TestNumInst[13] <= 16'h0034;	TestAns[13] <= 16'h001e;	TestPassed[13] <= 1'b0; //ADDI
		TestID[14] <= "15";		TestNumInst[14] <= 16'h003c;	TestAns[14] <= 16'h0003;	TestPassed[14] <= 1'b0; //LW
		TestID[15] <= "16";		TestNumInst[15] <= 16'h0042;	TestAns[15] <= 16'h001e;	TestPassed[15] <= 1'b0; //ADDI
		TestID[16] <= "17";		TestNumInst[16] <= 16'h0046;	TestAns[16] <= 16'h0010;	TestPassed[16] <= 1'b0; //SLLI
		TestID[17] <= "18";		TestNumInst[17] <= 16'h0100;	TestAns[17] <= 16'h0011;	TestPassed[17] <= 1'b0; //LW
		TestID[18] <= "19";		TestNumInst[18] <= 16'h0200;	TestAns[18] <= 16'h0e74;	TestPassed[18] <= 1'b0; //LW
		TestID[19] <= "20";		TestNumInst[19] <= 16'h0310;	TestAns[19] <= 16'h0ebc;	TestPassed[19] <= 1'b0; //ADD

		TestID[20] <= "21";		TestNumInst[20] <= 16'h0420;	TestAns[20] <= 16'h0e54;	TestPassed[20] <= 1'b0; //SW
		TestID[21] <= "22";		TestNumInst[21] <= 16'h0520;	TestAns[21] <= 16'h0010;	TestPassed[21] <= 1'b0; //LW
		TestID[22] <= "23";		TestNumInst[22] <= 16'h0620;	TestAns[22] <= 16'h001e;	TestPassed[22] <= 1'b0; //LW
		TestID[23] <= "24";		TestNumInst[23] <= 16'h0740;	TestAns[23] <= 16'h003c;	TestPassed[23] <= 1'b0; //SLLI
		TestID[24] <= "25";		TestNumInst[24] <= 16'h0810;	TestAns[24] <= 16'h001a;	TestPassed[24] <= 1'b0; //LW
		TestID[25] <= "26";		TestNumInst[25] <= 16'h0880;	TestAns[25] <= 16'h0e84;	TestPassed[25] <= 1'b0; //ADD
		TestID[26] <= "27";		TestNumInst[26] <= 16'h0900;	TestAns[26] <= 16'h001e;	TestPassed[26] <= 1'b0; //LW
		TestID[27] <= "28";		TestNumInst[27] <= 16'h0a20;	TestAns[27] <= 16'h0068;	TestPassed[27] <= 1'b0; //SLLI
		TestID[28] <= "29";		TestNumInst[28] <= 16'h0b20;	TestAns[28] <= 16'h001e;	TestPassed[28] <= 1'b0; //LW
		TestID[29] <= "30";		TestNumInst[29] <= 16'h0b90;	TestAns[29] <= 16'h0e54;	TestPassed[29] <= 1'b0; //SW

		TestID[30] <= "31";		TestNumInst[30] <= 16'h0c20;	TestAns[30] <= 16'h001c;	TestPassed[30] <= 1'b0; //LW
		TestID[31] <= "32";		TestNumInst[31] <= 16'h0c34;	TestAns[31] <= 16'h001d;	TestPassed[31] <= 1'b0; //ADDI
		TestID[32] <= "33";		TestNumInst[32] <= 16'h0d00;	TestAns[32] <= 16'h0e5c;	TestPassed[32] <= 1'b0; //SW
		TestID[33] <= "34";		TestNumInst[33] <= 16'h0d88;	TestAns[33] <= 16'h0e54;	TestPassed[33] <= 1'b0; //SW
		TestID[34] <= "35";		TestNumInst[34] <= 16'h0e00;	TestAns[34] <= 16'h006c;	TestPassed[34] <= 1'b0; //SLLI
		TestID[35] <= "36";		TestNumInst[35] <= 16'h0eec;	TestAns[35] <= 16'h0e74;	TestPassed[35] <= 1'b0; //LW
		TestID[36] <= "37";		TestNumInst[36] <= 16'h0fff;	TestAns[36] <= 16'h0018;	TestPassed[36] <= 1'b0; //LW
		TestID[37] <= "38";		TestNumInst[37] <= 16'h1120;	TestAns[37] <= 16'h0009;	TestPassed[37] <= 1'b0; //LW
		TestID[38] <= "39";		TestNumInst[38] <= 16'h1210;	TestAns[38] <= 16'h001e;	TestPassed[38] <= 1'b0; //LW
		TestID[39] <= "40";		TestNumInst[39] <= 16'h1340;	TestAns[39] <= 16'h0001;	TestPassed[39] <= 1'b0; //BGE
	end

	always @ (posedge CLK) begin
		if (RSTn) begin
			cycle <= cycle + 1;

			for(i=0; i<`NUM_TEST; i=i+1) begin
				if ((NUM_INST==TestNumInst[i]) & (TestPassed[i]==0)) begin
					if (OUTPUT_PORT == TestAns[i]) begin
						TestPassed[i] <= 1'b1;
						$display("Test #%s has been passed", TestID[i]);
					end
					else begin
						TestPassed[i] <= 1'b0;
						$display("Test #%s has been failed!", TestID[i]);
						$display("output_port = 0x%0x (Ans : 0x%0x)", OUTPUT_PORT, TestAns[i]);
						$finish();
					end
				end
			end

			if (HALT == 1) begin
				$display("Finish: %d cycle", cycle);
				$display("Success.");
				$finish();
			end
		end
	end

endmodule
