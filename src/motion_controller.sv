// ============================================================
// Module: motion_controller
// Description: Controls motor motion using two operating modes:
//
//   on=1 : continuous mode - the motor rotates continuously
//   on=0 : quarter mode - a quarter_pulse command rotates the motor
//          exactly 1/4 revolution (50 full steps / 100 half steps)
//          and then stops. A new quarter turn is allowed only after completion.
//
//   move_enable=1 -> allows step_sequence_driver to advance one step
// ============================================================

module motion_controller (
    input  wire       clk,           // system clock
    input  wire       resetb,        // active-low reset
    input  wire       on,            // SW2: 1=continuous, 0=stop/quarter-turn mode
    input  wire       step_size,     // SW3: 1=full, 0=half
    input  wire       quarter_pulse, // pulse from KEY1 (one-pulse)
    input  wire       step_tick,     // step pulse from the tick generator
    output reg        move_enable    // motion enable signal for the driver
);

    // Number of steps required for a quarter turn
    // Full step: 200/4 = 50 steps
    // Half step: 400/4 = 100 steps
    wire [6:0] quarter_steps = step_size ? 7'd50 : 7'd100;

    // FSM states
    localparam IDLE     = 2'd0;  // stopped - waiting for a command
    localparam RUNNING  = 2'd1;  // continuous mode (on=1)
    localparam QUARTER  = 2'd2;  // executing a quarter turn

    reg [1:0]  state;
    reg [6:0]  step_count;  // counts steps while in QUARTER state

    always @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            state       <= IDLE;
            step_count  <= 7'd0;
            move_enable <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    move_enable <= 1'b0;
                    if (on) begin
                        // SW2=1 -> enter continuous motion
                        state <= RUNNING;
                    end else if (quarter_pulse) begin
                        // KEY1 press -> start quarter turn
                        state      <= QUARTER;
                        step_count <= 7'd0;
                    end
                end

                RUNNING: begin
                    move_enable <= 1'b1;
                    if (!on) begin
                        // SW2 turned off -> stop
                        state       <= IDLE;
                        move_enable <= 1'b0;
                    end
                end

                QUARTER: begin
                    move_enable <= 1'b1;
                    if (step_tick) begin
                        if (step_count >= quarter_steps - 1) begin
                            // quarter turn completed -> stop
                            state       <= IDLE;
                            move_enable <= 1'b0;
                            step_count  <= 7'd0;
                        end else begin
                            step_count <= step_count + 1;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule