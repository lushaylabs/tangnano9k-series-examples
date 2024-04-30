`ifdef FORMAL
`default_nettype none
`endif

module counterM(
    input clk,
    output reg [7:0] counterValue = 0
);
    reg [32:0] clockCounter = 0;

    localparam WAIT_TIME = 27000000;

    always @(posedge clk) begin
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            counterValue <= counterValue + 1;
        end
        else
            clockCounter <= clockCounter + 1;
    end
endmodule

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
    input uartRx
);
    wire [9:0] pixelAddress;
    wire [7:0] textPixelData, progressPixelData, chosenPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput;

    wire uartByteReady;
    wire [7:0] uartDataIn;
    wire [7:0] charOut1, charOut2, charOut3;
    wire [1:0] rowNumber;

    wire [7:0] counterValue;

    wire sys_reset;
    assign sys_reset = 0;

    screen #(STARTUP_WAIT) scr(
        clk,
        sys_reset,
        ioSclk, 
        ioSdin, 
        ioCs, 
        ioDc, 
        ioReset, 
        pixelAddress,
        chosenPixelData
    );

    textEngine te(
        clk,
        sys_reset,
        pixelAddress,
        textPixelData,
        charAddress,
        charOutput
    );

    assign rowNumber = charAddress[5:4];

    uart u(
        clk,
        sys_reset,
        uartRx,
        uartByteReady,
        uartDataIn
    );

    uartTextRow row1(
        clk,
        uartByteReady,
        uartDataIn,
        charAddress[3:0],
        charOut1
    );

    counterM c(clk, counterValue);

    binaryRow row2(
        clk,
        counterValue,
        charAddress[3:0],
        charOut2
    );

    hexDecRow row3(
        clk,
        counterValue,
        charAddress[3:0],
        charOut3
    );

    progressRow row4(
        clk,
        sys_reset, 
        counterValue,
        pixelAddress,
        progressPixelData
    );

    always @(posedge clk) begin
        case (rowNumber)
            0: charOutput <= charOut1;
            1: charOutput <= charOut2;
            2: charOutput <= charOut3;
            3: charOutput <= "D";
        endcase
    end
    assign chosenPixelData = (rowNumber == 3) ? progressPixelData : textPixelData;
endmodule