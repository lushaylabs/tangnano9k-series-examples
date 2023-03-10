module toDec(
    input clk,
    input [11:0] value,
    output reg [7:0] thousands = "0",
    output reg [7:0] hundreds = "0",
    output reg [7:0] tens = "0",
    output reg [7:0] units = "0"
);
    reg [15:0] digits = 0;
    reg [11:0] cachedValue = 0;
    reg [3:0] stepCounter = 0;
    reg [3:0] state = 0;

    localparam START_STATE = 0;
    localparam ADD3_STATE = 1;
    localparam SHIFT_STATE = 2;
    localparam DONE_STATE = 3;

    always @(posedge clk) begin
        case (state)
            START_STATE: begin
                cachedValue <= value;
                stepCounter <= 0;
                digits <= 0;
                state <= ADD3_STATE;
            end
            ADD3_STATE: begin
                digits <= digits + 
                    ((digits[7:4] >= 5) ? 16'd48 : 16'd0) + 
                    ((digits[3:0] >= 5) ? 16'd3 : 16'd0) + 
                    ((digits[11:8] >= 5) ? 16'd768 : 16'd0) + 
                    ((digits[15:12] >= 5) ? 16'd12288 : 16'd0);
                state <= SHIFT_STATE;
            end
            SHIFT_STATE: begin
                digits <= {digits[14:0],cachedValue[11] ? 1'b1 : 1'b0};
                cachedValue <= {cachedValue[10:0],1'b0};
                if (stepCounter == 11)
                    state <= DONE_STATE;
                else begin
                    state <= ADD3_STATE;
                    stepCounter <= stepCounter + 1;
                end
            end
            DONE_STATE: begin
                thousands <= 8'd48 + {4'd0, digits[15:12]};
                hundreds <= 8'd48 + {4'd0, digits[11:8]};
                tens <= 8'd48 + {4'd0, digits[7:4]};
                units <= 8'd48 + {4'd0, digits[3:0]};
                state <= START_STATE;
            end
        endcase
    end
endmodule
