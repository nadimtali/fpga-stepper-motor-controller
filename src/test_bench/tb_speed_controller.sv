// ============================================================
// Testbench: tb_speed_controller.sv
// בדיקה ויזואלית בגלים בלבד
//
// מה לבדוק בגלים:
//   1. לאחר reset: speed_rpm=10
//   2. כל speed_pulse: speed_rpm עולה ב-10 (10→20→...→60)
//   3. ב-60: פולס נוסף → ירידה ל-50 (כיוון מתהפך)
//   4. ירידה עד 10: פולס נוסף → עלייה חזרה ל-20
//   5. reset באמצע → חזרה ל-10
// ============================================================

`timescale 1ns/1ps

module tb_speed_controller;

    reg        clk;
    reg        resetb;
    reg        speed_pulse;
    wire [5:0] speed_rpm;

    speed_controller dut (
        .clk         (clk),
        .resetb      (resetb),
        .speed_pulse (speed_pulse),
        .speed_rpm   (speed_rpm)
    );

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // task: פולס שינוי מהירות - רוחב מחזור שעון אחד
    task send_pulse;
        begin
            @(posedge clk);
            speed_pulse = 1;
            @(posedge clk);
            speed_pulse = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        // אתחול
        resetb      = 0;
        speed_pulse = 0;
        repeat(5) @(posedge clk);

        resetb = 1;
        repeat(5) @(posedge clk);

        // --- עלייה: 10 → 60 (5 פולסים) ---
        send_pulse; // 20
        send_pulse; // 30
        send_pulse; // 40
        send_pulse; // 50
        send_pulse; // 60
        repeat(5) @(posedge clk);

        // --- ב-60: פולס נוסף → ירידה ל-50 ---
        send_pulse;
        repeat(5) @(posedge clk);

        // --- ירידה: 50 → 10 (4 פולסים) ---
        send_pulse; // 40
        send_pulse; // 30
        send_pulse; // 20
        send_pulse; // 10
        repeat(5) @(posedge clk);

        // --- ב-10: פולס נוסף → עלייה ל-20 ---
        send_pulse;
        repeat(5) @(posedge clk);

        // --- reset באמצע ---
        send_pulse; // 30
        send_pulse; // 40
        repeat(3) @(posedge clk);
        resetb = 0;
        repeat(5) @(posedge clk);
        resetb = 1;
        repeat(5) @(posedge clk);

        $stop;
    end

endmodule