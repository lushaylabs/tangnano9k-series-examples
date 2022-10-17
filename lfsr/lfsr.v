`default_nettype none

module lfsr
#(
  parameter SEED = 5'd1,
  parameter TAPS = 5'h1B,
  parameter NUM_BITS = 5
)
(
    input clk,
    output reg randomBit
);
  reg [NUM_BITS-1:0] sr = SEED;

  genvar i;
  generate
    for (i = 0; i < NUM_BITS; i = i + 1) begin: lf
      wire feedback;
      if (i == 0)
        assign feedback = sr[i] & TAPS[i];
      else
       assign feedback = lf[i-1].feedback ^ (sr[i] & TAPS[i]);
    end
  endgenerate

  wire finalFeedback;
  assign finalFeedback = lf[NUM_BITS-1].feedback;

  always @(posedge clk) begin
    sr <= {sr[NUM_BITS-2:0],finalFeedback};
    randomBit <= sr[NUM_BITS-1];
  end
endmodule
