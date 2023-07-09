`timescale 1ns/10ps
module SP_DRAM #(parameter ROMDATA = "", AWIDTH = 10, SIZE = 1024, DWIDTH = 128, LATENCY = 8) (
	input	wire			CLK,
	input	wire			CSN,//chip select negative??
	input	wire	[AWIDTH-1:0]	ADDR,
	input	wire			WEN,//write enable negative??
	//input	wire	[3:0]		BE,//byte enable, removed for Cache lab
	input	wire	[127:0]		DI, //data in
	output	wire	[127:0]		DOUT // data out
);

	reg		[127:0]		outline;
	reg		[127:0]		ram[0 : SIZE-1];
	reg		[127:0]		temp;

	// New features for Cache lab
	reg   [3:0]     latency_counter;
	reg							reg_WEN;
	reg		[AWIDTH-1:0]	reg_ADDR;
	reg 	[127:0]		reg_DI;

	initial begin
		if (ROMDATA != "")
			$readmemh(ROMDATA, ram);
	end

	assign #1 DOUT = outline;

	always @ (negedge CLK) begin
		if (latency_counter) begin
			latency_counter <= latency_counter - 1;
		end
		else if (~CSN) begin
			latency_counter <= LATENCY-2;
			reg_WEN <= WEN;
			reg_ADDR <= ADDR;
			reg_DI <= DI;
		end

		// Synchronous write
		else if (~latency_counter)
				if (~reg_WEN)
					ram[reg_ADDR] = reg_DI;
				else
					outline = ram[reg_ADDR];
	end

endmodule
