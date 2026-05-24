// ============================================================
// Testbench: tb_button_one_pulse.sv
// בדיקה ויזואלית בגלים בלבד
//
// מה לבדוק בגלים:
//   1. לחיצה קצרה  → pulse עולה ל-1 למשך מחזור שעון אחד בלבד
//   2. לחיצה ארוכה → pulse עולה פעם אחת בלבד (לא נשאר גבוה)
//   3. שתי לחיצות  → שני פולסים נפרדים
//   4. reset        → pulse=0, button_prev=1 (ניתן לראות בגלים פנימיים)
// ============================================================

`timescale 1ns/1ps

module tb_button_one_pulse;

    reg  clk;
    reg  resetb;
    reg  button;
    wire pulse;

    button_one_pulse dut (
        .clk    (clk),
        .resetb (resetb),
        .button (button),
        .pulse  (pulse)
    );

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        // אתחול
        resetb = 0;
        button = 1;  // כפתור לא לחוץ (active low)
        repeat(5) @(posedge clk);

        resetb = 1;
        repeat(5) @(posedge clk);

        // --- לחיצה קצרה (3 clocks) ---
        button = 0;
        repeat(3) @(posedge clk);
        button = 1;
        repeat(15) @(posedge clk);

        // --- לחיצה ארוכה (20 clocks) ---
        button = 0;
        repeat(20) @(posedge clk);
        button = 1;
        repeat(15) @(posedge clk);

        // --- שתי לחיצות נפרדות ---
        button = 0;
        repeat(5) @(posedge clk);
        button = 1;
        repeat(15) @(posedge clk);

        button = 0;
        repeat(5) @(posedge clk);
        button = 1;
        repeat(15) @(posedge clk);

        // --- reset באמצע לחיצה ---
        button = 0;
        repeat(3) @(posedge clk);
        resetb = 0;
        repeat(5) @(posedge clk);
        resetb = 1;
        button = 1;
        repeat(10) @(posedge clk);

        $stop;
    end

endmodule