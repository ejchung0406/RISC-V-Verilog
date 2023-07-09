module CACHE (
	input wire [9:0] ADDR,
	input wire [1:0] BO, // block offset
	input wire [31:0] DI,
	input wire [127:0] Dread,
	input wire RSTn,
	input wire MemLD,
	input wire MemWE,
	input wire CLK,
	input wire isInst,

	output reg [127:0] Dwrite,
	output reg [31:0] Dout,
	output reg memstall,
	output reg RW,
	output reg DWE,

	output reg [31:0] read_hit,
	output reg [31:0] read_miss,
	output reg [31:0] write_hit,
	output reg [31:0] write_miss
	);

	reg [6:0] tag;
	reg [2:0] idx;

	reg [6:0] tagbank[0:7];
	reg valid[0:7];
	reg [127:0] databank[0:7];

	reg hit;
	reg [127:0] temp;

	reg [31:0] state;
	reg [31:0] state_next;

	

	initial begin
		state = 0;
		state_next = 0;
		read_hit = 0;
		read_miss = 0;
		write_hit = 0;
		write_miss = 0;
	end

	always @(*) begin
		tag = ADDR[9:3];
		idx = ADDR[2:0];

		hit = (valid[idx] === 1) ? ((tag === tagbank[idx])? 1 : 0) : 0;

		case (state)
			0: begin
				if ((MemLD || MemWE) == 0) begin // not load nor store 
					state_next = 0;
					memstall = 0;
				end
				else begin // load or store inst
					if ((MemLD && isInst) && !MemWE && hit) begin // read hit
						case (BO)
							2'b00: Dout = databank[idx][31:0];
							2'b01: Dout = databank[idx][63:32];
							2'b10: Dout = databank[idx][95:64];
							2'b11: Dout = databank[idx][127:96];
						endcase
						state_next = 0;
						RW = 1;
						memstall = 0;
						read_hit = read_hit + 1;
					end
					else if ((MemLD && isInst) && !MemWE && !hit) begin // read miss
						state_next = 11;
						RW = 0;
						DWE = 0;
						memstall = 1;
						read_miss = read_miss + 1;
					end
					else if (!MemLD && MemWE && hit) begin // write hit
						temp = databank[idx];
						case (BO)
							2'b00: temp[31:0] = DI;
							2'b01: temp[63:32] = DI;
							2'b10: temp[95:64] = DI;
							2'b11: temp[127:96] = DI;
						endcase
						databank[idx] = temp;
						Dwrite = temp;
						state_next = 21;
						RW = 0;
						DWE = 1;
						memstall = 1;
						write_hit = write_hit + 1;
					end	
					else if (!MemLD && MemWE && !hit) begin // write miss
						state_next = 31;
						RW = 0;
						DWE = 0;
						memstall = 1;
						write_miss = write_miss + 1;
					end
				end
			end

			11: begin
				RW = 1; state_next = 12;
			end
			12: state_next = 13;
			13: state_next = 14;
			14: state_next = 15;
			15: state_next = 16;
			16: state_next = 17;
			17: state_next = 18;
			18: state_next = 19;
			19: begin // update cache
				state_next = 0;
				memstall = 0;
				tagbank[idx] = tag;
				databank[idx] = Dread;
				valid[idx] = 1'b1;
				case (BO)
					2'b00: Dout = Dread[31:0];
					2'b01: Dout = Dread[63:32];
					2'b10: Dout = Dread[95:64];
					2'b11: Dout = Dread[127:96];
				endcase
			end

			21: begin
				RW = 1; state_next = 22;
			end
			22: state_next = 23;
			23: state_next = 24;
			24: state_next = 25;
			25: state_next = 26;
			26: state_next = 27;
			27: state_next = 28;
			28: begin
				state_next = 0;
				memstall = 0;
			end

			31: begin
				RW = 1; state_next = 32;
			end
			32: state_next = 33;
			33: state_next = 34;
			34: state_next = 35;
			35: state_next = 36;
			36: state_next = 37;
			37: state_next = 38;
			38: state_next = 40;
			
			40: begin
				RW = 0;
				DWE = 1;
				temp = Dread;
				case (BO)
					2'b00: temp[31:0] = DI;
					2'b01: temp[63:32] = DI;
					2'b10: temp[95:64] = DI;
					2'b11: temp[127:96] = DI;
				endcase
				databank[idx] = temp;
				tagbank[idx] = tag;
				valid[idx] = 1'b1;
				Dwrite = temp;
				state_next = 21;
			end
		endcase
	end

	always @(posedge CLK) begin
		if (RSTn) state <= state_next;
	end 


endmodule
