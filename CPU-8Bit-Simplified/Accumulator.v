module Accumulator (
    input clk,
    input reset,
    input we,                      // write enable from the Control_Unit
    input [7:0] alu_result,        // Result from the ALU
    output reg [7:0] acc_value     // Accumulator value
);
    // Only real arithmetic/logic instructions update the accumulator. OUTPUT and
    // OUTPUT_READ must leave it alone, otherwise they act as an implicit ADD.
    always @(posedge clk or posedge reset) begin
        if (reset)
            acc_value <= 8'b0;
        else if (we)
            acc_value <= alu_result;
    end
endmodule
