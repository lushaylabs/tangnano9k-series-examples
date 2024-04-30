`ifdef FORMAL
`default_nettype none
`endif
module textRow #(
    parameter ADDRESS_OFFSET = 8'd0
) (
    input clk_i,
    input [7:0] readAddress_i,
    output [7:0] outByte_o
);
    reg [7:0] textBuffer [15:0];

    integer i;

    initial begin
        for (i=0; i<15; i=i+1) begin
            textBuffer[i] = 'd48 + ADDRESS_OFFSET + i;
        end
    end

    assign outByte_o = textBuffer[(readAddress_i-ADDRESS_OFFSET)];

    //
    // FORMAL VERIFICATION
    //
    `ifdef FORMAL

        `ifdef TEXT
            `define	ASSUME	assume
        `else
            `define	ASSUME	assert
        `endif

        // Prove outByte_o is assigned correctly
        always @(*)
            if(f_past_valid)
                assert(outByte_o == textBuffer[(readAddress_i-ADDRESS_OFFSET)]);

        // f_past_valid
        reg	f_past_valid;
        initial	f_past_valid = 1'b0;
        always @(posedge clk_i)
            f_past_valid <= 1'b1;

        //
        // Contract
        //

    `endif // FORMAL

endmodule

module textEngine (
    input clk_i,
    input reset_i,
    input [9:0] pixelAddress_i,
    output [7:0] pixelData_o,
    output [5:0] charAddress_o,
    input [7:0] charOutput_i
);
    reg [7:0] fontBuffer [1519:0];
    initial $readmemh("font.hex", fontBuffer);

    wire [2:0] columnAddress;
    wire topRow;

    reg [7:0] outputBuffer;
    wire [7:0] chosenChar;

    always @(posedge clk_i) begin
        outputBuffer <= fontBuffer[((chosenChar-8'd32) << 4) + (columnAddress << 1) + (topRow ? 0 : 1)];
    end

    assign charAddress_o = {pixelAddress_i[9:8],pixelAddress_i[6:3]};
    assign columnAddress = pixelAddress_i[2:0];
    assign topRow = !pixelAddress_i[7];

    assign chosenChar = (charOutput_i >= 32 && charOutput_i <= 126) ? charOutput_i : 32;
    assign pixelData_o = outputBuffer;

    //
    // FORMAL VERIFICATION
    //
    `ifdef FORMAL

        `ifdef TEXT
            `define	ASSUME	assume
        `else
            `define	ASSUME	assert
        `endif

        // f_past_valid
        reg	f_past_valid;
        initial	f_past_valid = 1'b0;
        always @(posedge clk_i)
            f_past_valid <= 1'b1;

        // Prove that charAddress_o is assigned correctly
        always @(*)
            if((f_past_valid)&&(!reset_i))
                assert(charAddress_o == {pixelAddress_i[9:8],pixelAddress_i[6:3]});

        // Prove that topRow is assigned correctly
        always @(*)
            if((f_past_valid)&&(!reset_i))
                assert(topRow == !pixelAddress_i[7]);

        // Prove that pixelData_o is assigned correctly
        always @(*)
            if((f_past_valid)&&(!reset_i))
                assert(pixelData_o == outputBuffer);
        
        // Prove that columnAddress is assigned correctly
        always @(*)            
            if((f_past_valid)&&(!reset_i))
                assert(columnAddress == pixelAddress_i[2:0]);
        
        //
        // Contract
        //
        always @(*)
        if((f_past_valid)&&(!reset_i))
            if((charOutput_i >= 32) && (charOutput_i <= 126))
                assert(chosenChar == charOutput_i);
            else
                assert(chosenChar == 32);


    `endif // FORMAL

endmodule