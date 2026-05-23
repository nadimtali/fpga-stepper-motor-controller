// ============================================================
// Module: button_one_pulse
// Description: Generates a single short pulse when a push button is pressed.
//              Converts a long button press into a one-shot pulse.
//              Used for speed_sel (KEY3) and quarter (KEY1).
// ============================================================

module button_one_pulse (
    input  wire clk,      // 50 MHz system clock
    input  wire resetb,   // active-low reset
    input  wire button,   // button input (active low - 0 when pressed)
    output wire pulse     // single pulse when the button is pressed
);

    // Registers for detecting button state transitions
    reg button_prev;   // button state in the previous clock cycle
    reg button_sync1;  // first synchronization stage (metastability protection)
    reg button_sync2;  // second synchronization stage - stable value

    // Step 1: synchronize the input to the system clock (2-FF synchronizer)
    always @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            button_sync1 <= 1'b1;
            button_sync2 <= 1'b1;
        end else begin
            button_sync1 <= button;
            button_sync2 <= button_sync1;
        end
    end

    // Step 2: store the previous state for edge detection
    always @(posedge clk or negedge resetb) begin
        if (!resetb)
            button_prev <= 1'b1;
        else
            button_prev <= button_sync2;
    end

    // Generate a pulse only on the 1-to-0 transition (active-low press)
    assign pulse = button_prev & (~button_sync2);

endmodule