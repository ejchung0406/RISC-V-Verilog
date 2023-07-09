module BRANCH_PREDICTOR( // Always non-taken predictor
    input wire [11:0] PCfromALU, // non taken 했는데 틀리면 여기서 가져옴 
    input wire [11:0] PCplusFour,
	input wire wrong,

    output reg taken,
	output reg [11:0] PC_next
	);

	always @(*) begin
		if(wrong) begin
            PC_next = PCfromALU;
            taken = 1'b1;
        end
        else begin
            PC_next = PCplusFour;
            taken = 1'b0;
        end
	end 
endmodule

module BRANCH_PREDICTOR_new #(parameter N = 8, SIZE = 256) ( // BTB predictor
    input wire [11:0] PCfromALU, // non taken 했는데 틀리면 여기서 가져옴 
    input wire [11:0] PCold, 
    input wire [11:0] PCplusFour,
    input wire [11:0] PColdplusFour, // taken 예측했는데 틀리면 여기서 가져옴
    input wire [11:0] PC,
    input wire taken_pw_pw, // 2 사이클 전에 어떻게 예측했는지  
	input wire wrong,
    input wire [6:0] OPCODE,
    input wire CLK,

    output reg taken,
	output reg [11:0] PC_next
	);

    reg [9-N:0] TAG[0:SIZE-1];
    reg [1:0] BHT[0:SIZE-1];
    reg [11:0] BTB[0:SIZE-1];

    always @(negedge CLK) begin
        if (OPCODE == 7'b1100011 || OPCODE == 7'b1101111 || OPCODE == 7'b1100111) begin
            if (BHT[PC[N+1:2]] === 2'bxx) begin
                TAG[PC[N+1:2]] <= PC[11:N+2];
                BHT[PC[N+1:2]] <= 2'b10;
            end
            PC_next <= (TAG[PC[N+1:2]] == PC[11:N+2] && BTB[PC[N+1:2]] !== 12'bx && BHT[PC[N+1:2]][1] == 1) ? BTB[PC[N+1:2]] : PCplusFour;
            taken <= (TAG[PC[N+1:2]] == PC[11:N+2] && BTB[PC[N+1:2]] !== 12'bx) ? BHT[PC[N+1:2]][1] : 0;
        end
        else begin
            PC_next <= PCplusFour;
            taken <= 1'b0;
        end
    end

	always @(*) begin
		if (wrong && !CLK) begin
            //update BTB entry
            if (TAG[PCold[N+1:2]] == PCold[11:N+2]) begin
                BHT[PCold[N+1:2]] = (taken_pw_pw) ? ((BHT[PCold[N+1:2]] == 0) ? 0 : BHT[PCold[N+1:2]] - 1) : ((BHT[PCold[N+1:2]] == 3) ? 3 : BHT[PCold[N+1:2]] + 1);
                if (BTB[PCold[N+1:2]] === 12'bx) BTB[PCold[N+1:2]] = PCfromALU;
            end
            PC_next = (taken_pw_pw) ? PColdplusFour : PCfromALU;
            taken = !taken_pw_pw;
        end
	end 
endmodule

