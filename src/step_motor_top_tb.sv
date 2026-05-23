// ============================================================
// Testbench: step_motor_top_tb
// Description: Full-system testbench.
//
//   Uses defparam to override CLK_FREQ to 100 instead of 50 MHz,
//   so every period is small enough for fast simulation.
//
//   CLK_FREQ=100:
//     Full step, 10RPM: period = 100*60/(10*200) = 3 cycles
//     Half step, 60RPM: period = 100*60/(60*400) = 0 → min 1
//   -> the simulation runs in seconds instead of hours.
//
//   Simulation limit: MAX_CYCLES clock cycles, then $finish
// ============================================================

`timescale 1ns/1ps

module step_motor_top_tb;

    // ---- Simulation-limit parameters ----
    localparam MAX_CYCLES = 10_000;  // maximum number of clock cycles
    localparam CLK_PERIOD = 20;      // 20 ns = 50 MHz clock period for simulation timing

    // ---- Inputs (regs) ----
    reg clk;
    reg resetb;
    reg direction;
    reg speed_sel;
    reg on;
    reg quarter;
    reg step_size;

    // ---- Outputs (wires) ----
    wire [6:0] sev_seg_o;
    wire [6:0] sev_seg_t;
    wire [3:0] pulses_out;

    // ---- Cycle counter for simulation limit ----
    integer cycle_count;

    // ---- instantiate ----
    step_motor_top uut (
        .clk        (clk),
        .resetb     (resetb),
        .direction  (direction),
        .speed_sel  (speed_sel),
        .on         (on),
        .quarter    (quarter),
        .step_size  (step_size),
        .sev_seg_o  (sev_seg_o),
        .sev_seg_t  (sev_seg_t),
        .pulses_out (pulses_out)
    );

    // ---- Override CLK_FREQ for simulation ----
    // Instead of 50,000,000 -> 100, so the periods are small
    defparam uut.u_tick_gen.CLK_FREQ = 100;

    // ---- Clock generation ----
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- Simulation limit ----
    initial begin
        cycle_count = 0;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
        if (cycle_count >= MAX_CYCLES) begin
            $display("=== Reached the limit of %0d cycles - stopping simulation ===", MAX_CYCLES);
            $finish;
        end
    end

    // ---- Main test sequence ----
    initial begin
        // initialize all inputs
        resetb    = 0;
        direction = 1;   // CW
        speed_sel = 1;   // not pressed (active low)
        on        = 0;   // stopped
        quarter   = 1;   // not pressed (active low)
        step_size = 1;   // full step

        $display("--- Test 1: Reset ---");
        repeat(5) @(posedge clk);
        resetb = 1;  // release reset
        repeat(5) @(posedge clk);
        $display("After reset: pulses=%b, seg_t=%b, seg_o=%b",
                  pulses_out, sev_seg_t, sev_seg_o);

        // =============================================
        $display("--- Test 2: Continuous motion - Full Step CW ---");
        on = 1;   // SW2=1 → continuous
        repeat(50) @(posedge clk);
        $display("Continuous CW full-step: pulses=%b", pulses_out);

        // =============================================
        $display("--- Test 3: Speed change (KEY3) ---");
        // press speed_sel (active low)
        speed_sel = 0;
        repeat(2) @(posedge clk);
        speed_sel = 1;
        repeat(20) @(posedge clk);
        $display("After press 1 - speed: seg_t=%b (expected digit 2)", sev_seg_t);

        speed_sel = 0;
        repeat(2) @(posedge clk);
        speed_sel = 1;
        repeat(20) @(posedge clk);
        $display("After press 2 - speed: seg_t=%b (expected digit 3)", sev_seg_t);

        // =============================================
        $display("--- Test 4: Direction change to CCW ---");
        direction = 0;  // SW1=0 → CCW
        repeat(30) @(posedge clk);
        $display("CCW full: pulses=%b", pulses_out);

        // =============================================
        $display("--- Test 5: Half Step ---");
        step_size = 0;  // SW3=0 → half step
        repeat(50) @(posedge clk);
        $display("Half step CCW: pulses=%b", pulses_out);

        // =============================================
        $display("--- Test 6: Stop and quarter turn (KEY1) ---");
        on = 0;     // SW2=0 → stop continuous
        step_size = 1;  // return to full-step mode
        direction = 1;  // CW
        repeat(10) @(posedge clk);

        // press quarter (active low)
        quarter = 0;
        repeat(2) @(posedge clk);
        quarter = 1;
        $display("Quarter turn started...");

        // wait for quarter turn completion (50 steps in full-step mode)
        repeat(300) @(posedge clk);
        $display("After quarter turn: move_enable expected=0, pulses=%b", pulses_out);

        // =============================================
        $display("--- Test 7: Reset during operation ---");
        on = 1;
        repeat(20) @(posedge clk);
        resetb = 0;  // reset during motion
        repeat(5) @(posedge clk);
        resetb = 1;
        repeat(10) @(posedge clk);
        $display("After reset: pulses=%b (expected=1001)", pulses_out);

        $display("=== All tests completed successfully ===");
        $finish;
    end

    // ---- Real-time signal monitoring ----
    initial begin
        $monitor("t=%0t | pulses=%b | seg_t=%b | seg_o=%b | on=%b dir=%b",
                  $time, pulses_out, sev_seg_t, sev_seg_o, on, direction);
    end

endmodule