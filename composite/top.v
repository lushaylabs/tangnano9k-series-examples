module top(
    input refclk,
    output reg output_270ohm = 0,
    output reg output_330ohm = 0,
    output reg output_470ohm = 0
);

    wire hsync;
    wire vsync;
    wire hblank;
    wire vblank;
    wire active_video;
    wire [9:0] y;

    composite_count_test cc(
        .clk(refclk),
        .hsync(hsync),
        .vsync(vsync),
        .hblank(hblank),
        .vblank(vblank),
        .active_video(active_video),
        .y(y)
    );

    reg [7:0] xCounter = 0;
    always @(posedge refclk) begin
        if (hsync)
            xCounter <= 0;
        else 
            xCounter <= xCounter + 1;
    end

    always @(posedge refclk) begin
        if (hsync | vsync) begin
            output_270ohm <= 0;
            output_330ohm <= 0;
            output_470ohm <= 0;
        end
        else if (hblank | vblank) begin
            output_270ohm <= 0;
            output_330ohm <= 0;
            output_470ohm <= 1;
        end
        else if (active_video) begin
            case ({y[4], xCounter[6]})
                2'b00: begin
                    output_270ohm <= 0;
                    output_330ohm <= 0;
                    output_470ohm <= 1;
                end
                2'b01: begin
                    output_270ohm <= 1;
                    output_330ohm <= 0;
                    output_470ohm <= 0;
                end
                2'b10: begin
                    output_270ohm <= 0;
                    output_330ohm <= 1;
                    output_470ohm <= 1;
                end
                2'b11: begin
                    output_270ohm <= 1;
                    output_330ohm <= 1;
                    output_470ohm <= 0;
                end
            endcase
        end
    end
endmodule