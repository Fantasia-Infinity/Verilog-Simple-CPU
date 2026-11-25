module Output_Register (
    input clk,
    input reset,
    input [7:0] acc_value,         // Value from the Accumulator
    input [4:0] output_index,      // Index in the Output Register (32 slots)
    input       write_enable,      // Store acc_value into memory[output_index]
    input       read_enable,       // Drive the selected slot onto output_value
    output [7:0] output_value      // Output to the outside world
);
    reg [7:0] memory [31:0];
    reg [7:0] held_value;          // Holds the last value read out
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            memory[i] = 8'b0;
    end

    always @(posedge clk) begin
        if (write_enable)
            memory[output_index] <= acc_value;
    end

    // Capture the read value so it stays valid after the one-cycle READ pulse
    // instead of relying on an inferred latch.
    always @(posedge clk or posedge reset) begin
        if (reset)
            held_value <= 8'b0;
        else if (read_enable)
            held_value <= memory[output_index];
    end

    // During the READ cycle the value appears immediately; afterwards the
    // registered copy keeps driving the pins.
    assign output_value = read_enable ? memory[output_index] : held_value;
endmodule
