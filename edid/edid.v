
module edid (
    input clk,
    input enable,
    output reg dataReady = 1,
    output reg [1:0] instructionI2C = 0,
    output reg enableI2C = 0,
    output reg [7:0] byteToSendI2C = 0,
    input [7:0] byteReceivedI2C,
    input completeI2C,
    input [3:0] charIndex,
    input [1:0] rowIndex,
    output reg [7:0] edidDataOut = 0
);

localparam INST_START_TX = 0;
localparam INST_STOP_TX = 1;
localparam INST_READ_BYTE = 2;
localparam INST_WRITE_BYTE = 3;

localparam STATE_IDLE = 0;
localparam STATE_START_I2C = 1;
localparam STATE_SEND_ADDRESS = 2;
localparam STATE_SEND_EDID_BYTE_INDEX = 3;
localparam STATE_RESTART_I2C_FOR_READ = 4;
localparam STATE_SEND_READ_COMMAND = 5;
localparam STATE_HANDLE_BYTES = 6;
localparam STATE_READ_BYTE = 7;
localparam STATE_NEXT_READ_NAME = 8;
localparam STATE_STOP_I2C = 9;
localparam STATE_REFRESH_RATE = 10;
localparam STATE_REFRESH_RATE2 = 11;
localparam STATE_REFRESH_RATE3 = 12;
localparam STATE_REFRESH_RATE4 = 13;
localparam STATE_DONE = 14;
localparam STATE_WAIT_FOR_I2C = 15;

reg [3:0] state = STATE_IDLE;
reg [3:0] returnState = 0;
reg processStarted = 0;
reg [103:0] screenName = 0;
reg [3:0] nameCounter = 0;
reg [7:0] counter = 0;
reg [11:0] horizontalPixels = 0;
reg [11:0] verticalPixels = 0;
reg [15:0] pixelClock = 0;
reg [11:0] horizontalBlank = 0;
reg [11:0] verticalBlank = 0;
reg [19:0] refreshCalcTop = 0, refreshCalcBottom = 0;
reg [11:0] refreshRate = 0;
reg [2:0] foundNamePrefix = 0;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (enable) begin
                state <= STATE_START_I2C;
                dataReady <= 0;
                nameCounter <= 0;
                counter <= 0;
                refreshRate <= 0;
                foundNamePrefix <= 0;
            end
        end
        STATE_START_I2C: begin
            instructionI2C <= INST_START_TX;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_SEND_ADDRESS;
        end
        STATE_SEND_ADDRESS: begin
            instructionI2C <= INST_WRITE_BYTE;
            byteToSendI2C <= {7'h50, 1'b0};
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_SEND_EDID_BYTE_INDEX;
        end
        STATE_SEND_EDID_BYTE_INDEX: begin
            instructionI2C <= INST_WRITE_BYTE;
            byteToSendI2C <= 0;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_RESTART_I2C_FOR_READ;
        end
        STATE_RESTART_I2C_FOR_READ: begin
            instructionI2C <= INST_START_TX;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_SEND_READ_COMMAND;
        end
        STATE_SEND_READ_COMMAND: begin
            instructionI2C <= INST_WRITE_BYTE;
            byteToSendI2C <= {7'h50, 1'b1};
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_HANDLE_BYTES;
        end
        STATE_HANDLE_BYTES: begin
            instructionI2C <= INST_READ_BYTE;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_HANDLE_BYTES;
            counter <= counter + 1;
            case (counter)
                1, 8: begin
                    if (byteReceivedI2C != 8'h00) begin
                        state <= STATE_IDLE;
                        enableI2C <= 0;
                    end
                end
                55: pixelClock[7:0] <= byteReceivedI2C;
                56: pixelClock[15:8] <= byteReceivedI2C;
                57: horizontalPixels[7:0] <= byteReceivedI2C;
                58: horizontalBlank[7:0] <= byteReceivedI2C;
                59: begin
                    horizontalPixels[11:8] <= byteReceivedI2C[7:4];
                    horizontalBlank[11:8] <= byteReceivedI2C[3:0];
                end
                60: verticalPixels[7:0] <= byteReceivedI2C;
                61: verticalBlank[7:0] <= byteReceivedI2C;
                62: begin
                    verticalPixels[11:8] <= byteReceivedI2C[7:4];
                    verticalBlank[11:8] <= byteReceivedI2C[3:0];
                end
                73, 74, 75,
                91, 92, 93,
                109, 110, 111: foundNamePrefix <= byteReceivedI2C === 8'h00 ? foundNamePrefix + 1 : 0;
                76, 94, 112: foundNamePrefix <= byteReceivedI2C === 8'hFC ? foundNamePrefix + 1 : 0;
                77, 95, 113: begin
                    if (byteReceivedI2C == 8'h00 && foundNamePrefix == 3'd4)
                        returnState <= STATE_NEXT_READ_NAME;
                    else 
                        foundNamePrefix <= 0;
                end
                default: begin end
            endcase
        end
        STATE_READ_BYTE: begin
            instructionI2C <= INST_READ_BYTE;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_NEXT_READ_NAME;
        end
        STATE_NEXT_READ_NAME: begin
            screenName[{nameCounter, 3'b0}+:8] <= byteReceivedI2C;
            nameCounter <= nameCounter + 1;
            state <= (nameCounter === 12) ? STATE_STOP_I2C : STATE_READ_BYTE;
        end
        STATE_STOP_I2C: begin
            instructionI2C <= INST_STOP_TX;
            enableI2C <= 1;
            state <= STATE_WAIT_FOR_I2C;
            returnState <= STATE_REFRESH_RATE;
        end
        STATE_REFRESH_RATE: begin
            refreshCalcTop <= pixelClock * 10;
            refreshCalcBottom <= {8'b0, horizontalPixels + horizontalBlank};
            state <= STATE_REFRESH_RATE2;
        end
        STATE_REFRESH_RATE2: begin
            if (refreshCalcTop >= refreshCalcBottom) begin
                refreshCalcTop <= refreshCalcTop - refreshCalcBottom;
                refreshRate <= refreshRate + 1;
            end else begin
                state <= STATE_REFRESH_RATE3;
                refreshCalcBottom <= {8'b0, verticalPixels + verticalBlank};
            end
        end
        STATE_REFRESH_RATE3: begin
            refreshCalcTop <= {8'b0, refreshRate} * 20'd1000;
            refreshRate <= 0;
            state <= STATE_REFRESH_RATE4;
        end
        STATE_REFRESH_RATE4: begin
            if (refreshCalcTop >= refreshCalcBottom) begin
                refreshCalcTop <= refreshCalcTop - refreshCalcBottom;
                refreshRate <= refreshRate + 1;
            end else begin
                if (refreshCalcTop > 0)
                    refreshRate <= refreshRate + 1;
                state <= STATE_DONE;
            end
        end
        STATE_DONE: begin
            dataReady <= 1;
            if (~enable)
                state <= STATE_IDLE;
        end
        STATE_WAIT_FOR_I2C: begin
            if (~processStarted && ~completeI2C)
                processStarted <= 1;
            else if (completeI2C && processStarted) begin
                state <= returnState;
                processStarted <= 0;
                enableI2C <= 0;
            end
        end
    endcase
end


wire [7:0] verticalThousand, verticalHundred, verticalTen, verticalUnit;
wire [7:0] horizontalThousand, horizontalHundred, horizontalTen, horizontalUnit;
wire [7:0] refreshThousands, refreshHundreds, refreshTen, refreshUnit;


toDec vertConv(
    clk,
    horizontalPixels,
    horizontalThousand,
    horizontalHundred,
    horizontalTen,
    horizontalUnit
);
toDec horizConv(
    clk,
    verticalPixels,
    verticalThousand,
    verticalHundred,
    verticalTen,
    verticalUnit
);
toDec refreshConv(
    clk,
    refreshRate,
    refreshThousands,
    refreshHundreds,
    refreshTen,
    refreshUnit
);

always @(posedge clk) begin
    if (~enable) begin
        if (rowIndex == 1)
            edidDataOut <= screenName[{charIndex, 3'b0}+:8];
        else if (rowIndex == 3) begin
            case (charIndex)
                0: edidDataOut <= horizontalThousand;
                1: edidDataOut <= horizontalHundred;
                2: edidDataOut <= horizontalTen;
                3: edidDataOut <= horizontalUnit;

                5: edidDataOut <= verticalThousand;
                6: edidDataOut <= verticalHundred;
                7: edidDataOut <= verticalTen;
                8: edidDataOut <= verticalUnit;

                12: edidDataOut <= refreshTen;
                13: edidDataOut <= refreshUnit;
                default: edidDataOut <= "";
            endcase
        end
    end
end

endmodule
