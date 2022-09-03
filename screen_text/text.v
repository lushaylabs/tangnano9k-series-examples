`default_nettype none

module textRow #(
    parameter ADDRESS_OFFSET = 8'd0
) (
    input clk,
    input [7:0] readAddress,
    output [7:0] outByte
);
    reg [7:0] textBuffer [15:0];
    integer i;
    initial begin
        for (i=0; i<15; i=i+1) begin
            textBuffer[i] = 0;
        end
        textBuffer[0] = "L";
        textBuffer[1] = "u";
        textBuffer[2] = "s";
        textBuffer[3] = "h";
        textBuffer[4] = "a";
        textBuffer[5] = "y";
        textBuffer[6] = " ";
        textBuffer[7] = "L";
        textBuffer[8] = "a";
        textBuffer[9] = "b";
        textBuffer[10] = "s";
        textBuffer[11] = "!";
    end

    assign outByte = textBuffer[(readAddress-ADDRESS_OFFSET)];
endmodule

module textEngine (
    input clk,
    input [9:0] pixelAddress,
    output [7:0] pixelData
);
    reg [7:0] fontBuffer [1519:0];
    initial $readmemh("font.hex", fontBuffer);

    wire [5:0] charAddress;
    wire [2:0] columnAddress;
    wire topRow;

    reg [7:0] outputBuffer;

    
    wire [7:0] charOutput, chosenChar;
    wire [7:0] charOutput1, charOutput2, charOutput3, charOutput4;

    textRow #(6'd0) t1(
        clk,
        charAddress,
        charOutput1
    );
    textRow #(6'd16) t2(
        clk,
        charAddress,
        charOutput2
    );
    textRow #(6'd32) t3(
        clk,
        charAddress,
        charOutput3
    );
    textRow #(6'd48) t4(
        clk,
        charAddress,
        charOutput4
    );

    always @(posedge clk) begin
        outputBuffer <= fontBuffer[((chosenChar-8'd32) << 4) + (columnAddress << 1) + (topRow ? 0 : 1)];
    end

    assign charAddress = {pixelAddress[9:8],pixelAddress[6:3]};
    assign columnAddress = pixelAddress[2:0];
    assign topRow = !pixelAddress[7];

    assign charOutput = (charAddress[5] && charAddress[4]) ? charOutput4 : ((charAddress[5]) ? charOutput3 : ((charAddress[4]) ? charOutput2 : charOutput1));    
    assign chosenChar = (charOutput >= 32 && charOutput <= 126) ? charOutput : 32;

    assign pixelData = outputBuffer;
endmodule