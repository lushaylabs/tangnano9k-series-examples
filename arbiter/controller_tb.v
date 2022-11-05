module test();
    reg clk = 0;
    reg req1 = 1, req2 = 1, req3 = 1;
    wire [2:0] grantedAccess;
    wire enabled;

    wire [7:0] address;
    wire [31:0] dataToMem;
    wire readWrite;

    reg [7:0] addr1 = 8'hA1;
    reg [7:0] addr2 = 8'hA2;
    reg [7:0] addr3 = 8'hA3;

    reg [31:0] dataToMem1 = 32'hD1;
    reg [31:0] dataToMem2 = 32'hD2;
    reg [31:0] dataToMem3 = 32'hD3;

    memController fc(
        clk,
        {req3,req2,req1},
        grantedAccess,
        enabled,
        address,
        dataToMem,
        readWrite,
        addr1,
        addr2,
        addr3,
        dataToMem1,
        dataToMem2,
        dataToMem3,
        1'b0,
        1'b1,
        1'b0
    );
    
    always
        #1  clk = ~clk;

    reg [1:0] counter = 0;
    always @(posedge clk) begin
        if (enabled) begin
            counter <= counter + 1;
            if (counter == 2'b11) begin
                if (grantedAccess == 3'b001) begin
                    req1 <= 0;
                end
                else if (grantedAccess == 3'b010) begin
                    req2 <= 0;
                end
                else if (grantedAccess == 3'b100) begin
                    req3 <= 0;
                end
            end
        end
        else begin
            counter <= 0;
            req1 <= 1;
            req2 <= 1;
            req3 <= 1;
        end
    end

    initial begin
        #1000 $finish;
    end
        

    initial begin
        $dumpfile("controller.vcd");
        $dumpvars(0,test);
    end
endmodule