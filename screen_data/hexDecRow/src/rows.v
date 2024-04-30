`ifdef FORMAL
`default_nettype none
`endif
module uartTextRow (
    input clk_i,
    input byteReady_i,
    input [7:0] data_i,
    input [3:0] outputCharIndex_i,
    output [7:0] outByte_o
);
    localparam bufferWidth = 128;
    reg [(bufferWidth-1):0] textBuffer = 0;
    reg [3:0] inputCharIndex = 0;
    reg [1:0] state = 0;

    localparam WAIT_FOR_NEXT_CHAR_STATE = 0;
    localparam WAIT_FOR_TRANSFER_FINISH = 1;
    localparam SAVING_CHARACTER_STATE = 2;

    always @(posedge clk_i) begin
        case (state)
            WAIT_FOR_NEXT_CHAR_STATE: begin
                if (byteReady_i == 0)
                    state <= WAIT_FOR_TRANSFER_FINISH;
            end
            WAIT_FOR_TRANSFER_FINISH: begin
                if (byteReady_i == 1)
                    state <= SAVING_CHARACTER_STATE;
            end
            SAVING_CHARACTER_STATE: begin
                if (data_i == 8'd8 || data_i == 8'd127) begin
                    inputCharIndex <= inputCharIndex - 1;
                    textBuffer[({4'd0,inputCharIndex-4'd1}<<3)+:8] <= 8'd32;
                end
                else begin
                    inputCharIndex <= inputCharIndex + 1;
                    textBuffer[({4'd0,inputCharIndex}<<3)+:8] <= data_i;
                end
                state <= WAIT_FOR_NEXT_CHAR_STATE;
            end
        endcase
    end

    assign outByte_o = textBuffer[({4'd0, outputCharIndex_i} << 3)+:8];

    //
    // FORMAL VERIFICATION
    //
    `ifdef FORMAL

        `ifdef UART_TEXT_ROW
            `define	ASSUME	assume
        `else
            `define	ASSUME	assert
        `endif

        // f_past_valid
        reg	f_past_valid;
        initial	f_past_valid = 1'b0;
        always @(posedge clk_i)
            f_past_valid <= 1'b1;

    // Prove that outByte_o is assigned correctly
    always @(*)
        if(f_past_valid)
            assert(outByte_o == (textBuffer[({4'd0, outputCharIndex_i} << 3)+:8]));

    //
    // Formal Verification
    //
    always @(posedge clk_i) begin
        if((f_past_valid)) begin
            case ($past(state))
                SAVING_CHARACTER_STATE: begin
                    // `ASSUME(data_i == 8'd8 || data_i == 8'd127);
                    if ($past(data_i) == 8'd8 || $past(data_i) == 8'd127) begin
                        if($past(inputCharIndex) != 0)
                            assert(inputCharIndex == ($past(inputCharIndex) - 1));
                        assert(textBuffer[({4'd0, $past(inputCharIndex)-4'd1}<<3)+:8] == 8'd32);
                    end else begin
                        if($past(inputCharIndex) != 8'hF)
                            assert(inputCharIndex == ($past(inputCharIndex) + 1));
                        assert(textBuffer[({4'd0,$past(inputCharIndex)}<<3)+:8] == $past(data_i));
                    end
                end
            endcase
        end
    end

`endif

endmodule

module binaryRow(
    input clk_i,
    input [7:0] value,
    input [3:0] outputCharIndex,
    output [7:0] outByte
);
    reg [7:0] outByteReg;
    wire [2:0] bitNumber;

    assign bitNumber = outputCharIndex - 5;

    always @(posedge clk_i) begin
        case (outputCharIndex)
            0: outByteReg <= "B";
            1: outByteReg <= "i";
            2: outByteReg <= "n";
            3: outByteReg <= ":";
            4: outByteReg <= " ";
            13, 14, 15: outByteReg <= " ";
            default: outByteReg <= (value[7-bitNumber]) ? "1" : "0";
        endcase
    end

    assign outByte = outByteReg;
endmodule

module toHex(
    input clk_i,
    input [3:0] value,
    output reg [7:0] hexChar = "0"
);
    always @(posedge clk_i) begin
        hexChar <= (value <= 9) ? 8'd48 + value : 8'd55 + value;
    end
endmodule

module toDec(
    input clk_i,
    input [7:0] value,
    output reg [7:0] hundreds = "0",
    output reg [7:0] tens = "0",
    output reg [7:0] units = "0"
);
    reg [11:0] digits = 0;
    reg [7:0] cachedValue = 0;
    reg [3:0] stepCounter = 0;
    reg [3:0] state = 0;

    localparam START_STATE = 0;
    localparam ADD3_STATE = 1;
    localparam SHIFT_STATE = 2;
    localparam DONE_STATE = 3;

    always @(posedge clk_i) begin
        case (state)
            START_STATE: begin
                cachedValue <= value;
                stepCounter <= 0;
                digits <= 0;
                state <= ADD3_STATE;
            end
            ADD3_STATE: begin
                digits <= digits + ((digits[3:0] >= 5) ? 12'd3 : 12'd0) + ((digits[7:4] >= 5) ? 12'd48 : 12'd0) + ((digits[11:8] >= 5) ? 12'd768 : 12'd0);
                state <= SHIFT_STATE;
            end
            SHIFT_STATE: begin
                digits <= {digits[10:0],cachedValue[7]};
                cachedValue <= {cachedValue[6:0],1'b0};
                if (stepCounter == 7)
                    state <= DONE_STATE;
                else begin
                    state <= ADD3_STATE;
                    stepCounter <= stepCounter + 1;
                end
            end
            DONE_STATE: begin
                hundreds <= 8'd48 + digits[11:8];
                tens <= 8'd48 + digits[7:4];
                units <= 8'd48 + digits[3:0];
                state <= START_STATE;
            end
        endcase
    end
endmodule


module hexDecRow(
    input clk_i,
    input [7:0] value_i,
    input [3:0] outputCharIndex_i,
    output [7:0] outByte_i
);
    reg [7:0] outByteReg;

    wire [3:0] hexLower, hexHigher;
    wire [7:0] lowerHexChar, higherHexChar;

    assign hexLower = value_i[3:0];
    assign hexHigher = value_i[7:4];

    toHex h1(clk_i, hexLower, lowerHexChar);
    toHex h2(clk_i, hexHigher, higherHexChar);

    wire [7:0] decChar1, decChar2, decChar3;
    toDec dec(clk_i, value_i, decChar1, decChar2, decChar3);
    
    always @(posedge clk_i) begin
        case (outputCharIndex_i)
            0: outByteReg <= "H";
            1: outByteReg <= "e";
            2: outByteReg <= "x";
            3: outByteReg <= ":";
            5: outByteReg <= higherHexChar;
            6: outByteReg <= lowerHexChar;
            8: outByteReg <= "D";
            9: outByteReg <= "e";
            10: outByteReg <= "c";
            11: outByteReg <= ":";
            13: outByteReg <= decChar1;
            14: outByteReg <= decChar2;
            15: outByteReg <= decChar3;
            default: outByteReg <= " ";
        endcase
    end

    assign outByte_i = outByteReg;

    //
    // FORMAL VERIFICATION
    //
    `ifdef FORMAL

        `ifdef HEX_DEC_ROW
            `define	ASSUME	assume
        `else
            `define	ASSUME	assert
        `endif

        // f_past_valid
        reg	f_past_valid;
        initial	f_past_valid = 1'b0;
        always @(posedge clk_i)
            f_past_valid <= 1'b1;

        // Prove that outByte_i is assigned correctly
        always @(*)
            if(f_past_valid)
                assert(outByte_i == outByteReg);

        //
        // Contract
        //
        always @(posedge clk_i) begin
            if(f_past_valid) begin
                case ($past(outputCharIndex_i))
                    5: assert(outByteReg == $past(higherHexChar));
                    6: assert(outByteReg == $past(lowerHexChar));
                    13: assert(outByteReg == $past(decChar1));
                    14: assert(outByteReg == $past(decChar2));
                    15: assert(outByteReg == $past(decChar3));
                endcase
            end
        end


    `endif // FORMAL
endmodule

module progressRow(
    input clk_i,
    input reset_i,
    input [7:0] value_i,
    input [9:0] pixelAddress_i,
    output [7:0] outByte_o
);
    reg [7:0] outByteReg;
    reg [7:0] bar, border;
    wire topRow;
    wire [6:0] column;

    assign topRow = !pixelAddress_i[7];
    assign column  = pixelAddress_i[6:0];

    always @(posedge clk_i) begin
        if (topRow) begin
            case (column)
                0, 127: begin
                    bar = 8'b1100_0000;
                    border = 8'b1100_0000;
                end
                1, 126: begin
                    bar = 8'b1110_0000;
                    border = 8'b0110_0000;
                end
                2, 125: begin
                    bar = 8'b1110_0000;
                    border = 8'b0011_0000;
                end
                default: begin
                    bar = 8'b1111_0000;
                    border = 8'b0001_0000;
                end
            endcase
        end else begin
            case (column)
                0, 127: begin
                    bar = 8'b0000_0011;
                    border = 8'b0000_0011;
                end
                1, 126: begin
                    bar = 8'b0000_0111;
                    border = 8'b0000_0110;
                end
                2, 125: begin
                    bar = 8'b0000_0111;
                    border = 8'b0000_1100;
                end
                default: begin
                    bar = 8'b0000_1111;
                    border = 8'b0000_1000;
                end
            endcase
        end

        if (column > value_i[7:1])
            outByteReg <= border;
        else
            outByteReg <= bar;
    end

    assign outByte_o = outByteReg;

    //
    // FORMAL VERIFICATION
    //
    `ifdef FORMAL

        `ifdef PROGRESS_ROW
            `define	ASSUME	assume
        `else
            `define	ASSUME	assert
        `endif

        // f_past_valid
        reg	f_past_valid;
        initial	f_past_valid = 1'b0;
        always @(posedge clk_i)
            f_past_valid <= 1'b1;

        // Prove that topRow gets assigned correctly
        always @(*)
            if(f_past_valid)
                assert(topRow == !pixelAddress_i[7]);

        // Prove that column gets assigned correctly
        always @(*)
            if(f_past_valid)
                assert(column  == pixelAddress_i[6:0]);

        // Prove that outByte_o gets assigned correctly
        always @(*)
            if(f_past_valid)
                assert(outByte_o == outByteReg);



        //
        // Contract
        //
        always @(posedge clk_i) begin
            if((f_past_valid)&&($past(f_past_valid))&&(!reset_i)) begin
                `ASSUME(pixelAddress_i == $past(pixelAddress_i));
                if (topRow) begin
                    case (column)
                        0, 127: begin
                            assert(bar == 8'b1100_0000);
                            assert(border == 8'b1100_0000);
                        end
                        1, 126: begin
                            assert(bar == 8'b1110_0000);
                            assert(border == 8'b0110_0000);  
                        end
                        2, 125: begin
                            assert(bar == 8'b1110_0000);
                            assert(border == 8'b0011_0000); 
                        end
                        default: begin
                            assert(bar == 8'b1111_0000);
                            assert(border == 8'b0001_0000); 
                        end
                    endcase
                end else begin
                    case (column)
                        0, 127: begin
                            assert(bar == 8'b0000_0011);
                            assert(border == 8'b0000_0011);
                        end
                        1, 126: begin
                            assert(bar == 8'b0000_0111);
                            assert(border == 8'b0000_0110);  
                        end
                        2, 125: begin
                            assert(bar == 8'b0000_0111);
                            assert(border == 8'b0000_1100); 
                        end
                        default: begin
                            assert(bar == 8'b0000_1111);
                            assert(border == 8'b0000_1000); 
                        end
                    endcase
                end
            end
        end

    `endif

endmodule