`default_nettype none

module i2c (
    input clk,
    input sdaIn,
    output reg sdaOutReg = 1,
    output reg isSending = 0,
    output reg scl = 1,
    input [1:0] instruction,
    input enable,
    input [7:0] byteToSend,
    output reg [7:0] byteReceived = 0,
    output reg complete
);
    localparam INST_START_TX = 0;
    localparam INST_STOP_TX = 1;
    localparam INST_READ_BYTE = 2;
    localparam INST_WRITE_BYTE = 3;
    localparam STATE_IDLE = 4;
    localparam STATE_DONE = 5;
    localparam STATE_SEND_ACK = 6;
    localparam STATE_RCV_ACK = 7;

    reg [6:0] clockDivider = 0;

    reg [2:0] state = STATE_IDLE;
    reg [2:0] bitToSend = 0;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                if (enable) begin
                    complete <= 0;
                    clockDivider <= 0;
                    bitToSend <= 0;
                    state <= {1'b0,instruction};
                end
            end
            INST_START_TX: begin
                isSending <= 1;
                clockDivider <= clockDivider + 1;
                if (clockDivider[6:5] == 2'b00) begin
                    scl <= 1;
                    sdaOutReg <= 1;
                end else if (clockDivider[6:5] == 2'b01) begin
                    sdaOutReg <= 0;
                end else if (clockDivider[6:5] == 2'b10) begin
                    scl <= 0;
                end else if (clockDivider[6:5] == 2'b11) begin
                    state <= STATE_DONE;
                end
            end
            INST_STOP_TX: begin
                isSending <= 1;
                clockDivider <= clockDivider + 1;
                if (clockDivider[6:5] == 2'b00) begin
                    scl <= 0;
                    sdaOutReg <= 0;
                end else if (clockDivider[6:5] == 2'b01) begin
                    scl <= 1;
                end else if (clockDivider[6:5] == 2'b10) begin
                    sdaOutReg <= 1;
                end else if (clockDivider[6:5] == 2'b11) begin
                    state <= STATE_DONE;
                end
            end
            INST_READ_BYTE: begin
                isSending <= 0;
                clockDivider <= clockDivider + 1;
                if (clockDivider[6:5] == 2'b00) begin
                    scl <= 0;
                end else if (clockDivider[6:5] == 2'b01) begin
                    scl <= 1;
                end else if (clockDivider == 7'b1000000) begin
                    byteReceived <= {byteReceived[6:0], sdaIn ? 1'b1 : 1'b0};
                end else if (clockDivider == 7'b1111111) begin
                    bitToSend <= bitToSend + 1;
                    if (bitToSend == 3'b111) begin
                        state <= STATE_SEND_ACK;
                    end
                end else if (clockDivider[6:5] == 2'b11) begin
                    scl <= 0;
                end
            end
            STATE_SEND_ACK: begin
                isSending <= 1;
                sdaOutReg <= 0;
                clockDivider <= clockDivider + 1;
                if (clockDivider[6:5] == 2'b01) begin
                    scl <= 1;
                end else if (clockDivider == 7'b1111111) begin
                    state <= STATE_DONE;
                end else if (clockDivider[6:5] == 2'b11) begin
                    scl <= 0;
                end
            end
            INST_WRITE_BYTE: begin
                isSending <= 1;
                clockDivider <= clockDivider + 1;
                sdaOutReg <= byteToSend[3'd7-bitToSend] ? 1'b1 : 1'b0;

                if (clockDivider[6:5] == 2'b00) begin
                    scl <= 0;
                end else if (clockDivider[6:5] == 2'b01) begin
                    scl <= 1;
                end else if (clockDivider == 7'b1111111) begin
                    bitToSend <= bitToSend + 1;
                    if (bitToSend == 3'b111) begin
                        state <= STATE_RCV_ACK;
                    end
                end else if (clockDivider[6:5] == 2'b11) begin
                    scl <= 0;
                end
            end
            STATE_RCV_ACK: begin
                isSending <= 0;
                clockDivider <= clockDivider + 1;

                if (clockDivider[6:5] == 2'b01) begin
                    scl <= 1;
                end else if (clockDivider == 7'b1111111) begin
                    state <= STATE_DONE;
                end else if (clockDivider[6:5] == 2'b11) begin
                    scl <= 0;
                end
                // else if (clockDivider == 7'b1000000) begin
                //     sdaIn should be 0
                // end 
            end
            STATE_DONE: begin
                complete <= 1;
                if (~enable)
                    state <= STATE_IDLE;
            end
        endcase
    end
endmodule
