// ============================================================
// Module: step_tick_generator
// Description: Generates a step_tick pulse at the required motor stepping rate
//              according to the following parameters:
//                - speed_rpm : speed (10-60 RPM)
//                - step_size : 1=full step, 0=half step
//
//              Tick-period calculation:
//              steps_per_rev = 200 (full) or 400 (half)
//              period = CLK_FREQ / (RPM/60 * steps_per_rev)
//                     = CLK_FREQ * 60 / (RPM * steps_per_rev)
// ============================================================

module step_tick_generator (
    input  wire       clk,       // 50 MHz system clock
    input  wire       resetb,    // active-low reset
    input  wire [5:0] speed_rpm, // speed in RPM
    input  wire       step_size, // 1=full step, 0=half step
    output reg        step_tick  // step pulse - one clock-wide pulse per motor step
);

    parameter CLK_FREQ = 50_000_000; // 50 MHz

    // ---- Compute the period according to RPM and step_size ----
    // Full step: 200 steps/rev → period = 50M*60 / (RPM*200)
    // Half step: 400 steps/rev → period = 50M*60 / (RPM*400)

    reg [31:0] period;   // number of clock cycles between motor steps
    reg [31:0] counter;  // current counter value

    // Period calculation (combinational)
    always @(*) begin
        if (step_size) begin
            // Full step mode - 200 steps per revolution
            case (speed_rpm)
                6'd10: period = 32'd1_500_000; // 50M*60/(10*200)
                6'd20: period = 32'd750_000;
                6'd30: period = 32'd500_000;
                6'd40: period = 32'd375_000;
                6'd50: period = 32'd300_000;
                6'd60: period = 32'd250_000;
                default: period = 32'd1_500_000;
            endcase
        end else begin
            // Half step mode - 400 steps per revolution
            case (speed_rpm)
                6'd10: period = 32'd750_000;  // 50M*60/(10*400)
                6'd20: period = 32'd375_000;
                6'd30: period = 32'd250_000;
                6'd40: period = 32'd187_500;
                6'd50: period = 32'd150_000;
                6'd60: period = 32'd125_000;
                default: period = 32'd750_000;
            endcase
        end
    end

    // ---- Counter and pulse generation ----
    always @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            counter   <= 32'd0;
            step_tick <= 1'b0;
        end else begin
            if (counter >= period - 1) begin
                counter   <= 32'd0;
                step_tick <= 1'b1;  // step pulse
            end else begin
                counter   <= counter + 1;
                step_tick <= 1'b0;
            end
        end
    end

endmodule