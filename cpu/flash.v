`default_nettype none

module flash
#(
  parameter STARTUP_WAIT = 32'd10000000
)
(
    input clk,
    output reg flashClk = 0,
    input flashMiso,
    output reg flashMosi = 0,
    output reg flashCs = 1,
    input [10:0] addr,
    output reg [7:0] byteRead = 0,
    input enable,
    output reg dataReady = 0
);

  reg [7:0] command = 8'h03;
  reg [7:0] currentByteOut = 0;

  localparam STATE_INIT_POWER = 8'd0;
  localparam STATE_LOAD_CMD_TO_SEND = 8'd1;
  localparam STATE_SEND = 8'd2;
  localparam STATE_LOAD_ADDRESS_TO_SEND = 8'd3;
  localparam STATE_READ_DATA = 8'd4;
  localparam STATE_DONE = 8'd5;

  reg [23:0] dataToSend = 0;
  reg [8:0] bitsToSend = 0;

  reg [32:0] counter = 0;
  reg [2:0] state = 0;
  reg [2:0] returnState = 0;

  always @(posedge clk) begin
    case (state)
      STATE_INIT_POWER: begin
        if (counter < STARTUP_WAIT)
          counter <= counter + 1;
        else if (enable) begin
          state <= STATE_LOAD_CMD_TO_SEND;
          counter <= 32'b0;
          dataReady <= 0;
          currentByteOut <= 0;
        end
      end
      STATE_LOAD_CMD_TO_SEND: begin
          flashCs <= 0;
          dataToSend[23-:8] <= command;
          bitsToSend <= 8;
          state <= STATE_SEND;
          returnState <= STATE_LOAD_ADDRESS_TO_SEND;
      end
      STATE_SEND: begin
        if (counter == 32'd0) begin
          flashClk <= 0;
          flashMosi <= dataToSend[23];
          dataToSend <= {dataToSend[22:0],1'b0};
          bitsToSend <= bitsToSend - 1;
          counter <= 1;
        end
        else begin
          counter <= 32'd0;
          flashClk <= 1;
          if (bitsToSend == 0)
            state <= returnState;
        end
      end
      STATE_LOAD_ADDRESS_TO_SEND: begin
        dataToSend <= {13'b0,addr};
        bitsToSend <= 24;
        state <= STATE_SEND;
        returnState <= STATE_READ_DATA;
      end
      STATE_READ_DATA: begin
        if (counter[0] == 1'd0) begin
          flashClk <= 0;
          counter <= counter + 1;
          if (counter[3:0] == 0 && counter > 0) begin
            byteRead <= currentByteOut;
            state <= STATE_DONE;
          end
        end
        else begin
          flashClk <= 1;
          currentByteOut <= {currentByteOut[6:0], flashMiso};
          counter <= counter + 1;
        end
      end
      STATE_DONE: begin
        dataReady <= 1;
        flashCs <= 1;
        counter <= STARTUP_WAIT;
        if (~enable) begin 
          state <= STATE_INIT_POWER;
        end
      end
    endcase
  end
endmodule
