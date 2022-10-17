module lfsrTest (
    input clk,
    output reg randomBit
);
  reg [4:0] sr = 5'b00001;

  always @(posedge clk) begin
    sr <= {sr[3:0], sr[4] ^ sr[1]};
    randomBit <= sr[4];
  end
endmodule

module test();
  reg clk = 0;
  wire l1Bit, l2Bit, l3Bit;

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h12),
    .NUM_BITS(5)
  ) l1(
    clk,
    l1Bit
  );

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h1B),
    .NUM_BITS(5)
  ) l2(
    clk,
    l2Bit
  );

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h1E),
    .NUM_BITS(5)
  ) l3(
    clk,
    l3Bit
  );

  wire randomBit;
  lfsrTest testLFSR (
    clk,
    randomBit
  );
  reg [2:0] tempBuffer = 0;
  reg [1:0] counter = 0;
  reg [2:0] value;

  always @(posedge clk) begin
    if (counter == 3) begin
        value <= tempBuffer;
    end
    counter <= counter + 1;
    tempBuffer <= {tempBuffer[1:0], randomBit};
  end

  always
    #1  clk = ~clk;

  initial begin
    #1000 $finish;
  end

  initial begin
    $dumpfile("lfsr.vcd");
    $dumpvars(0,test);
  end
endmodule