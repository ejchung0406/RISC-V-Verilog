module CTRL (
    input wire [31:0] INST,
    input wire CLK,
    input wire RSTn,
    input wire wrong,

	output reg RegWE,
    output reg [3:0] ALUOP,
    output reg ALUsrcA,
    output reg ALUsrcB, 
    output reg [2:0] Immsrc,
    output reg MemWE,
    output reg MemLD,
    output reg PCsrc
    );

    reg state, state_next; // normal: 0, wrong: 1

	initial begin
        state = 1'b0;
        state_next = 1'b0;
    end

    always @(posedge CLK) begin
        if(RSTn) state <= state_next;
    end

    always @(*) begin
        if (RSTn && wrong && !state) state_next = 1'b1;
        if (state) state_next = 1'b0;
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
                RegWE = (state) ? 0 : 1;
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

                RegWE = (state) ? 0 : 1;
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

                RegWE = (state) ? 0 : 1;
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

                MemWE = (state) ? 0 : 1;
            end

            // load
            7'b0000011: begin
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 0;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 1;
                PCsrc = 1;

                RegWE = (state) ? 0 : 1;
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

                RegWE = (state) ? 0 : 1;
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

                RegWE = (state) ? 0 : 1;
            end

            default: begin
                ALUOP = 4'b0000;
                ALUsrcA = 1;
                ALUsrcB = 1;
                Immsrc = 3'b000;
                MemWE = 0;
                MemLD = 0;
                PCsrc = 1;
                RegWE = 0;
            end
		endcase
    end
	
endmodule
