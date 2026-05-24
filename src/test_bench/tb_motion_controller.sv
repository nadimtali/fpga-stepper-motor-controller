// ============================================================
// Testbench: tb_motion_controller.sv
// בדיקה ויזואלית בגלים בלבד
//
// מה לבדוק בגלים:
//   1. reset → move_enable=0, state=IDLE
//   2. on=1 → move_enable=1 (RUNNING)
//   3. on=0 → move_enable=0 (חזרה ל-IDLE)
//   4. quarter_pulse + full step → move_enable=1 למשך 50 ticks בדיוק
//   5. quarter_pulse + half step → move_enable=1 למשך 100 ticks בדיוק
//   6. quarter_pulse שני בזמן QUARTER → לא מאפס את המונה
// ============================================================

`timescale 1ns/1ps

module tb_motion_controller;

    reg  clk;
    reg  resetb;
    reg  on;
    reg  step_size;
    reg  quarter_pulse;
    reg  step_tick;
    wire move_enable;

    motion_controller dut (
        .clk          (clk),
        .resetb       (resetb),
        .on           (on),
        .step_size    (step_size),
        .quarter_pulse(quarter_pulse),
        .step_tick    (step_tick),
        .move_enable  (move_enable)
    );

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // task: N פולסי step_tick
    task send_ticks;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk); step_tick = 1;
                @(posedge clk); step_tick = 0;
            end
            @(posedge clk);
        end
    endtask

    // task: quarter_pulse יחיד
    task send_quarter;
        begin
            @(posedge clk); quarter_pulse = 1;
            @(posedge clk); quarter_pulse = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        // אתחול
        resetb        = 0;
        on            = 0;
        step_size     = 1;
        quarter_pulse = 0;
        step_tick     = 0;
        repeat(5) @(posedge clk);

        resetb = 1;
        repeat(5) @(posedge clk);

        // --- on=1 → RUNNING ---
        on = 1;
        repeat(5) @(posedge clk);

        // --- on=0 → IDLE ---
        on = 0;
        repeat(5) @(posedge clk);

        // --- Full step quarter: 50 ticks → עצירה ---
        step_size = 1;
        send_quarter;
        send_ticks(50); // אחרי 50 ticks: move_enable חוזר ל-0
        repeat(5) @(posedge clk);

        // --- Half step quarter: 100 ticks → עצירה ---
        step_size = 0;
        send_quarter;
        send_ticks(100);
        repeat(5) @(posedge clk);

        // --- quarter שני באמצע QUARTER (לא מאפס) ---
        step_size = 1;
        send_quarter;         // מתחיל רבע סיבוב
        send_ticks(25);       // באמצע
        send_quarter;         // לחיצה שנייה - אמורה להתעלם
        send_ticks(25);       // ממשיך - צריך לעצור אחרי 50 סה"כ
        repeat(5) @(posedge clk);

        $stop;
    end

endmodule