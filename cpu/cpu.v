
module cpu(
    input clk,
    output reg [10:0] flashReadAddr = 0,
    input [7:0] flashByteRead,
    output reg enableFlash = 0,
    input flashDataReady,
    output reg [5:0] leds = 6'b111111,
    output reg [7:0] cpuChar = 0,
    output reg [5:0] cpuCharIndex = 0,
    output reg writeScreen = 0,
    input reset,
    input btn
);

    localparam STATE_FETCH = 0;
    localparam STATE_FETCH_WAIT_START = 1;
    localparam STATE_FETCH_WAIT_DONE = 2;
    localparam STATE_DECODE = 3;
    localparam STATE_RETRIEVE = 4;
    localparam STATE_RETRIEVE_WAIT_START = 5;
    localparam STATE_RETRIEVE_WAIT_DONE = 6;
    localparam STATE_EXECUTE = 7;
    localparam STATE_HALT = 8;
    localparam STATE_WAIT = 9;
    localparam STATE_PRINT = 10;

    localparam CMD_CLR = 0;
    localparam CMD_ADD = 1;
    localparam CMD_STA = 2;
    localparam CND_INV = 3;
    localparam CMD_PRNT = 4;
    localparam CMD_JMPZ = 5;
    localparam CMD_WAIT = 6;
    localparam CMD_HLT = 7;

    reg [5:0] state = 0;
    reg [10:0] pc = 0;
    reg [7:0] a = 0, b = 0, c = 0, ac = 0;
    reg [7:0] param = 0, command = 0;

    reg [15:0] waitCounter = 0;

    always @(posedge clk) begin
        if (reset) begin
            pc <= 0;
            a <= 0;
            b <= 0;
            c <= 0;
            ac <= 0;
            command <= 0;
            param <= 0;
            state <= STATE_FETCH;
            enableFlash <= 0;
            leds <= 6'b111111;
        end
        else begin
            case(state)
                STATE_FETCH: begin
                    if (~enableFlash) begin
                        flashReadAddr <= pc;
                        enableFlash <= 1;
                        state <= STATE_FETCH_WAIT_START;
                    end
                end
                STATE_FETCH_WAIT_START: begin
                    if (~flashDataReady) begin
                        state <= STATE_FETCH_WAIT_DONE;
                    end
                end
                STATE_FETCH_WAIT_DONE: begin
                    if (flashDataReady) begin
                        command <= flashByteRead;
                        enableFlash <= 0;
                        state <= STATE_DECODE;
                    end
                end
                STATE_DECODE: begin
                    pc <= pc + 1;
                    // command has constant param
                    if (command[7]) begin
                        state <= STATE_RETRIEVE;
                    end else begin
                        param <= command[3] ? a : command[2] ? b : command[1] ? c : ac;
                        state <= STATE_EXECUTE;
                    end
                end
                STATE_RETRIEVE: begin
                    if (~enableFlash) begin
                        flashReadAddr <= pc;
                        enableFlash <= 1;
                        state <= STATE_RETRIEVE_WAIT_START;
                    end
                end
                 STATE_RETRIEVE_WAIT_START: begin
                    if (~flashDataReady) begin
                        state <= STATE_RETRIEVE_WAIT_DONE;
                    end
                end
                STATE_RETRIEVE_WAIT_DONE: begin
                    if (flashDataReady) begin
                        param <= flashByteRead;
                        enableFlash <= 0;
                        state <= STATE_EXECUTE;
                        pc <= pc + 1;
                    end
                end
                STATE_EXECUTE: begin
                    state <= STATE_FETCH;
                    case (command[6:4])
                        CMD_CLR: begin
                            if (command[0])
                                ac <= 0;
                            else if (command[1])
                                ac <= btn ? 0 : (ac ? 1 : 0);
                            else if (command[2])
                                b <= 0;
                            else if (command[3])
                                a <= 0;
                        end
                        CMD_ADD: begin
                            ac <= ac + param;
                        end
                        CMD_STA: begin
                            if (command[0])
                                leds <= ~ac[5:0];
                            else if (command[1])
                                c <= ac;
                            else if (command[2])
                                b <= ac;
                            else if (command[3])
                                a <= ac;
                        end
                        CND_INV: begin
                            if (command[0])
                                ac <= ~ac;
                            else if (command[1])
                                c <= ~c;
                            else if (command[2])
                                b <= ~b;
                            else if (command[3])
                                a <= ~a;
                        end
                        CMD_PRNT: begin
                            cpuCharIndex <= ac[5:0];
                            cpuChar <= param;
                            writeScreen <= 1;
                            state <= STATE_PRINT;
                        end
                        CMD_JMPZ: begin
                            pc <= (ac == 8'd0) ? {3'b0,param} : pc;
                        end
                        CMD_WAIT: begin
                            waitCounter <= 0;
                            state <= STATE_WAIT;
                        end
                        CMD_HLT: begin
                            state <= STATE_HALT;
                        end
                    endcase
                end
                STATE_PRINT: begin
                    writeScreen <= 0;
                    state <= STATE_FETCH;
                end
                STATE_WAIT: begin
                    if (waitCounter == 27000) begin
                        param <= param - 1;
                        waitCounter <= 0;
                        if (param == 0)
                            state <= STATE_FETCH;
                    end else
                        waitCounter <= waitCounter + 1;
                end
                STATE_HALT: begin

                end
            endcase
        end
    end
endmodule
