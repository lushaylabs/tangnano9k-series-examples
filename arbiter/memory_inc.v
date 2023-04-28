module memoryIncAtomic (
    input clk,
    input grantedAccess,
    output reg requestingMemory = 0,
    output reg [7:0] address = 8'h18,
    output reg readWrite = 1,
    input [31:0] inputData,
    output reg [31:0] outputData = 0
);

    reg [24:0] counter = 0;
    always @(posedge clk) begin
        if (grantedAccess)
            counter <= 0;
        else if (counter != 25'd27000000) 
            counter <= counter + 1;
    end

    reg [1:0] state = 0;

    localparam STATE_IDLE = 2'd0;
    localparam STATE_WAIT_FOR_CONTROL = 2'd1;
    localparam STATE_READ_VALUE = 2'd2;
    localparam STATE_WRITE_VALUE = 2'd3;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                if (counter == 25'd27000000) begin
                    state <= STATE_WAIT_FOR_CONTROL;
                    requestingMemory <= 1;
                    readWrite <= 1; 
                end
            end
            STATE_WAIT_FOR_CONTROL: begin
                if (grantedAccess) begin
                    state <= STATE_READ_VALUE;
                end 
            end
            STATE_READ_VALUE: begin
                outputData <= inputData + 1;
                state <= STATE_WRITE_VALUE;
                readWrite <= 0;
            end
            STATE_WRITE_VALUE: begin
                requestingMemory <= 0;
                state <= STATE_IDLE;
                readWrite <= 1;
            end
        endcase
    end
endmodule

module memoryRead (
    input clk,
    input grantedAccess,
    output reg requestingMemory = 0,
    output reg [7:0] address = 8'h18,
    output reg readWrite = 1,
    input [31:0] inputData,
    output reg [31:0] outputData = 0
);

    reg [24:0] counter = 0;
    always @(posedge clk) begin
        if (grantedAccess)
            counter <= 0;
        else if (counter != 25'd27000000) 
            counter <= counter + 1;
    end

    reg [1:0] state = 0;

    localparam STATE_IDLE = 2'd0;
    localparam STATE_WAIT_FOR_CONTROL = 2'd1;
    localparam STATE_READ_VALUE = 2'd2;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                if (counter == 25'd27000000) begin
                    state <= STATE_WAIT_FOR_CONTROL;
                    requestingMemory <= 1;
                    readWrite <= 1; 
                end
            end
            STATE_WAIT_FOR_CONTROL: begin
                if (grantedAccess) begin
                    state <= STATE_READ_VALUE;
                end 
            end
            STATE_READ_VALUE: begin
                outputData <= inputData;
                state <= STATE_IDLE;
                requestingMemory <= 0;
            end
        endcase
    end
endmodule
