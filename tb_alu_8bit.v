// =====================================================================
// tb_alu_8bit.v
// Self-checking testbench for alu_8bit
//   - Directed tests: cover every opcode plus key edge cases
//     (zero result, overflow, underflow/borrow, shifts by 0 and max,
//     signed comparisons, all-ones / all-zeros operands)
//   - Random tests: 200 randomized (a, b, opcode) vectors checked
//     against a behavioral reference model
//   - Tracks per-opcode coverage (each opcode hit at least once)
//   - Dumps a VCD waveform for visual inspection
// =====================================================================

`timescale 1ns/1ps

module tb_alu_8bit;

    reg  [7:0] a, b;
    reg  [3:0] opcode;
    wire [7:0] result;
    wire       carry, overflow, zero, negative;

    integer errors;
    integer tests;
    integer i;

    // opcode coverage tracking
    reg [11:0] opcode_hit; // bit per opcode 0..11

    alu_8bit dut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .carry(carry),
        .overflow(overflow), .zero(zero), .negative(negative)
    );

    // ---------------- Reference model ----------------
    task automatic ref_model;
        input  [7:0] ra, rb;
        input  [3:0] rop;
        output [7:0] rresult;
        output       rcarry, rover;
        reg [8:0] add_ext, sub_ext;
        begin
            add_ext = {1'b0, ra} + {1'b0, rb};
            sub_ext = {1'b0, ra} - {1'b0, rb};
            rcarry = 1'b0;
            rover  = 1'b0;
            case (rop)
                4'b0000: begin rresult = add_ext[7:0]; rcarry = add_ext[8];
                               rover = (ra[7]==rb[7]) && (rresult[7]!=ra[7]); end
                4'b0001: begin rresult = sub_ext[7:0]; rcarry = ~sub_ext[8];
                               rover = (ra[7]!=rb[7]) && (rresult[7]!=ra[7]); end
                4'b0010: rresult = ra & rb;
                4'b0011: rresult = ra | rb;
                4'b0100: rresult = ra ^ rb;
                4'b0101: rresult = ~(ra | rb);
                4'b0110: rresult = ra << rb[2:0];
                4'b0111: rresult = ra >> rb[2:0];
                4'b1000: rresult = $signed(ra) >>> rb[2:0];
                4'b1001: rresult = ($signed(ra) < $signed(rb)) ? 8'h01 : 8'h00;
                4'b1010: rresult = (ra < rb) ? 8'h01 : 8'h00;
                4'b1011: rresult = ~ra;
                default: rresult = 8'h00;
            endcase
        end
    endtask

    // ---------------- Check task ----------------
    task automatic check(input [127:0] label);
        reg [7:0] exp_result;
        reg       exp_carry, exp_over;
        begin
            ref_model(a, b, opcode, exp_result, exp_carry, exp_over);
            tests = tests + 1;
            if (opcode <= 11) opcode_hit[opcode] = 1'b1;
            #1; // allow combinational settle for $display ordering
            if (result !== exp_result || carry !== exp_carry || overflow !== exp_over) begin
                errors = errors + 1;
                $display("FAIL [%0s] a=%h b=%h op=%b | got result=%h carry=%b ovf=%b | exp result=%h carry=%b ovf=%b",
                          label, a, b, opcode, result, carry, overflow, exp_result, exp_carry, exp_over);
            end else begin
                $display("PASS [%0s] a=%h b=%h op=%b -> result=%h carry=%b ovf=%b zero=%b neg=%b",
                          label, a, b, opcode, result, carry, overflow, zero, negative);
            end
        end
    endtask

    task automatic apply(input [7:0] ta, input [7:0] tb, input [3:0] top, input [127:0] label);
        begin
            a = ta; b = tb; opcode = top;
            #5;
            check(label);
        end
    endtask

    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, tb_alu_8bit);

        errors = 0;
        tests  = 0;
        opcode_hit = 12'b0;

        $display("===================================================");
        $display(" DIRECTED TESTS");
        $display("===================================================");

        // ADD: basic, zero result, carry-out, signed overflow
        apply(8'h05, 8'h03, 4'b0000, "ADD_basic");
        apply(8'h00, 8'h00, 4'b0000, "ADD_zero");
        apply(8'hFF, 8'h01, 4'b0000, "ADD_carry_out");
        apply(8'h7F, 8'h01, 4'b0000, "ADD_signed_overflow"); // 127+1 overflows

        // SUB: basic, zero result, borrow, signed overflow
        apply(8'h05, 8'h03, 4'b0001, "SUB_basic");
        apply(8'h05, 8'h05, 4'b0001, "SUB_zero");
        apply(8'h00, 8'h01, 4'b0001, "SUB_borrow");
        apply(8'h80, 8'h01, 4'b0001, "SUB_signed_overflow"); // -128-1 overflows

        // Bitwise ops
        apply(8'hF0, 8'h0F, 4'b0010, "AND_disjoint");
        apply(8'hAA, 8'h55, 4'b0011, "OR_alternating");
        apply(8'hFF, 8'hFF, 4'b0100, "XOR_identical");
        apply(8'h00, 8'h00, 4'b0101, "NOR_all_zero");

        // Shifts: by 0 and by max (7)
        apply(8'h01, 8'h00, 4'b0110, "SLL_by_zero");
        apply(8'h01, 8'h07, 4'b0110, "SLL_by_max");
        apply(8'h80, 8'h07, 4'b0111, "SRL_by_max");
        apply(8'h80, 8'h01, 4'b1000, "SRA_negative_msb");

        // Comparisons
        apply(8'hFF, 8'h01, 4'b1001, "SLT_signed_neg_lt_pos"); // -1 < 1 -> true
        apply(8'h01, 8'hFF, 4'b1010, "SLTU_unsigned_lt");      // 1 < 255 -> true

        // NOT
        apply(8'h00, 8'h00, 4'b1011, "NOT_all_zero");
        apply(8'hFF, 8'h00, 4'b1011, "NOT_all_ones");

        // Illegal/undefined opcode -> default branch
        apply(8'hAA, 8'h55, 4'b1111, "UNDEFINED_opcode");

        $display("===================================================");
        $display(" RANDOM TESTS (200 vectors, opcodes 0-11)");
        $display("===================================================");
        for (i = 0; i < 200; i = i + 1) begin
            a = $random;
            b = $random;
            opcode = $unsigned($random) % 12; // restrict to defined opcodes 0-11
            #5;
            check("RANDOM");
        end

        $display("===================================================");
        $display(" SUMMARY");
        $display("===================================================");
        $display("Total checks run : %0d", tests);
        $display("Failures         : %0d", errors);
        $display("Opcode coverage  : %0d / 12 opcodes hit (mask=%b)",
                  count_ones(opcode_hit), opcode_hit);

        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: %0d TEST(S) FAILED", errors);

        $finish;
    end

    function automatic integer count_ones(input [11:0] vec);
        integer k;
        begin
            count_ones = 0;
            for (k = 0; k < 12; k = k + 1)
                if (vec[k]) count_ones = count_ones + 1;
        end
    endfunction

endmodule