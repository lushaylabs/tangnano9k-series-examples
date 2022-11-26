module test();

reg clk = 0;

always
    #1  clk = ~clk;

wire [1:0] i2cInstruction;
wire [7:0] i2cByteToSend;
wire [7:0] i2cByteReceived;
wire i2cComplete;
wire i2cEnable;

wire i2cSda;

wire i2cScl;
wire sdaIn;
wire sdaOut;
wire isSending;
assign i2cSda = (isSending & ~sdaOut) ? 1'b0 : 1'b1;
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

reg [1:0] adcChannel = 0;
wire [15:0] adcOutputData;
wire adcDataReady;
reg adcEnable = 1;

adc #(7'b1001001) a(
    clk,
    adcChannel,
    adcOutputData,
    adcDataReady,
    adcEnable,
    i2cInstruction,
    i2cEnable,
    i2cByteToSend,
    i2cByteReceived,
    i2cComplete
);

initial begin
    #100000 $finish;
end
    

initial begin
    $dumpfile("adc.vcd");
    $dumpvars(0,test);
end
endmodule