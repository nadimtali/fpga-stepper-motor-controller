// ============================================================
// Testbench: tb_step_motor_top.sv
// בדיקה ויזואלית בגלים בלבד - Integration Test
//
// מה לבדוק בגלים:
//   1. reset → sev_seg_t='1' sev_seg_o='0' (10 RPM), pulses_out=1001
//   2. לחיצת KEY3 → sev_seg_t מתעדכן ל-'2' (20 RPM)
//   3. 4 לחיצות נוספות → sev_seg_t='6' (60 RPM)
//   4. on=1, CW, full step → pulses_out משתנה ברצף CW כל 250K clocks
//   5. on=0 → pulses_out מפסיק להשתנות
//   6. direction=0 (CCW) → רצף הפוך ב-pulses_out
//   7. step_size=0 (half) → pulses_out משתנה בתדר כפול
//   8. KEY1 (quarter) → pulses_out פעיל 50 ticks ואז עוצר
//   9. reset → חזרה ל-10 RPM בתצוגה
//
// הערה: KEY3 ו-KEY1 הם active low (0=לחוץ)
// ============================================================

`timescale 1ns/1ps

module tb_step_motor_top;

    reg        clk;
    reg        resetb;
    reg        direction;
    reg        speed_sel; // KEY3 - active low
    reg        on;
    reg        quarter;   // KEY1 - active low
    reg        step_size;
    wire [6:0] sev_seg_o;
    wire [6:0] sev_seg_t;
    wire [3:0] pulses_out;

    step_motor_top dut (
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

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // task: לחיצת KEY3 (speed_sel) - active low
    task press_key3;
        begin
            speed_sel = 0;
            repeat(5) @(posedge clk);
            speed_sel = 1;
            repeat(10) @(posedge clk);
        end
    endtask

    // task: לחיצת KEY1 (quarter) - active low
    task press_key1;
        begin
            quarter = 0;
            repeat(5) @(posedge clk);
            quarter = 1;
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        // אתחול: כפתורים לא לחוצים = 1 (active low)
        resetb    = 0;
        direction = 1;
        speed_sel = 1;
        on        = 0;
        quarter   = 1;
        step_size = 1;
        repeat(10) @(posedge clk);

        resetb = 1;
        repeat(5) @(posedge clk);

        // --- לחיצת KEY3: RPM 10→20→30→40→50→60 ---
        press_key3; // 20
        press_key3; // 30
        press_key3; // 40
        press_key3; // 50
        press_key3; // 60
        repeat(5) @(posedge clk);

        // --- on=1, CW, full step, 60 RPM → מנוע פועל ---
        on = 1;
        repeat(800_000) @(posedge clk); // ~3 צעדים
        on = 0;
        repeat(10) @(posedge clk);

        // --- CCW direction ---
        direction = 0;
        on = 1;
        repeat(800_000) @(posedge clk);
        on = 0;
        direction = 1;
        repeat(10) @(posedge clk);

        // --- Half step ---
        step_size = 0;
        on = 1;
        repeat(400_000) @(posedge clk); // period=125K, ~3 צעדים
        on = 0;
        step_size = 1;
        repeat(10) @(posedge clk);

        // --- Quarter rotation (KEY1), full step, 60 RPM ---
        // 50 צעדים × 250,000 = 12,500,000 clocks
        press_key1;
        repeat(13_000_000) @(posedge clk);

        // --- reset ---
        on = 1;
        repeat(5) @(posedge clk);
        resetb = 0;
        repeat(5) @(posedge clk);
        resetb = 1;
        repeat(10) @(posedge clk);

        $stop;
    end

endmodule