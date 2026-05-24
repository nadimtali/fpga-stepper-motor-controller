// ============================================================
// Testbench: tb_speed_display.sv
// בדיקה ויזואלית בגלים בלבד
// מודול combinational - אין שעון
//
// מה לבדוק בגלים:
//   לכל ערך RPM: sev_seg_t (עשרות) ו-sev_seg_o (יחידות=תמיד 1000000)
//   10  → sev_seg_t=1111001 ('1')
//   20  → sev_seg_t=0100100 ('2')
//   30  → sev_seg_t=0110000 ('3')
//   40  → sev_seg_t=0011001 ('4')
//   50  → sev_seg_t=0010010 ('5')
//   60  → sev_seg_t=0000010 ('6')
//   ערך לא חוקי → sev_seg_t=1111111 (כבוי)
// ============================================================

`timescale 1ns/1ps

module tb_speed_display;

    reg  [5:0] speed_rpm;
    wire [6:0] sev_seg_t;
    wire [6:0] sev_seg_o;

    speed_display dut (
        .speed_rpm (speed_rpm),
        .sev_seg_t (sev_seg_t),
        .sev_seg_o (sev_seg_o)
    );

    initial begin
        speed_rpm = 6'd10;  #20;
        speed_rpm = 6'd20;  #20;
        speed_rpm = 6'd30;  #20;
        speed_rpm = 6'd40;  #20;
        speed_rpm = 6'd50;  #20;
        speed_rpm = 6'd60;  #20;

        // ערך לא חוקי → תצוגה כבויה
        speed_rpm = 6'd15;  #20;

        $stop;
    end

endmodule