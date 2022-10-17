`default_nettype none

module top
#(
  parameter STARTUP_WAIT = 32'd10000000
)
(
    input clk,
    output ioSclk,
    output ioSdin,
    output ioCs,
    output ioDc,
    output ioReset
);
    wire [9:0] pixelAddress;
    reg [7:0] pixelData = 0;

    screen #(STARTUP_WAIT) scr(
        clk, 
        ioSclk, 
        ioSdin, 
        ioCs, 
        ioDc, 
        ioReset, 
        pixelAddress,
        pixelData
    );

    wire randomBit;

    lfsr #(
        .SEED(32'd1),
        .TAPS(32'h80000412),
        .NUM_BITS(32)
    ) l1(
        clk,
        randomBit
    );

    reg [3:0] tempBuffer = 0;
    always @(posedge clk) begin
        tempBuffer <= {tempBuffer[2:0], randomBit};
    end

    localparam NUM_BITS_STORAGE = 8 * 128;
    reg [NUM_BITS_STORAGE - 1:0] graphStorage = 0;
    
    reg [7:0] graphValue = 127;
    reg [6:0] graphColumnIndex = 0;
    reg [19:0] delayCounter = 0;

    always @(posedge clk) begin
        if (delayCounter == 20'd900000) begin
            if (tempBuffer != 4'd15)
                graphValue <= graphValue + tempBuffer - 8'd7;
            delayCounter <= 0;
            graphStorage[({3'd0, graphColumnIndex} << 3)+:8] <= graphValue;
            graphColumnIndex <= graphColumnIndex + 1;
        end
        else
            delayCounter <= delayCounter + 1;
    end

    wire [6:0] xCoord;
    wire [2:0] yCoord;
    assign xCoord = pixelAddress[6:0] + graphColumnIndex;
    assign yCoord = 3'd7-pixelAddress[9:7];

    wire [7:0] currentGraphValue;
    wire [5:0] maxYHeight;
    
    assign currentGraphValue = graphStorage[({3'd0,xCoord} << 3)+:8];
    assign maxYHeight = currentGraphValue[7:2];

    always @(posedge clk) begin
        pixelData[0] <= ({yCoord,3'd7} <= maxYHeight);
        pixelData[1] <= ({yCoord,3'd6} <= maxYHeight);
        pixelData[2] <= ({yCoord,3'd5} <= maxYHeight);
        pixelData[3] <= ({yCoord,3'd4} <= maxYHeight);
        pixelData[4] <= ({yCoord,3'd3} <= maxYHeight);
        pixelData[5] <= ({yCoord,3'd2} <= maxYHeight);
        pixelData[6] <= ({yCoord,3'd1} <= maxYHeight);
        pixelData[7] <= ({yCoord,3'd0} <= maxYHeight);
    end
endmodule
