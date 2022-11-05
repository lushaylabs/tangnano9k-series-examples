`default_nettype none

module sharedMemory
(
    input clk,

    input [7:0] address,
    input readWrite,
    output reg [31:0] dataOut = 0,
    input [31:0] dataIn,
    input enabled
);
  reg [31:0] storage [255:0];
  integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      storage[i] = 0;
    end
  end

  always @(posedge clk) begin
    if (enabled) begin
      if (readWrite) begin
        dataOut <= storage[address];
      end
      else begin
        storage[address] <= dataIn;
      end
    end
  end
endmodule
