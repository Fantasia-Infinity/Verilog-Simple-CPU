module Instruction_Register (
    input clk,
    input load,                      // Unified load signal
    input is_instruction,            // Selector signal to differentiate between instruction and data
    input [4:0] load_address,        // Address to load instruction (5 bits)
    input [15:0] cpu_input,          // Unified input for loading both instruction and data
    input [4:0] program_counter,     // Current instruction address
    output reg [15:0] instruction    // 16-bit instruction (Opcode + Operand Address)
);
    reg [15:0] instructions [31:0];  // 32 instructions, each 16 bits wide
    integer i;

    // Demo program: four arithmetic operations, each followed by an OUTPUT that
    // stores the accumulator into a slot, then eight OUTPUT_READ instructions.
    // Unused slots are filled with NOP so that a program-counter wrap can never
    // execute uninitialised memory.
    initial begin
        instructions[0]  = 16'b0000_0000_0000_0000;  // ADD    data address 0
        instructions[1]  = 16'b0110_0000_0000_0000;  // OUTPUT slot 0
        instructions[2]  = 16'b0000_0001_0000_0001;  // ADD    data address 1
        instructions[3]  = 16'b0110_0001_0000_0001;  // OUTPUT slot 1
        instructions[4]  = 16'b0001_0010_0000_0010;  // SUB    data address 2
        instructions[5]  = 16'b0110_0010_0000_0010;  // OUTPUT slot 2
        instructions[6]  = 16'b0001_0011_0000_0011;  // SUB    data address 3
        instructions[7]  = 16'b0110_0011_0000_0011;  // OUTPUT slot 3
        instructions[8]  = 16'b0100_0100_0000_0100;  // MUL    data address 4
        instructions[9]  = 16'b0110_0100_0000_0100;  // OUTPUT slot 4
        instructions[10] = 16'b0100_0101_0000_0101;  // MUL    data address 5
        instructions[11] = 16'b0110_0101_0000_0101;  // OUTPUT slot 5
        instructions[12] = 16'b0101_0110_0000_0110;  // DIV    data address 6
        instructions[13] = 16'b0110_0110_0000_0110;  // OUTPUT slot 6
        instructions[14] = 16'b0101_0111_0000_0111;  // DIV    data address 7
        instructions[15] = 16'b0110_0111_0000_0111;  // OUTPUT slot 7

        // Read the eight stored results back out, one slot per instruction
        instructions[16] = 16'b0111_0000_0000_0000;  // OUTPUT_READ slot 0
        instructions[17] = 16'b0111_0001_0000_0001;  // OUTPUT_READ slot 1
        instructions[18] = 16'b0111_0010_0000_0010;  // OUTPUT_READ slot 2
        instructions[19] = 16'b0111_0011_0000_0011;  // OUTPUT_READ slot 3
        instructions[20] = 16'b0111_0100_0000_0100;  // OUTPUT_READ slot 4
        instructions[21] = 16'b0111_0101_0000_0101;  // OUTPUT_READ slot 5
        instructions[22] = 16'b0111_0110_0000_0110;  // OUTPUT_READ slot 6
        instructions[23] = 16'b0111_0111_0000_0111;  // OUTPUT_READ slot 7

        for (i = 24; i < 32; i = i + 1)
            instructions[i] = 16'b1111_0000_0000_0000;  // NOP
    end

    always @(posedge clk) begin
        if (load && is_instruction) begin
            // Load instruction into the specified address
            instructions[load_address] <= cpu_input;
        end
    end

    always @(*) begin
        // Fetch the instruction from the instruction memory
        instruction = instructions[program_counter];
    end
endmodule
