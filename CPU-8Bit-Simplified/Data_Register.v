module Data_Register (
    input clk,
    input load,                      // Unified load signal
    input is_instruction,            // Selector signal to differentiate between instruction and data
    input [3:0] load_address,        // Address to load data (4 bits)
    input [7:0] cpu_input,           // Unified input for loading both instruction and data
    input [3:0] address,             // Address to fetch operand
    output reg [7:0] data            // Operand data
);
    reg [7:0] memory [15:0];  // 16 locations of 8-bit memory
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            memory[i] = 8'b0;
    end

    always @(posedge clk) begin
        if (load && !is_instruction) begin
            // Load data into the specified address
            memory[load_address] <= cpu_input;
        end
    end

    always @(*) begin
        // Fetch the data from the data memory
        data = memory[address];
    end
endmodule
