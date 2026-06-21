// =====================================================================
// alu_8bit.v
// Synthesizable 8-bit Arithmetic Logic Unit (ALU)
//
// Supports 12 operations selected by a 4-bit opcode:
//   0000 ADD   : result = a + b
//   0001 SUB   : result = a - b
//   0010 AND   : result = a & b
//   0011 OR    : result = a | b
//   0100 XOR   : result = a ^ b
//   0101 NOR   : result = ~(a | b)
//   0110 SLL   : result = a << b[2:0]   (logical shift left)
//   0111 SRL   : result = a >> b[2:0]   (logical shift right)
//   1000 SRA   : result = a >>> b[2:0]  (arithmetic shift right)
//   1001 SLT   : result = (signed a < signed b) ? 1 : 0
//   1010 SLTU  : result = (unsigned a < unsigned b) ? 1 : 0
//   1011 NOT   : result = ~a
//   others     : result = 8'h00 (default/illegal opcode)
//
// Flags:
//   zero     - result == 0
//   negative - result[7] (MSB of result, two's-complement sign bit)
//   carry    - carry-out for ADD, NOT(borrow) for SUB, 0 otherwise
//   overflow - signed arithmetic overflow for ADD/SUB, 0 otherwise
// =====================================================================

module alu_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] opcode,
    output reg  [7:0] result,
    output reg        carry,
    output reg        overflow,
    output wire        zero,
    output wire        negative
);

    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam AND_OP = 4'b0010;
    localparam OR_OP  = 4'b0011;
    localparam XOR_OP = 4'b0100;
    localparam NOR_OP = 4'b0101;
    localparam SLL  = 4'b0110;
    localparam SRL  = 4'b0111;
    localparam SRA  = 4'b1000;
    localparam SLT  = 4'b1001;
    localparam SLTU = 4'b1010;
    localparam NOT_OP = 4'b1011;

    wire [8:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [8:0] sub_ext = {1'b0, a} - {1'b0, b};

    assign zero     = (result == 8'h00);
    assign negative = result[7];

    always @(*) begin
        // Defaults every evaluation (avoids latch inference)
        result   = 8'h00;
        carry    = 1'b0;
        overflow = 1'b0;

        case (opcode)
            ADD: begin
                result   = add_ext[7:0];
                carry    = add_ext[8];
                // signed overflow: operands same sign, result different sign
                overflow = (a[7] == b[7]) && (result[7] != a[7]);
            end

            SUB: begin
                result   = sub_ext[7:0];
                carry    = ~sub_ext[8]; // carry=1 means no borrow (typical ALU convention)
                // signed overflow: operands different sign, result sign != a's sign
                overflow = (a[7] != b[7]) && (result[7] != a[7]);
            end

            AND_OP:  result = a & b;
            OR_OP:   result = a | b;
            XOR_OP:  result = a ^ b;
            NOR_OP:  result = ~(a | b);
            SLL:     result = a << b[2:0];
            SRL:     result = a >> b[2:0];
            SRA:     result = $signed(a) >>> b[2:0];
            SLT:     result = ($signed(a) < $signed(b)) ? 8'h01 : 8'h00;
            SLTU:    result = (a < b) ? 8'h01 : 8'h00;
            NOT_OP:  result = ~a;

            default: result = 8'h00;
        endcase
    end

endmodule