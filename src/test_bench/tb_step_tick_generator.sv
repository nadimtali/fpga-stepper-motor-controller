// ============================================================
// Testbench: tb_step_tick_generator.sv
// בדיקה ויזואלית בגלים בלבד
//
// מה לבדוק בגלים:
//   1. Full step, 60 RPM → step_tick עולה כל 250,000 clocks
//   2. Half step, 60 RPM → step_tick עולה כל 125,000 clocks (כפול מהר)
//   3. Full step, 10 RPM → step_tick עולה כל 1,500,000 clocks (איטי)
//   4. reset → step_tick=0, counter=0
//
// טיפ: בגלים השתמש ב-divider כדי לקרוא את ה-period בין פולסים
// ============================================================

`timescale 1ns/1ps

module tb_step_tick_generator;

    reg        clk;
    reg        resetb;
    reg  [5:0] speed_rpm;
    reg        step_size;
    wire       step_tick;

    step_tick_generator #(.CLK_FREQ(50_000_000)) dut (
        .clk       (clk),
        .resetb    (resetb),
        .speed_rpm (speed_rpm),
        .step_size (step_size),
        .step_tick (step_tick)
    );

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        // אתחול
        resetb    = 0;
        speed_rpm = 6'd60;
        step_size = 1;
        repeat(5) @(posedge clk);

        resetb = 1;
        repeat(3) @(posedge clk);

        // --- Full step, 60 RPM: period=250,000 clocks ---
        // ממתינים לשני פולסים כדי לראות את ה-period בגלים
        step_size = 1;
        speed_rpm = 6'd60;
        repeat(600_000) @(posedge clk);

        // --- Half step, 60 RPM: period=125,000 clocks ---
        // period קטן בחצי - הפולסים מגיעים בתדר כפול
        step_size = 0;
        speed_rpm = 6'd60;
        repeat(400_000) @(posedge clk);

        // --- Full step, 10 RPM: period=1,500,000 clocks ---
        // הכי איטי - period גדול פי 6 מ-60 RPM
        step_size = 1;
        speed_rpm = 6'd10;
        repeat(3_200_000) @(posedge clk);

        // --- reset באמצע ---
        resetb = 0;
        repeat(5) @(posedge clk);
        resetb = 1;
        repeat(300_000) @(posedge clk);

        $stop;
    end

endmodule