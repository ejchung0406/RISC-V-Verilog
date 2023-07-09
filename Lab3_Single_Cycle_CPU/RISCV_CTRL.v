module CTRL (
    input wire [31:0] INST,
    input wire [2:0] bCond,

	output reg RegWE,
    output reg [3:0] ALUOP,
    output reg ALUsrcA,
    output reg ALUsrcB, 
    output reg [2:0] Immsrc,
    output reg MemWE,
    output reg MemLD,
    output reg PCsrc, 
    output reg isBranch,
    output reg [3:0] byteEnable
    );

    reg [6:0] OPCODE;
    reg [2:0] whatBranch;

	initial begin
        byteEnable = 0;
    end

    always @(*) begin
        OPCODE = INST[6:0];
        case (OPCODE)
            // r-type
			7'b0110011: begin
                RegWE = 1;
                ALUOP = {1'b0, INST[14:12]};
                if (INST[14:12] == 3'b000 || INST[14:12] == 3'b101)
                    ALUOP[3] = INST[30];
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 3'b000; // x
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;
            end

            // i-type
            7'b0010011: begin
                RegWE = 1;
                ALUOP = {1'b0, INST[14:12]};
                if (INST[14:12] == 3'b101)
                    ALUOP[3] = INST[30];
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;
            end

            // custom
			7'b0001011: begin
                RegWE = 1;
                ALUOP = {INST[14:12], INST[25]};
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 0; // x
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;
            end

            // store
            7'b0100011: begin
                RegWE = 0; 
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b001;
                MemWE = 1;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;

                case (INST[13:12])
                    2'b00: byteEnable = 4'b0001;
                    2'b01: byteEnable = 4'b0011;
                    2'b10: byteEnable = 4'b1111;
                    default: byteEnable = 4'b0000;
                endcase
            end

            // load
            7'b0000011: begin
                RegWE = 1; 
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 1;
                PCsrc = 1;
                isBranch = 0;

                case (INST[13:12])
                    2'b00: byteEnable = 4'b0001;
                    2'b01: byteEnable = 4'b0011;
                    2'b10: byteEnable = 4'b1111;
                    default: byteEnable = 4'b0000;
                endcase
            end

            // JALR
            7'b1100111: begin
                RegWE = 1; 
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 0;
                isBranch = 0;
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
                whatBranch = INST[14:12];
                case (whatBranch)
                    3'b000: isBranch = (bCond[2] == 1'b1);
                    3'b001: isBranch = (bCond[2] == 1'b0);
                    3'b100: isBranch = (bCond[1] == 1'b0 & bCond[2] == 1'b0);
                    3'b101: isBranch = (bCond[1] == 1'b1 | bCond[2] == 1'b1);
                    3'b110: isBranch = (bCond[0] == 1'b0 & bCond[2] == 1'b0);
                    3'b111: isBranch = (bCond[0] == 1'b1 | bCond[2] == 1'b1);
                    default: isBranch = 0;
                endcase
            end

            // JAL
            7'b1101111: begin
                RegWE = 1; 
                ALUOP = 4'b0000;
                ALUsrcA = 0;
                ALUsrcB = 0;
                Immsrc = 3'b011;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 0;
                isBranch = 0;
            end

            // LUI
            7'b0110111: begin
                RegWE = 1; 
                ALUOP = 4'b1001;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b100;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;
            end

            // AUIPC
            7'b0010111: begin
                RegWE = 1; 
                ALUOP = 4'b0000;
                ALUsrcA = 0;
                ALUsrcB = 0;
                Immsrc = 3'b100;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                isBranch = 0;
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
                isBranch = 0;
			end
		endcase
    end
	
endmodule
