
module top(
    input  wire       clk,           // Board 27MHz clock
    output reg  [3:0] ADDR  = 4'd0,  // A B C and D pins (address pins) counts from 0 up to PIXEL_LINES-1 (2 groups of PIXEL_LINES lines)
    output reg        OE    = 1'd1,  // OUTPUT ENABLE pin, drives the display intensity
    output reg        LATCH = 1'd0,  // LATCH pin (HIGH every time the line is filled, LOW elsewhere)
    output wire [2:0] RGB0,          // R0, G0 and B0 pins - lines  0 to PIXEL_LINES-1
    output wire [2:0] RGB1,          // R1, G1 and B1 pins - lines PIXEL_LINES to 2*PIXEL_LINES-1
    output reg        clk_out = 1'd0 // output clock pin (needs to cycle PIXEL_COLUMNS times until reset column count)
);

    localparam PIXEL_COLUMNS = 64;
    localparam BRIGHNESS = 5'd31;

    reg [6:0] pixelCounter = 7'd0;
    reg [4:0] displayCounter = 5'd0;


    wire clk_master;
    clock_divisor clkdiv(.clk(clk), .clk_out(clk_master));

    reg [1:0] colorCycle = 2'd0;
    framebuffer2Bit buffer(
        .clk(clk), 
        .column(pixelCounter[5:0]),
        .ADDR(ADDR),
        .RGB0(RGB0),
        .RGB1(RGB1),
        .colorCycle(colorCycle)
    );

    localparam SHIFT_DATA = 0;
    localparam LATCH_DATA = 1;
    localparam SHOW_PIXELS = 2;
    localparam SHIFT_ADDR = 3;

    reg [1:0] state = SHIFT_DATA;

    always @(posedge clk_master) begin
        case(state)
            SHIFT_DATA: begin
                if (~clk_out) begin
                    clk_out <= 1'd1;
                end else begin
                    clk_out <= 1'd0;
                    if (pixelCounter == PIXEL_COLUMNS-1) begin
                        state <= LATCH_DATA;
                    end else begin
                        pixelCounter <= pixelCounter + 7'd1;
                    end
                end
            end
            LATCH_DATA: begin
                if (~LATCH) begin
                    LATCH <= 1'd1;
                end else begin
                    LATCH <= 1'd0;
                    OE <= 1'd0;
                    state <= SHOW_PIXELS;
                end
            end
            SHOW_PIXELS: begin
                displayCounter <= displayCounter + 5'd1;
                if (displayCounter == BRIGHNESS) begin
                    OE <= 1'd1;
                    displayCounter <= 5'd0;
                    state <= SHIFT_ADDR;
                end
            end
            SHIFT_ADDR: begin
                ADDR <= ADDR + 4'd1;
                pixelCounter <= 7'd0;
                state <= SHIFT_DATA;
                if (ADDR == 4'd15) begin
                    colorCycle <= colorCycle + 2'd1;
                    if (colorCycle == 2'd2) begin
                        colorCycle <= 2'd0;
                    end
                end
            end
        endcase
    end
endmodule

