`timescale 1ns/1ps
// ISA regression on the 16-bit core: exercises AND/OR (previously unreachable
// opcodes) and the NOP default, using instructions loaded through the pins.
module tb_isa;
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
    reg [15:0] prog [0:3];
    reg [15:0] dval [0:2];

    task chk(input [15:0] got, input [15:0] exp, input [511:0] name);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s: got %0d (%h), want %0d (%h)", name, got, got, exp, exp);
            end else begin
                $display("  pass %0s = %h", name, got);
            end
        end
    endtask

    initial begin
        prog[0] = 16'b0000_0001_0000_0001;  // ADD  data 1  (0x0F0F)
        prog[1] = 16'b0010_0000_0000_0000;  // AND  data 0  (0x00FF)
        prog[2] = 16'b0011_0010_0000_0010;  // OR   data 2  (0xF000)
        prog[3] = 16'b1111_0000_0000_0000;  // NOP (unknown opcode)

        dval[0] = 16'h00FF;
        dval[1] = 16'h0F0F;
        dval[2] = 16'hF000;

        $dumpfile("build/tb_isa.vcd");
        $dumpvars(0, tb_isa);

        load = 1; is_instruction = 1;
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            cpu_input = prog[i]; load_address = i[4:0];
        end
        @(negedge clk);
        is_instruction = 0;
        for (i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            cpu_input = dval[i]; load_address = i[4:0];
        end
        @(negedge clk);
        load = 0; reset = 0;

        @(negedge clk); chk(dut.acc_value, 16'h0F0F, "ADD");
        @(negedge clk); chk(dut.acc_value, 16'h000F, "AND");
        @(negedge clk); chk(dut.acc_value, 16'hF00F, "OR");
        @(negedge clk); chk(dut.acc_value, 16'hF00F, "NOP leaves acc alone");

        $display("");
        if (errors == 0) $display("*** PASS tb_isa (%0d checks)", checks);
        else             $display("*** FAIL tb_isa: %0d of %0d checks failed", errors, checks);
        $finish;
    end
endmodule
