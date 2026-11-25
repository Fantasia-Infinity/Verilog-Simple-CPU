`timescale 1ns/1ps
// 16-bit CPU regression: runs the demo program hardcoded in Instruction_Register
// and checks every result, including that OUTPUT/OUTPUT_READ no longer disturb
// the accumulator and that the NOP padding prevents X after a PC wrap.
//
// Stimulus is driven on the NEGEDGE so it never races the DUT's posedge sampling.
module tb_cpu16;
    reg clk = 0;
    reg reset = 1;
    reg [15:0] cpu_input = 0;
    reg [4:0]  load_address = 0;
    reg        load = 0;
    reg        is_instruction = 0;
    wire [15:0] output_value;

    CPU dut (
        .clk(clk), .reset(reset), .cpu_input(cpu_input),
        .load_address(load_address), .load(load),
        .is_instruction(is_instruction), .output_value(output_value)
    );

    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer i;
    reg [511:0] namebuf;
    reg [15:0] dval [0:7];
    reg [15:0] want [0:7];

    task chk(input [15:0] got, input [15:0] exp, input [511:0] name);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s: got %0d (%h), want %0d (%h)", name, got, got, exp, exp);
            end else begin
                $display("  pass %0s = %0d", name, got);
            end
        end
    endtask

    initial begin
        dval[0] = 10;  want[0] = 10;      // ADD
        dval[1] = 15;  want[1] = 25;      // ADD
        dval[2] = 16;  want[2] = 9;       // SUB
        dval[3] = 8;   want[3] = 1;       // SUB
        dval[4] = 255; want[4] = 255;     // MUL
        dval[5] = 15;  want[5] = 3825;    // MUL
        dval[6] = 10;  want[6] = 382;     // DIV
        dval[7] = 0;   want[7] = 65535;   // DIV by zero -> 0xFFFF

        $dumpfile("build/tb_cpu16.vcd");
        $dumpvars(0, tb_cpu16);

        // ---- load the data memory while reset holds the PC at 0 ----
        load = 1; is_instruction = 0;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            cpu_input = dval[i];
            load_address = i[4:0];
        end
        @(negedge clk);
        load = 0;
        reset = 0;

        // output pins must be quiet before the first read
        chk(output_value, 16'd0, "output_value before any read");

        // ---- 24 instructions: 8 arithmetic ops, each followed by an OUTPUT ----
        // mid-way through the READ block: PC=17 executes READ slot 1 -> 25
        repeat (17) @(negedge clk);
        chk(output_value, 16'd25, "output_value driven during READ slot 1");
        repeat (7) @(negedge clk);

        $display("--- Output_Register after the program ---");
        for (i = 0; i < 8; i = i + 1) begin
            $sformat(namebuf, "out[%0d]", i);
            chk(dut.OR.memory[i], want[i], namebuf);
        end

        // ---- 8 NOPs: accumulator must be untouched, no X from uninitialised imem ----
        repeat (7) @(negedge clk);   // now at the end of cycle 30, PC = 31
        chk(dut.instruction, 16'hF000, "PC=31 fetches NOP");
        chk(dut.acc_value, 16'd65535, "acc untouched by READ/NOP");

        $display("");
        if (errors == 0) $display("*** PASS tb_cpu16 (%0d checks)", checks);
        else             $display("*** FAIL tb_cpu16: %0d of %0d checks failed", errors, checks);
        $finish;
    end
endmodule
