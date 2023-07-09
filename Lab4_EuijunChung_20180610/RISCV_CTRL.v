module CTRL (
    input wire [31:0] INST,
    input wire [2:0] bCond,
    input wire CLK,
    input wire RSTn,

	output reg RegWE,
    output reg [3:0] ALUOP,
    output reg ALUsrcA,
    output reg ALUsrcB, 
    output reg [2:0] Immsrc,
    output reg MemWE,
    output reg MemLD,
    output reg PCsrc,
    output reg backToIF
    );

    reg [2:0] state, state_next; // IF, ID, EX, MEM, WB = 000, 001, 010, 011, 100

	initial begin
        state_next = 3'b001;
        backToIF = 0;
    end

    always @(posedge CLK) begin
        if(RSTn) state <= state_next;
    end

    always @(*) begin
        case (INST[6:0])
            // r-type
			7'b0110011: begin
                ALUOP = {1'b0, INST[14:12]};
                if (INST[14:12] == 3'b000 || INST[14:12] == 3'b101)
                    ALUOP[3] = INST[30];
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 3'b000; // x
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;    
                        RegWE = 0;
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b100;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                    end
                endcase

            end

            // i-type
            7'b0010011: begin
                ALUOP = {1'b0, INST[14:12]};
                if (INST[14:12] == 3'b101)
                    ALUOP[3] = INST[30];
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;  
                        RegWE = 0;  
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b100;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                    end
                endcase
            end

            // custom
			7'b0001011: begin
                
                ALUOP = {INST[14:12], INST[25]};
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 0; // x
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;    
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b100;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                    end
                endcase
            end

            // store
            7'b0100011: begin
                RegWE = 0; 
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b001;
                
                MemLD = 0;
                PCsrc = 1;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        MemWE = 0;  
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        MemWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b011;
                        backToIF = 0;
                        MemWE = 0;
                    end
                    3'b011: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        MemWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        MemWE = 0;
                    end
                endcase
            end

            // load
            7'b0000011: begin
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                
                PCsrc = 1;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;  
                        RegWE = 0;  
                        MemLD = 0;
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                        MemLD = 0;
                    end
                    3'b010: begin
                        state_next = 3'b011;
                        backToIF = 0;
                        RegWE = 0;
                        MemLD = 0;
                    end
                    3'b011: begin
                        state_next = 3'b100; 
                        backToIF = 0;
                        RegWE = 0;
                        MemLD = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                        MemLD = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                        MemLD = 0;
                    end
                endcase
            end

            // JALR
            7'b1100111: begin
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 0;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;    
                        RegWE = 0;
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b100;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                    end
                endcase
            end

            // Branch
            7'b1100011: begin
                RegWE = 0; 
                ALUOP = 4'b0000;
                ALUsrcA = 0;
                ALUsrcB = 0;
                Immsrc = 3'b010;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                
                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;    
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                    end
                    3'b010: begin
                        state_next = 3'b000;
                        backToIF = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                    end
                endcase
            end

            // JAL
            7'b1101111: begin
                ALUOP = 4'b0000;
                ALUsrcA = 0;
                ALUsrcB = 0;
                Immsrc = 3'b011;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 0;

                case(state)
                    3'b000: begin
                        state_next = 3'b001;
                        backToIF = 0;  
                        RegWE = 0;  
                    end
                    3'b001: begin
                        state_next = 3'b010;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b010: begin
                        state_next = 3'b100;
                        backToIF = 0;
                        RegWE = 0;
                    end
                    3'b100: begin
                        state_next = 3'b000; 
                        backToIF = 1;
                        RegWE = 1;
                    end
                    default: begin
                        state_next = 3'b001;
                        backToIF = 0;
                        RegWE = 0;
                    end
                endcase
            end

			default: begin
				RegWE = 0;
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                state_next = 3'b001;
                backToIF = 0;
			end
		endcase
    end
	
endmodule
