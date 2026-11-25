module Address_Register (
    input  [7:0] instruction,   // 8-bit instruction
    output reg [3:0] address    // Operand address: the low 4 bits of the instruction
);
    always @(*) begin
        address = instruction[3:0];
    end
endmodule
