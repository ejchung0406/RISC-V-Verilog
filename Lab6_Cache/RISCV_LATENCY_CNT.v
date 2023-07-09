module LATENCY_CNT #(parameter LATENCY = 8) (
	input wire MemLD,
    input wire MemWE,
	input wire CLK,
    input wire RSTn,
    input wire isInst,

	output reg memstall = 0,
    output reg RW
	);

    reg [31:0] state;
    reg [31:0] state_next;

    initial begin
        state = 0;
        state_next = 0;
    end

    always @(posedge CLK) begin
		if (RSTn) state <= state_next;
	end 

    always @(*) begin
        case (state)
			0: begin
				if ((MemLD || MemWE) == 0) begin // not load nor store 
                    state_next = 0;
                    memstall = 0;
				end
				else begin // load or store inst
					if ((MemLD && isInst) || MemWE) begin // read or write
						state_next = 1;
						RW = 0;
						memstall = 1;
                    end
				end
			end

			1: begin
				RW = 1; state_next = 2;
			end
			2: state_next = 3;
			3: state_next = 4;
			4: state_next = 5;
			5: state_next = 6;
			6: state_next = 7;
            7: begin
                state_next = 0;
                memstall = 0;
            end
		endcase
	end 

endmodule