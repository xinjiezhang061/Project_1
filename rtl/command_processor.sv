module command_processor (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cmd_valid,
    output logic        cmd_ready,
    input  logic [31:0] cmd_data,
    output logic        event_valid,
    input  logic        event_ready,
    output logic [1:0]  event_type,
    output logic [15:0] event_vertices,
    output logic [7:0]  event_instances,
    output logic        error_valid,
    output logic [7:0]  state_value
);

    localparam logic [3:0] OP_NOP      = 4'h0;
    localparam logic [3:0] OP_SET_STATE = 4'h1;
    localparam logic [3:0] OP_DRAW     = 4'h2;
    localparam logic [3:0] OP_BARRIER  = 4'h3;

    localparam logic [1:0] EVENT_DRAW = 2'd1;
    localparam logic [1:0] EVENT_BARRIER = 2'd2;

    // The block has one-entry event storage. Commands that produce events are
    // back-pressured until the consumer accepts the previous event.
    assign cmd_ready = !event_valid || event_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_valid    <= 1'b0;
            event_type     <= 2'b0;
            event_vertices <= 16'b0;
            event_instances<= 8'b0;
            error_valid    <= 1'b0;
            state_value    <= 8'b0;
        end else begin
            error_valid <= 1'b0;

            if (event_valid && event_ready)
                event_valid <= 1'b0;

            if (cmd_valid && cmd_ready) begin
                unique case (cmd_data[31:28])
                    OP_NOP: begin
                        // Intentionally no side effect.
                    end
                    OP_SET_STATE: begin
                        state_value <= cmd_data[7:0];
                    end
                    OP_DRAW: begin
                        event_valid     <= 1'b1;
                        event_type      <= EVENT_DRAW;
                        event_vertices  <= cmd_data[23:8];
                        event_instances <= cmd_data[7:0];
                    end
                    OP_BARRIER: begin
                        event_valid     <= 1'b1;
                        event_type      <= EVENT_BARRIER;
                        event_vertices  <= 16'b0;
                        event_instances <= 8'b0;
                    end
                    default: begin
                        error_valid <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
