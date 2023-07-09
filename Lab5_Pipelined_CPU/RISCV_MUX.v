module FOUR_MUX (
    input wire signed [31:0] A,
    input wire signed [31:0] B,
    input wire signed [31:0] C,
    input wire signed [31:0] D,
    input wire [1:0] ctrl,

    output wire signed [31:0] out
    );

    assign out = ctrl[1] ? (ctrl[0] ? D : C) : (ctrl[0] ? B : A);

endmodule

module TWO_MUX (
    input wire signed [31:0] A,
    input wire signed [31:0] B,
    input wire ctrl,

    output wire signed [31:0] out
    );

    assign out = ctrl ? B : A;

endmodule