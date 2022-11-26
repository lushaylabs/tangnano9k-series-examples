`default_nettype none

module adc #(
    parameter address = 7'd0
) (
    input clk,
    input [1:0] channel,
    output reg [15:0] outputData = 0,
    output reg dataReady = 1,
    input enable,
    output reg [1:0] instructionI2C = 0,
    output reg enableI2C = 0,
    output reg [7:0] byteToSendI2C = 0,
    input [7:0] byteReceivedI2C,
    input completeI2C
);

// setup config
reg [15:0] setupRegister = {
    1'b1, // Start Conversion
    3'b100, // Channel 0 Single ended
    3'b001, // FSR +- 4.096v
    1'b1, // Single shot mode
    3'b100, // 128 SPS
    1'b0, // Traditional Comparator
    1'b0, // Active low alert
    1'b0, // Non latching
    2'b11 // Disable comparator
};

localparam CONFIG_REGISTER = 8'b00000001;
localparam CONVERSION_REGISTER = 8'b00000000;

localparam TASK_SETUP = 0;
localparam TASK_CHECK_DONE = 1;
localparam TASK_CHANGE_REG = 2;
localparam TASK_READ_VALUE = 3;

localparam INST_START_TX = 0;
localparam INST_STOP_TX = 1;
localparam INST_READ_BYTE = 2;
localparam INST_WRITE_BYTE = 3;

localparam STATE_IDLE = 0;
localparam STATE_RUN_TASK = 1;
localparam STATE_WAIT_FOR_I2C = 2;
localparam STATE_INC_SUB_TASK = 3;
localparam STATE_DONE = 4;
localparam STATE_DELAY = 5;

reg [1:0] taskIndex = 0;
reg [2:0] subTaskIndex = 0;
reg [4:0] state = STATE_IDLE;
reg [7:0] counter = 0;
reg processStarted = 0;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (enable) begin
                state <= STATE_RUN_TASK;
                taskIndex <= 0;
                subTaskIndex <= 0;
                dataReady <= 0;
                counter <= 0;
            end
        end
        STATE_RUN_TASK: begin
            case ({taskIndex,subTaskIndex})
                {TASK_SETUP,3'd0},
                {TASK_CHECK_DONE,3'd1},
                {TASK_CHANGE_REG,3'd1},
                {TASK_READ_VALUE,3'd0}: begin
                    instructionI2C <= INST_START_TX;
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_SETUP,3'd1},
                {TASK_CHANGE_REG,3'd2},
                {TASK_CHECK_DONE,3'd2},
                {TASK_READ_VALUE,3'd1}: begin
                    instructionI2C <= INST_WRITE_BYTE;
                    byteToSendI2C <= {address, (taskIndex == TASK_CHECK_DONE || taskIndex == TASK_READ_VALUE) ? 1'b1 : 1'b0};
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_SETUP,3'd5},
                {TASK_CHECK_DONE,3'd5},
                {TASK_CHANGE_REG,3'd4},
                {TASK_READ_VALUE,3'd5}: begin
                    instructionI2C <= INST_STOP_TX;
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_SETUP,3'd2},
                {TASK_CHANGE_REG,3'd3}: begin
                    instructionI2C <= INST_WRITE_BYTE;
                    byteToSendI2C <= taskIndex == TASK_SETUP ? CONFIG_REGISTER : CONVERSION_REGISTER;
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_SETUP,3'd3}: begin
                    instructionI2C <= INST_WRITE_BYTE;
                    byteToSendI2C <= {
                        setupRegister[15] ? 1'b1 : 1'b0,
                        1'b1, channel,
                        setupRegister[11:8]
                    };
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_SETUP,3'd4}: begin
                    instructionI2C <= INST_WRITE_BYTE;
                    byteToSendI2C <= setupRegister[7:0];
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_CHECK_DONE,3'd0}: begin
                    state <= STATE_DELAY;
                end
                {TASK_CHECK_DONE,3'd3}, 
                {TASK_READ_VALUE,3'd2}: begin
                    instructionI2C <= INST_READ_BYTE;
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_CHECK_DONE,3'd4},
                {TASK_READ_VALUE,3'd3}: begin
                    instructionI2C <= INST_READ_BYTE;
                    outputData[15:8] <= byteReceivedI2C;
                    enableI2C <= 1;
                    state <= STATE_WAIT_FOR_I2C;
                end
                {TASK_CHANGE_REG,3'd0}: begin
                    if (outputData[15])
                        state <= STATE_INC_SUB_TASK;
                    else begin
                        subTaskIndex <= 0;
                        taskIndex <= TASK_CHECK_DONE;
                    end
                end
                {TASK_READ_VALUE,3'd4}: begin
                    state <= STATE_INC_SUB_TASK;
                    outputData[7:0] <= byteReceivedI2C;
                end
                default:
                    state <= STATE_INC_SUB_TASK;
            endcase
        end
        STATE_WAIT_FOR_I2C: begin
            if (~processStarted && ~completeI2C)
                processStarted <= 1;
            else if (completeI2C && processStarted) begin
                state <= STATE_INC_SUB_TASK;
                processStarted <= 0;
                enableI2C <= 0;
            end
        end
        STATE_INC_SUB_TASK: begin
            state <= STATE_RUN_TASK;
            if (subTaskIndex == 3'd5) begin
                subTaskIndex <= 0;
                if (taskIndex == TASK_READ_VALUE) begin
                    state <= STATE_DONE;
                end
                else
                    taskIndex <= taskIndex + 1;
            end
            else
                subTaskIndex <= subTaskIndex + 1;
        end
        STATE_DELAY: begin
            counter <= counter + 1;
            if (counter == 8'b11111111) begin
                state <= STATE_INC_SUB_TASK;
            end
        end
        STATE_DONE: begin
            dataReady <= 1;
            if (~enable)
                state <= STATE_IDLE;
        end
    endcase
end

endmodule