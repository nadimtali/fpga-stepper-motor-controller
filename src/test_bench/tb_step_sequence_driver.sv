// ============================================================
// Testbench: tb_step_sequence_driver.sv
// בדיקה ויזואלית בגלים בלבד
//
// מה לבדוק בגלים:
//   1. reset → pulses_out=1001
//   2. move_enable=0 → pulses_out לא משתנה למרות ticks
//   3. Full step CW  → רצף:  1001→0101→0110→1010→1001...
//   4. Full step CCW → רצף:  1010→0110→0101→1001→1010...
//   5. Half step CW  → רצף:  1000→1001→0001→0101→0100→0110→0010→1010→1000...
//   6. Half step CCW → רצף:  1010→0010→0110→0100→0101→0001→1001→1000→1010...
// ============================================================

`timescale 1ns/1ps

module tb_step_sequence_driver;

    reg        clk;
    reg        resetb;
    reg        step_tick;
    reg        move_enable;
    reg        direction;
    reg        step_size;
    wire [3:0] pulses_out;

    step_sequence_driver dut (
        .clk        (clk),
        .resetb     (resetb),
        .step_tick  (step_tick),
        .move_enable(move_enable),
        .direction  (direction),
        .step_size  (step_size),
        .pulses_out (pulses_out)
    );

    // שעון 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // task: שליחת פולס step_tick אחד
    task send_tick;
        begin
            @(posedge clk); step_tick = 1;
            @(posedge clk); step_tick = 0;
            @(posedge clk);
        end
    endtask

    // task: reset
    task do_reset;
        begin
            resetb = 0;
            repeat(3) @(posedge clk);
            resetb = 1;
            @(posedge clk);
        end
    endtask

    initial begin
        // אתחול
        resetb      = 0;
        step_tick   = 0;
        move_enable = 0;
        direction   = 1;
        step_size   = 1;
        repeat(5) @(posedge clk);

        resetb = 1;
        repeat(5) @(posedge clk);

        // --- move_enable=0: ticks לא מזיזים ---
        move_enable = 0;
        send_tick; send_tick; send_tick;
        repeat(5) @(posedge clk);

        // --- Full step CW: 5 צעדים (מחזור + 1) ---
        move_enable = 1; direction = 1; step_size = 1;
        send_tick; send_tick; send_tick;
        send_tick; send_tick; // צעד 5 = חזרה לצעד 1
        repeat(5) @(posedge clk);

        // --- Full step CCW: 5 צעדים ---
        direction = 0; step_size = 1;
        do_reset;
        move_enable = 1;
        send_tick; send_tick; send_tick;
        send_tick; send_tick;
        repeat(5) @(posedge clk);

        // --- Half step CW: 9 צעדים (מחזור + 1) ---
        direction = 1; step_size = 0;
        do_reset;
        move_enable = 1;
        send_tick; send_tick; send_tick; send_tick;
        send_tick; send_tick; send_tick; send_tick;
        send_tick; // צעד 9 = חזרה לצעד 1
        repeat(5) @(posedge clk);

        // --- Half step CCW: 9 צעדים ---
        direction = 0; step_size = 0;
        do_reset;
        move_enable = 1;
        send_tick; send_tick; send_tick; send_tick;
        send_tick; send_tick; send_tick; send_tick;
        send_tick;
        repeat(5) @(posedge clk);

        $stop;
    end

endmodule