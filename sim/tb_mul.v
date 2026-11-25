`timescale 1ns/1ps
// Multiplier regression: the truncated product must equal a*b.
//   iverilog -DBIT8  ... tb_mul.v   -> multiplier_8bit, exhaustive over 65536 pairs
//   iverilog -DBIT16 ... tb_mul.v   -> multiplier_16bit, 65536 sampled pairs
module tb_mul;
    integer errors = 0;
    integer checks = 0;
    integer i, j;

`ifdef BIT8
    reg  [7:0] a = 0, b = 0;
    wire [7:0] product;
    multiplier_8bit dut (.a(a), .b(b), .product(product));
    integer expected;
`endif
`ifdef BIT16
    reg  [15:0] a = 0, b = 0;
    wire [15:0] product;
    multiplier_16bit dut (.a(a), .b(b), .product(product));
    longint expected;
`endif

    initial begin
`ifdef BIT8
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i[7:0]; b = j[7:0]; #1;
                expected = (i * j) & 8'hFF;
                checks = checks + 1;
                if (product !== expected[7:0]) begin
                    errors = errors + 1;
                    if (errors <= 5)
                        $display("  FAIL %0d * %0d = %0d, want %0d", i, j, product, expected);
                end
            end
        end
`endif
`ifdef BIT16
        // 256x256 well-spread operand pairs
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i * 257; b = j * 251; #1;
                expected = (longint'(a) * longint'(b)) & 64'hFFFF;
                checks = checks + 1;
                if (product !== expected[15:0]) begin
                    errors = errors + 1;
                    if (errors <= 5)
                        $display("  FAIL %0d * %0d = %0d, want %0d", a, b, product, expected);
                end
            end
        end
`endif
        $display("");
`ifdef BIT8
        if (errors == 0) $display("*** PASS tb_mul (8-bit, %0d pairs)", checks);
`endif
`ifdef BIT16
        if (errors == 0) $display("*** PASS tb_mul (16-bit, %0d pairs)", checks);
`endif
        if (errors != 0) $display("*** FAIL tb_mul: %0d of %0d pairs wrong", errors, checks);
        $finish;
    end
endmodule
