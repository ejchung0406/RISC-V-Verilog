`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin,				// Sign of the coin return
	stopwatch,
	current_total,
	return_temp,
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumCoins-1:0] o_return_coin;

	output [3:0] stopwatch;
	output [`kTotalBits-1:0] current_total;
	output [`kTotalBits-1:0] return_temp;
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.

//////////////////////////////////////////////////////////////////////	/

	//we have to return many coins
	reg [`kCoinBits-1:0] returning_coin_0;
	reg [`kCoinBits-1:0] returning_coin_1;
	reg [`kCoinBits-1:0] returning_coin_2;
	reg block_item_0;
	reg block_item_1;
	//check timeout
	reg [3:0] stopwatch;
	//when return triggered
	reg have_to_return;
	reg [`kTotalBits-1:0] return_temp;
	reg [`kTotalBits-1:0] temp;
////////////////////////////////////////////////////////////////////////

	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpage to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;

	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k, l, m, n;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;

	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;

	// Variables. You may add more your own registers.


	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state. current_total_nxt =
		have_to_return = i_trigger_return + (stopwatch==0);
		temp = i_input_coin[0]*kkCoinValue[0] + i_input_coin[1]*kkCoinValue[1] + i_input_coin[2]*kkCoinValue[2]
			 - (i_select_item[0]*kkItemPrice[0] + i_select_item[1]*kkItemPrice[1]
			 + i_select_item[2]*kkItemPrice[2] + i_select_item[3]*kkItemPrice[3]);
		current_total_nxt = current_total + temp;

		returning_coin_2 = current_total / kkCoinValue[2];
		returning_coin_1 = (current_total - returning_coin_2*kkCoinValue[2]) / kkCoinValue[1];
		returning_coin_0 = (current_total - returning_coin_2*kkCoinValue[2] - returning_coin_1*kkCoinValue[1]) / kkCoinValue[0];
		
		if (returning_coin_2 > 0) begin
			block_item_1 = 1;
			block_item_0 = 1;
			if (have_to_return)
				current_total_nxt = current_total_nxt - kkCoinValue[2];
		end
		else begin
			block_item_1 = 0;
			if (returning_coin_1 > 0) begin
				block_item_0 = 1;
				if (have_to_return)
					current_total_nxt = current_total_nxt - kkCoinValue[1];
			end
			else begin
				if (returning_coin_0 > 0) begin
					block_item_0 = 0;
					if (have_to_return)
						current_total_nxt = current_total_nxt - kkCoinValue[0];
				end
				else begin
					block_item_0 = 0;
					block_item_1 = 1;
				end
			end
		end
	end

	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		if (current_total >= kkItemPrice[0]) o_available_item[0] = 1;
		else o_available_item[0] = 0;
		if (current_total >= kkItemPrice[1]) o_available_item[1] = 1;
		else o_available_item[1] = 0;
		if (current_total >= kkItemPrice[2]) o_available_item[2] = 1;
		else o_available_item[2] = 0;
		if (current_total >= kkItemPrice[3]) o_available_item[3] = 1;
		else o_available_item[3] = 0;

		// TODO: o_output_item
		case (i_select_item)
			4'b0001: o_output_item[0] = 1;
			4'b0010: o_output_item[1] = 1;
			4'b0100: o_output_item[2] = 1;
			4'b1000: o_output_item[3] = 1;
			default: o_output_item = 0;
		endcase
	end

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total <= 0;
			stopwatch <= `kWaitTime;
			have_to_return <= 0;
		end
		else begin
			// TODO: update all states.
			current_total <= current_total_nxt;
			// decrease stopwatch
			if (current_total != 0 && temp == 0) begin
				if (stopwatch > 0)
					stopwatch <= stopwatch - 1;
			end
			else
				stopwatch <= `kWaitTime;
			// if you have to return some coins then you have to turn on the bit
			if (have_to_return) begin
				case ({block_item_0, block_item_1})
					{1'b1, 1'b1}:
						o_return_coin <= 3'b100;
					{1'b1, 1'b0}:
						o_return_coin <= 3'b010;
					{1'b0, 1'b0}:
						o_return_coin <= 3'b001;
					default:
						o_return_coin <= 3'b000;
				endcase
			end
		end		   //update all state end
	end	   //always end

endmodule
