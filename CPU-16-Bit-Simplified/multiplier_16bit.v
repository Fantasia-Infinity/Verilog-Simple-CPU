module multiplier_16bit (
    input  [15:0] a,        // 16-bit multiplicand
    input  [15:0] b,        // 16-bit multiplier
    output [15:0] product   // low 16 bits of a * b
);
    // Behavioural multiply (truncated to 16 bits).
    //
    // The previous hand-built partial-product tree discarded each adder's
    // carry-out (a multiple of 2^16) but then added that carry bit back in at
    // bit 0, so the result was off by +0..+7 for the large majority of operand
    // pairs. Synthesis maps this to the same array multiplier anyway.
    assign product = a * b;
endmodule
