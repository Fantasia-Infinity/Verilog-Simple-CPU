`timescale 1ns/1ps
// 8-bit CPU regression. The 8-bit Instruction_Register has no built-in program,
// so this testbench loads one through the pin interface while reset is held -
// exactly how a real host would program the chip.
//
// Instruction format: [7:4] opcode, [3:0] operand address / output slot.
module tb_cpu8;
    reg clk = 0;
    reg reset = 1;
    reg [7:0] cpu_input = 0;
    reg [4:0] load_address = 0;
    reg       load = 0;
    reg       is_instruction = 0;
    wire [7:0] output_value;

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
    reg [7:0] prog [0:23];
    reg [7:0] dval [0:7];
    reg [7:0] want [0:7];

    task chk(input [7:0] got, input [7:0] exp, input [511:0] name);
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
        // ---- program ----
        prog[0]  = 8'h00;  // ADD   data 0
        prog[1]  = 8'h60;  // OUTPUT slot 0
        prog[2]  = 8'h01;  // ADD   data 1
        prog[3]  = 8'h61;  // OUTPUT slot 1
        prog[4]  = 8'h12;  // SUB   data 2
        prog[5]  = 8'h62;  // OUTPUT slot 2
        prog[6]  = 8'h13;  // SUB   data 3
        prog[7]  = 8'h63;  // OUTPUT slot 3
        prog[8]  = 8'h44;  // MUL   data 4
        prog[9]  = 8'h64;  // OUTPUT slot 4
        prog[10] = 8'h45;  // MUL   data 5
        prog[11] = 8'h65;  // OUTPUT slot 5
        prog[12] = 8'h56;  // DIV   data 6
        prog[13] = 8'h66;  // OUTPUT slot 6
        prog[14] = 8'h57;  // DIV   data 7
        prog[15] = 8'h67;  // OUTPUT slot 7
        prog[16] = 8'h70;  // OUTPUT_READ slot 0
        prog[17] = 8'h71;
        prog[18] = 8'h72;
        prog[19] = 8'h73;
        prog[20] = 8'h74;
        prog[21] = 8'h75;
        prog[22] = 8'h76;
        prog[23] = 8'h77;

        dval[0] = 10;  want[0] = 10;     // ADD
        dval[1] = 15;  want[1] = 25;     // ADD
        dval[2] = 16;  want[2] = 9;      // SUB
        dval[3] = 8;   want[3] = 1;      // SUB
        dval[4] = 255; want[4] = 255;    // MUL
        dval[5] = 15;  want[5] = 241;    // MUL wraps: 255*15 = 3825 mod 256
        dval[6] = 10;  want[6] = 24;     // DIV: 241 / 10
        dval[7] = 0;   want[7] = 255;    // DIV by zero -> 0xFF

        $dumpfile("build/tb_cpu8.vcd");
        $dumpvars(0, tb_cpu8);

        // ---- load instructions, then data, then fill the rest with NOP ----
        load = 1; is_instruction = 1;
        for (i = 0; i < 32; i = i + 1) begin
            @(negedge clk);
            cpu_input = (i < 24) ? prog[i] : 8'hF0;   // 0xF0..0xFF decode to NOP
            load_address = i[4:0];
        end
        @(negedge clk);                                // let the last one land
        is_instruction = 0;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            cpu_input = dval[i];
            load_address = i[4:0];
        end
        @(negedge clk);
        load = 0;
        reset = 0;

        chk(output_value, 8'd0, "output_value before any read");

        // mid-way through the READ block: uo_out must already carry the slot
        // selected by the instruction currently being executed (PC=18 -> slot 2)
        repeat (18) @(negedge clk);
        chk(output_value, 8'd9, "uo_out driven during READ slot 2");
        repeat (6) @(negedge clk);

        $display("--- Output_Register after the program ---");
        for (i = 0; i < 8; i = i + 1) begin
            $sformat(namebuf, "out[%0d]", i);
            chk(dut.OR.memory[i], want[i], namebuf);
        end

        // after the READ block the pins must still hold the last slot read
        chk(output_value, 8'd255, "uo_out holds slot 7");

        $display("");
        if (errors == 0) $display("*** PASS tb_cpu8 (%0d checks)", checks);
        else             $display("*** FAIL tb_cpu8: %0d of %0d checks failed", errors, checks);
        $finish;
    end
endmodule
