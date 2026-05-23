// ============================================================
// Module: step_sequence_driver
// Description: Generates the coil excitation sequence for the stepper motor.
//
//   Full step (4 steps):
//     CW:  1001 → 0101 → 0110 → 1010
//     CCW: 1010 → 0110 → 0101 → 1001
//
//   Half step (8 steps):
//     CW:  1000 → 1001 → 0001 → 0101 →
//          0100 → 0110 → 0010 → 1010
//     CCW: reverse order
//
//   pulses_out[3:0] connects to GPIO pins -> driver -> motor
// ============================================================

module step_sequence_driver (
    input  wire       clk,         // system clock
    input  wire       resetb,      // active-low reset
    input  wire       step_tick,   // step rate
    input  wire       move_enable, // motion permission from motion_controller
    input  wire       direction,   // SW1: 1=CW, 0=CCW
    input  wire       step_size,   // SW3: 1=full, 0=half
    output reg  [3:0] pulses_out   // coil sequence to the driver
);

    reg [2:0] step_idx;  // current step index (0-7 for half-step, 0-3 for full-step)

    // ---- Full-step sequence tables ----
    // CW: A→AB→B→BA pattern
    function [3:0] full_step_seq;
        input [1:0] idx;
        input       dir;
        begin
            if (dir) begin // CW
                case (idx)
                    2'd0: full_step_seq = 4'b1001;
                    2'd1: full_step_seq = 4'b0101;
                    2'd2: full_step_seq = 4'b0110;
                    2'd3: full_step_seq = 4'b1010;
                    default: full_step_seq = 4'b1001;
                endcase
            end else begin // CCW - reverse order
                case (idx)
                    2'd0: full_step_seq = 4'b1010;
                    2'd1: full_step_seq = 4'b0110;
                    2'd2: full_step_seq = 4'b0101;
                    2'd3: full_step_seq = 4'b1001;
                    default: full_step_seq = 4'b1010;
                endcase
            end
        end
    endfunction

    // ---- Half-step sequence table ----
    function [3:0] half_step_seq;
        input [2:0] idx;
        input       dir;
        begin
            if (dir) begin // CW
                case (idx)
                    3'd0: half_step_seq = 4'b1000;
                    3'd1: half_step_seq = 4'b1001;
                    3'd2: half_step_seq = 4'b0001;
                    3'd3: half_step_seq = 4'b0101;
                    3'd4: half_step_seq = 4'b0100;
                    3'd5: half_step_seq = 4'b0110;
                    3'd6: half_step_seq = 4'b0010;
                    3'd7: half_step_seq = 4'b1010;
                    default: half_step_seq = 4'b1000;
                endcase
            end else begin // CCW - reverse order
                case (idx)
                    3'd0: half_step_seq = 4'b1010;
                    3'd1: half_step_seq = 4'b0010;
                    3'd2: half_step_seq = 4'b0110;
                    3'd3: half_step_seq = 4'b0100;
                    3'd4: half_step_seq = 4'b0101;
                    3'd5: half_step_seq = 4'b0001;
                    3'd6: half_step_seq = 4'b1001;
                    3'd7: half_step_seq = 4'b1000;
                    default: half_step_seq = 4'b1010;
                endcase
            end
        end
    endfunction

// ---- Step advance logic ----
always @(posedge clk or negedge resetb) begin
    if (!resetb) begin
        step_idx   <= 3'd0;
        pulses_out <= 4'b1001;
    end else begin

        if (move_enable && step_tick) begin

            if (step_size) begin
                // Full step
                if (step_idx[1:0] == 2'd3)
                    step_idx <= 3'd0;
                else
                    step_idx <= step_idx + 3'd1;
            end else begin
                // Half step
                if (step_idx == 3'd7)
                    step_idx <= 3'd0;
                else
                    step_idx <= step_idx + 3'd1;
            end

        end

        // Output follows current index
        if (step_size)
            pulses_out <= full_step_seq(step_idx[1:0], direction);
        else
            pulses_out <= half_step_seq(step_idx, direction);
    end
end
endmodule