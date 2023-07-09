`timescale 1ns/10ps
module SP_DRAM_nocache #(parameter ROMDATA = "", AWIDTH = 12, SIZE = 4096, DWIDTH = 32, LATENCY = 8) (
	input	wire			CLK,
	input	wire			CSN,//chip select negative??
	input	wire	[AWIDTH-1:0]	ADDR,
	input	wire			WEN,//write enable negative??
	//input	wire	[3:0]		BE,//byte enable, removed for Cache lab
	input	wire	[DWIDTH-1:0]		DI, //data in
	output	wire	[DWIDTH-1:0]		DOUT // data out
);

	reg		[DWIDTH-1:0]		outline;
	reg		[DWIDTH-1:0]		ram[0 : SIZE-1];
	reg		[DWIDTH-1:0]		temp;

	// New features for Cache lab
	reg   [3:0]     latency_counter;
	reg							reg_WEN;
	reg		[AWIDTH-1:0]	reg_ADDR;
	reg 	[DWIDTH-1:0]		reg_DI;

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
				if (~reg_WEN) begin
					ram[reg_ADDR] = reg_DI;
					// $display("write %d, %d, %d", reg_ADDR, ram[reg_ADDR], outline);
				end
				else begin
					outline = ram[reg_ADDR];
					// $display("read %d, %d, %d", reg_ADDR, ram[reg_ADDR], outline);
				end
	end

endmodule
