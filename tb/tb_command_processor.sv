`timescale 1ns/1ps

module tb_command_processor;
    logic clk = 0;
    always #5 clk = ~clk;

    logic rst_n, cmd_valid, cmd_ready;
    logic [31:0] cmd_data;
    logic event_valid, event_ready, error_valid;
    logic [1:0] event_type;
    logic [15:0] event_vertices;
    logic [7:0] event_instances, state_value;

    localparam logic [3:0] OP_SET_STATE = 4'h1;
    localparam logic [3:0] OP_DRAW = 4'h2;
    localparam logic [3:0] OP_BARRIER = 4'h3;
    localparam logic [1:0] EVENT_DRAW = 2'd1;
    localparam logic [1:0] EVENT_BARRIER = 2'd2;

    int checks, failures;
    int opcode_set_state, opcode_draw, opcode_barrier, opcode_invalid;
    int zero_count_draw, max_count_draw, reset_recovery;

    command_processor dut (.*);

    task automatic expect(input bit condition, input string message);
        checks++;
        if (!condition) begin
            failures++;
            $display("[FAIL] %s", message);
        end
    endtask

    task automatic reset_dut;
        rst_n = 0; cmd_valid = 0; cmd_data = '0; event_ready = 1;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    task automatic send(input logic [31:0] word);
        @(negedge clk);
        while (!cmd_ready) @(negedge clk);
        cmd_data = word; cmd_valid = 1;
        @(negedge clk);
        cmd_valid = 0;
    endtask

    task automatic consume_event(input logic [1:0] typ, input logic [15:0] verts, input logic [7:0] inst);
        while (!event_valid) @(posedge clk);
        expect(event_type == typ, "event type matches reference model");
        expect(event_vertices == verts, "event vertex count matches reference model");
        expect(event_instances == inst, "event instance count matches reference model");
        @(negedge clk);
        event_ready = 1;
    endtask

    function automatic [31:0] set_state(input [7:0] value);
        set_state = {OP_SET_STATE, 20'b0, value};
    endfunction
    function automatic [31:0] draw(input [15:0] verts, input [7:0] inst);
        draw = {OP_DRAW, 4'b0, verts, inst};
    endfunction
    function automatic [31:0] barrier;
        barrier = {OP_BARRIER, 28'b0};
    endfunction

    initial begin
        rst_n = 0; cmd_valid = 0; cmd_data = 0; event_ready = 1;
        reset_dut();
        expect(state_value == 0, "state resets to zero");

        send(set_state(8'h5A));
        @(posedge clk);
        expect(state_value == 8'h5A, "SET_STATE updates state register");
        opcode_set_state++;

        send(draw(16'd3, 8'd2));
        consume_event(EVENT_DRAW, 16'd3, 8'd2);
        @(posedge clk);
        opcode_draw++;

        send(draw(16'd0, 8'd0));
        consume_event(EVENT_DRAW, 16'd0, 8'd0);
        zero_count_draw++; opcode_draw++;

        send(draw(16'hFFFF, 8'hFF));
        consume_event(EVENT_DRAW, 16'hFFFF, 8'hFF);
        max_count_draw++; opcode_draw++;

        send(barrier());
        consume_event(EVENT_BARRIER, 0, 0);
        opcode_barrier++;

        // Invalid opcode must raise an error and preserve the state value.
        send(32'hF123_4567);
        @(posedge clk);
        expect(error_valid, "invalid opcode raises error");
        expect(state_value == 8'h5A, "invalid opcode does not corrupt state");
        opcode_invalid++;

        // Reset recovery check.
        reset_dut();
        expect(state_value == 0, "reset clears state after traffic");
        send(set_state(8'hA5));
        @(posedge clk);
        expect(state_value == 8'hA5, "block accepts commands after reset");
        reset_recovery++;

        $display("\nVerification summary");
        $display("  Checks: %0d  Failures: %0d", checks, failures);
        $display("  Coverage: SET_STATE=%0d DRAW=%0d BARRIER=%0d INVALID=%0d", opcode_set_state, opcode_draw, opcode_barrier, opcode_invalid);
        $display("  Coverage: ZERO_DRAW=%0d MAX_DRAW=%0d RESET_RECOVERY=%0d", zero_count_draw, max_count_draw, reset_recovery);
        if (failures != 0) $fatal(1, "verification failed");
        $display("  PASS");
        $finish;
    end
endmodule
