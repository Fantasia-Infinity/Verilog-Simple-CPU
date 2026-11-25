module multiplier_8bit (
    input  [7:0] a,        // 8-bit multiplicand
    input  [7:0] b,        // 8-bit multiplier
    output [7:0] product   // low 8 bits of a * b
);
    // Behavioural multiply (truncated to 8 bits).
    //
    // The previous hand-built partial-product tree discarded each adder's
    // carry-out (a multiple of 2^8) but then added that carry bit back in at
    // bit 0, so the result was wrong for ~51% of all operand pairs.
    assign product = a * b;
endmodule
