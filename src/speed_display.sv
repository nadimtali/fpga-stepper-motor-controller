// ============================================================
// Module: speed_display
// Description: Converts the RPM value (10-60) to 7-segment display outputs.
//              sev_seg_t -> HEX1 (tens digit)
//              sev_seg_o -> HEX0 (ones digit)
//              Encoding: active low (0 = segment ON)
//              Segment order: bit[6:0] = gfedcba
// ============================================================

module speed_display (
    input  wire [5:0] speed_rpm,  // current speed (10-60 RPM)
    output reg  [6:0] sev_seg_t,  // HEX1 - tens digit
    output reg  [6:0] sev_seg_o   // HEX0 - ones digit
);

    // ----  7-segment encoding (active low, common anode) ----
    // segments: gfedcba
    //   0 → 1000000
    //   1 → 1111001
    //   2 → 0100100
    //   3 → 0110000
    //   4 → 0011001
    //   5 → 0010010
    //   6 → 0000010

    // The ones digit is always 0 because RPM = 10,20,...,60
    // The tens digit is 1,2,3,4,5,6

    always @(*) begin
        // Ones digit - always "0"
        sev_seg_o = 7'b1000000;

        // Tens digit - according to the RPM value
        case (speed_rpm)
            6'd10: sev_seg_t = 7'b1111001;  // "1"
            6'd20: sev_seg_t = 7'b0100100;  // "2"
            6'd30: sev_seg_t = 7'b0110000;  // "3"
            6'd40: sev_seg_t = 7'b0011001;  // "4"
            6'd50: sev_seg_t = 7'b0010010;  // "5"
            6'd60: sev_seg_t = 7'b0000010;  // "6"
            default: sev_seg_t = 7'b1111111; // display off
        endcase
    end

endmodule