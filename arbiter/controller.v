`default_nettype none

module memController
(
    input clk,
    
    input [2:0] requestingMemory,
    output reg [2:0] grantedAccess = 0,

    output enabled,
    output [7:0] address,
    output [31:0] dataToMem,
    output readWrite,

    input [7:0] addr1,
    input [7:0] addr2,
    input [7:0] addr3,

    input [31:0] dataToMem1,
    input [31:0] dataToMem2,
    input [31:0] dataToMem3,

    input readWrite1,
    input readWrite2,
    input readWrite3
);
    reg [(3*4)-1:0] queue = 0;
    reg [2:0] currentlyInQueue = 0;
    reg [1:0] queueNextIndex = 0;
    reg [1:0] queueCurrIndex = 0;

    wire [2:0] requestsNotInQueue;
    wire [2:0] nextInLine;

    always @(posedge clk) begin
        if (requestsNotInQueue != 0) begin
            queue[(queueNextIndex * 3)+:3] <= nextInLine;
            currentlyInQueue <= currentlyInQueue | nextInLine;
            queueNextIndex <= queueNextIndex + 1;
        end
        else if (enabled && (requestingMemory & grantedAccess) == 0) begin
            grantedAccess <= 3'b000;
            queueCurrIndex <= queueCurrIndex + 1;
            currentlyInQueue <= currentlyInQueue & (~grantedAccess);
        end

        if (~enabled && queueNextIndex != queueCurrIndex) begin
            grantedAccess <= queue[(queueCurrIndex * 3)+:3];
        end
    end

    assign requestsNotInQueue = (requestingMemory & ~currentlyInQueue);
    assign nextInLine = requestsNotInQueue[0] ? 3'b001 : requestsNotInQueue[1] ? 3'b010 : 3'b100;
    assign enabled = grantedAccess[0] | grantedAccess[1] | grantedAccess[2];

    assign address = (grantedAccess[0]) ? addr1 : (grantedAccess[1]) ? addr2 : (grantedAccess[2]) ? addr3 : 0;
    assign readWrite = (grantedAccess[0]) ? readWrite1 : (grantedAccess[1]) ? readWrite2 : (grantedAccess[2]) ? readWrite3 : 0;
    assign dataToMem = (grantedAccess[0]) ? dataToMem1 : (grantedAccess[1]) ? dataToMem2 : (grantedAccess[2]) ? dataToMem3 : 0;
endmodule