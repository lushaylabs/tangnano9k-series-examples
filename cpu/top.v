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
    output ioReset,
    output flashClk,
    input flashMiso,
    output flashMosi,
    output flashCs,
    input btn1,
    input btn2,
    output [5:0] led
);
    reg btn1Reg = 1, btn2Reg = 1;
    always @(negedge clk) begin
        btn1Reg <= btn1 ? 0 : 1;
        btn2Reg <= btn2 ? 0 : 1;
    end

    wire [9:0] pixelAddress;
    wire [7:0] textPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput = "A";

    screen #(STARTUP_WAIT) scr(
        clk, 
        ioSclk, 
        ioSdin, 
        ioCs, 
        ioDc, 
        ioReset, 
        pixelAddress,
        textPixelData
    );

    textEngine te(
        clk,
        pixelAddress,
        textPixelData,
        charAddress,
        charOutput
    );

    wire [10:0] flashReadAddr;
    wire [7:0] byteRead;
    wire enableFlash;
    wire flashDataReady;

    flash externalFlash(
        clk,
        flashClk,
        flashMiso,
        flashMosi,
        flashCs,
        flashReadAddr,
        byteRead,
        enableFlash,
        flashDataReady
    );

    wire [7:0] cpuChar;
    wire [5:0] cpuCharIndex;
    wire writeScreen;

    cpu c(
        clk,
        flashReadAddr,
        byteRead,
        enableFlash,
        flashDataReady,
        led,
        cpuChar,
        cpuCharIndex,
        writeScreen,
        btn1Reg,
        btn2Reg
    );

    reg [511:0] screenBuffer = 0;
    always @(posedge clk) begin
        if (writeScreen)
            screenBuffer[{cpuCharIndex, 3'b0}+:8] <= cpuChar;
        else
            charOutput <= screenBuffer[{charAddress, 3'b0}+:8];
    end
endmodule

