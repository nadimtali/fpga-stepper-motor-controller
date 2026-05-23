// ============================================================
// Module: step_motor_top  (TOP MODULE)
// Description: Top-level module that connects all system modules.
//
//  INPUTS:
//    clk        - 50 MHz clock from the FPGA board
//    resetb     - KEY0 (active low reset)
//    direction  - SW1  (1=CW, 0=CCW)
//    speed_sel  - KEY3 (press = change speed)
//    on         - SW2  (1=continuous, 0=stop)
//    quarter    - KEY1 (press = quarter turn)
//    step_size  - SW3  (1=full step, 0=half step)
//
//  OUTPUTS:
//    sev_seg_o  - HEX0 (RPM ones digit)
//    sev_seg_t  - HEX1 (RPM tens digit)
//    pulses_out - GPIO pins carrying the driver sequence
// ============================================================

module step_motor_top (
    input  wire       clk,
    input  wire       resetb,
    input  wire       direction,
    input  wire       speed_sel,
    input  wire       on,
    input  wire       quarter,
    input  wire       step_size,
    output wire [6:0] sev_seg_o,
    output wire [6:0] sev_seg_t,
    output wire [3:0] pulses_out
);

    // ---- Internal connections ----
    wire       speed_pulse;    // single pulse from KEY3
    wire       quarter_pulse;  // single pulse from KEY1
    wire [5:0] speed_rpm;      // current speed in RPM
    wire       step_tick;      // step-rate pulse
    wire       move_enable;    // motion enable

    // ---- 1. One-pulse generator for KEY3 (speed_sel) ----
    button_one_pulse u_pulse_speed (
        .clk     (clk),
        .resetb  (resetb),
        .button  (speed_sel),
        .pulse   (speed_pulse)
    );

    // ---- 2. One-pulse generator for KEY1 (quarter) ----
    button_one_pulse u_pulse_quarter (
        .clk     (clk),
        .resetb  (resetb),
        .button  (quarter),
        .pulse   (quarter_pulse)
    );

    // ---- 3. Speed-selection FSM ----
    speed_controller u_speed_ctrl (
        .clk         (clk),
        .resetb      (resetb),
        .speed_pulse (speed_pulse),
        .speed_rpm   (speed_rpm)
    );

    // ---- 4. Speed display on 7-segment displays ----
    speed_display u_speed_disp (
        .speed_rpm (speed_rpm),
        .sev_seg_t (sev_seg_t),
        .sev_seg_o (sev_seg_o)
    );

    // ---- 5. Step pulse generator (tick generator) ----
    step_tick_generator u_tick_gen (
        .clk       (clk),
        .resetb    (resetb),
        .speed_rpm (speed_rpm),
        .step_size (step_size),
        .step_tick (step_tick)
    );

    // ---- 6. Motion controller (continuous / quarter turn) ----
    motion_controller u_motion_ctrl (
        .clk          (clk),
        .resetb       (resetb),
        .on           (on),
        .step_size    (step_size),
        .quarter_pulse(quarter_pulse),
        .step_tick    (step_tick),
        .move_enable  (move_enable)
    );

    // ---- 7. Coil sequence driver ----
    step_sequence_driver u_seq_driver (
        .clk        (clk),
        .resetb     (resetb),
        .step_tick  (step_tick),
        .move_enable(move_enable),
        .direction  (direction),
        .step_size  (step_size),
        .pulses_out (pulses_out)
    );

endmodule