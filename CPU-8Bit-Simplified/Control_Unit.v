module Control_Unit (
    input  [7:0] instruction,       // 8-bit instruction, [7:4] = opcode, [3:0] = operand address
    output reg       acc_we,        // accumulator write enable (only real ALU ops)
    output reg       sub,           // subtract control for the ALU
    output reg [2:0] op_select,     // ALU operation select
    output reg       write_enable,  // Output_Register write enable
    output reg       read_enable,   // Output_Register read enable
    output reg [4:0] output_index   // Output_Register slot
);
    localparam [3:0] OP_ADD  = 4'b0000,
                     OP_SUB  = 4'b0001,
                     OP_AND  = 4'b0010,
                     OP_OR   = 4'b0011,
                     OP_MUL  = 4'b0100,
                     OP_DIV  = 4'b0101,
                     OP_OUT  = 4'b0110,
                     OP_READ = 4'b0111;

    always @(*) begin
        // Safe defaults: nothing is written anywhere unless the opcode asks for it.
        acc_we       = 1'b0;
        sub          = 1'b0;
        op_select    = 3'b000;
        write_enable = 1'b0;
        read_enable  = 1'b0;
        output_index = 5'b00000;

        case (instruction[7:4])
            OP_ADD:  begin acc_we = 1'b1; op_select = 3'b000; sub = 1'b0; end
            OP_SUB:  begin acc_we = 1'b1; op_select = 3'b001; sub = 1'b1; end
            OP_AND:  begin acc_we = 1'b1; op_select = 3'b010; end
            OP_OR:   begin acc_we = 1'b1; op_select = 3'b011; end
            OP_MUL:  begin acc_we = 1'b1; op_select = 3'b100; end
            OP_DIV:  begin acc_we = 1'b1; op_select = 3'b101; end
            // The output slot is the same 4-bit field that also selects the
            // operand address, so only slots 0..15 of the 32-deep register are
            // reachable. NOTE: this must be instruction[3:0], not [4:0] -
            // bit 4 is part of the opcode and is 1 for OUTPUT_READ (0111_xxxx),
            // which made READ k address slot 16+k while OUTPUT k wrote slot k.
            OP_OUT:  begin write_enable = 1'b1;
                           output_index = {1'b0, instruction[3:0]}; end
            OP_READ: begin read_enable  = 1'b1;
                           output_index = {1'b0, instruction[3:0]}; end
            // Any other opcode is a NOP: the accumulator is left untouched.
            default: ;
        endcase
    end
endmodule
