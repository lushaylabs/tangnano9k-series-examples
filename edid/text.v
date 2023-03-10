`default_nettype none

module textEngine (
    input clk,
    input [9:0] pixelAddress,
    output [7:0] pixelData,
    output [5:0] charAddress,
    input [7:0] charOutput
);
    reg [7:0] fontBuffer [1519:0];
    initial $readmemh("font.hex", fontBuffer);

    wire [2:0] columnAddress;
    wire topRow;

    reg [7:0] outputBuffer;
    wire [7:0] chosenChar;

    always @(posedge clk) begin
        outputBuffer <= fontBuffer[((chosenChar-8'd32) << 4) + (columnAddress << 1) + (topRow ? 0 : 1)];
    end

    assign charAddress = {pixelAddress[9:8],pixelAddress[6:3]};
    assign columnAddress = pixelAddress[2:0];
    assign topRow = !pixelAddress[7];

    assign chosenChar = (charOutput >= 32 && charOutput <= 126) ? charOutput : 32;
    assign pixelData = outputBuffer;
endmodule