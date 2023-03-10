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
    inout i2cSda,
    output i2cScl,
    input btn1
);
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

    wire [1:0] i2cInstruction;
    wire [7:0] i2cByteToSend;
    wire [7:0] i2cByteReceived;
    wire i2cComplete;
    wire i2cEnable;

    wire sdaIn;
    wire sdaOut;
    wire isSending;
    assign i2cSda = (isSending & ~sdaOut) ? 1'b0 : 1'bz;
    assign sdaIn = i2cSda ? 1'b1 : 1'b0;

    i2c c(
        clk,
        sdaIn,
        sdaOut,
        isSending,
        i2cScl,
        i2cInstruction,
        i2cEnable,
        i2cByteToSend,
        i2cByteReceived,
        i2cComplete
    );

    reg enableEdid = 0;
    wire edidDataReady;
    wire [7:0] edidDataOut;

    edid e(
        clk,
        enableEdid,
        edidDataReady,
        i2cInstruction,
        i2cEnable,
        i2cByteToSend,
        i2cByteReceived,
        i2cComplete,
        charAddress[3:0],
        charAddress[5:4],
        edidDataOut
    );


    localparam EDID_STATE_READ_BYTE = 0;
    localparam EDID_STATE_WAIT_FOR_START = 1;
    localparam EDID_STATE_WAIT_FOR_VALUE = 2;
    localparam EDID_STATE_DONE = 3;

    reg [1:0] edidState = EDID_STATE_READ_BYTE;
    
    always @(posedge clk) begin
        if (~btn1) begin
            edidState <= EDID_STATE_READ_BYTE;
            enableEdid <= 0;
        end
        else begin
            case (edidState)
                EDID_STATE_READ_BYTE: begin
                    enableEdid <= 1;
                    edidState <= EDID_STATE_WAIT_FOR_START;
                end
                EDID_STATE_WAIT_FOR_START: begin
                    if (~edidDataReady) begin
                        edidState <= EDID_STATE_WAIT_FOR_VALUE;
                    end
                end
                EDID_STATE_WAIT_FOR_VALUE: begin
                    if (edidDataReady) begin
                        edidState <= EDID_STATE_DONE;
                    end
                end
                EDID_STATE_DONE: begin
                    enableEdid <= 0;
                end
            endcase
        end
    end

    wire [1:0] rowNumber;
    assign rowNumber = charAddress[5:4];

    reg [(4*8-1):0] NAME = "Name";
    reg [(10*8-1):0] RESOLUTION = "Resolution";

    always @(posedge clk) begin
        if (rowNumber == 2'd0) begin
            case (charAddress[3:0])
                0,1,2,3: charOutput <= NAME[{2'd3-charAddress[1:0], 3'b000}+:8];
                default: charOutput <= " ";
            endcase
        end
        if (rowNumber == 2'd1) begin
            case (charAddress[3:0])
                13, 14, 15: charOutput <= " ";
                default: charOutput <= edidDataOut;
            endcase
        end
        else if (rowNumber == 2'd2) begin
            case (charAddress[3:0])
                0, 1, 2, 3, 4,
                5, 6, 7, 8, 9: charOutput <= RESOLUTION[{4'd9-charAddress[3:0], 3'b000}+:8];
                default: charOutput <= " ";
            endcase
        end
        else if (rowNumber == 2'd3) begin
            case (charAddress[3:0])
                4: charOutput <= "x";
                9: charOutput <= "p";
                10: charOutput <= "x";
                11: charOutput <= "@";
                14: charOutput <= "H";
                15: charOutput <= "z";
                default: charOutput <= edidDataOut;
            endcase
        end
    end
endmodule
