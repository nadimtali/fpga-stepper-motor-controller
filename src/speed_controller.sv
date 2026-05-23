module speed_controller (
    input  wire       clk,
    input  wire       resetb,
    input  wire       speed_pulse,
    output reg  [5:0] speed_rpm
);

    // Indicates whether the speed should increase or decrease
    reg up_direction;

    // Speed controller:
    // After reset, the speed starts at 10 RPM.
    // Each speed_pulse changes the speed by 10 RPM.
    // The speed increases up to 60 RPM, then decreases back to 10 RPM.
    always @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            speed_rpm    <= 6'd10;  // Initial speed after reset
            up_direction <= 1'b1;   // Start by increasing the speed
        end else begin
            if (speed_pulse) begin

                // Increasing speed mode
                if (up_direction) begin
                    if (speed_rpm == 6'd60) begin
                        speed_rpm    <= 6'd50; // Start decreasing after reaching 60 RPM
                        up_direction <= 1'b0;
                    end else begin
                        speed_rpm <= speed_rpm + 6'd10;
                    end

                // Decreasing speed mode
                end else begin
                    if (speed_rpm == 6'd10) begin
                        speed_rpm    <= 6'd20; // Start increasing after reaching 10 RPM
                        up_direction <= 1'b1;
                    end else begin
                        speed_rpm <= speed_rpm - 6'd10;
                    end
                end
            end
        end
    end

endmodule