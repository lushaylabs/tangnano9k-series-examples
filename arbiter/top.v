`default_nettype none

module toHex(
    input clk,
    input [3:0] value,
    output reg [7:0] hexChar = "0"
);
    always @(posedge clk) begin
        hexChar <= (value <= 9) ? 8'd48 + value : 8'd55 + value;
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
    output ioReset
);
    wire enabled, readWrite;
    wire [31:0] dataToMem, dataFromMem;
    wire [7:0] address;

    wire req1, req2, req3;
    wire [2:0] grantedAccess;
    wire readWrite1, readWrite2, readWrite3;
    wire [31:0] currentMemVal, dataToMem2, dataToMem3;
    wire [7:0] address1, address2, address3;

    wire [9:0] pixelAddress;
    wire [7:0] textPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput;

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

    memController fc(
        clk,
        {req3,req2,req1},
        grantedAccess,
        enabled,
        address,
        dataToMem,
        readWrite,
        address1,
        address2,
        address3,
        0,
        dataToMem2,
        dataToMem3,
        readWrite1,
        readWrite2,
        readWrite3
    );

    sharedMemory sm(
        clk,
        address,
        readWrite,
        dataFromMem,
        dataToMem,
        enabled
    );

    memoryRead mr (
        clk,
        grantedAccess[0],
        req1,
        address1,
        readWrite1,
        dataFromMem,
        currentMemVal
    );

    memoryIncAtomic m1 (
        clk,
        grantedAccess[1],
        req2,
        address2,
        readWrite2,
        dataFromMem,
        dataToMem2
    );

    memoryIncAtomic m2 (
        clk,
        grantedAccess[2],
        req3,
        address3,
        readWrite3,
        dataFromMem,
        dataToMem3
    );

    wire [1:0] rowNumber;
    assign rowNumber = charAddress[5:4];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: hexVal 
            wire [7:0] hexChar;
            toHex converter(clk, currentMemVal[(i*4)+:4], hexChar);
        end
    endgenerate

    always @(posedge clk) begin
        if (rowNumber == 2'd0) begin
            case (charAddress[3:0])
                0: charOutput <= "0";
                1: charOutput <= "x";
                2: charOutput <= hexVal[7].hexChar;
                3: charOutput <= hexVal[6].hexChar;
                4: charOutput <= hexVal[5].hexChar;
                5: charOutput <= hexVal[4].hexChar;
                6: charOutput <= hexVal[3].hexChar;
                7: charOutput <= hexVal[2].hexChar;
                8: charOutput <= hexVal[1].hexChar;
                9: charOutput <= hexVal[0].hexChar;
                default: charOutput <= " ";
            endcase
        end
    end
endmodule