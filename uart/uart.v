`ifdef FORMAL
`default_nettype none
`endif

module uart
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115_200 Baud rate
)
(
    input clk_i,
    input reset_i,
    input uart_rx_i,
    output uart_tx_o,
    output reg [5:0] led_o,
    input btn1
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES/ 2);

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;

reg [3:0] rxState;
reg [12:0] rxCounter;
reg [2:0] rxBitNumber;
reg [7:0] dataIn;
reg byteReady;

initial rxState = RX_STATE_IDLE;
initial rxCounter = 0;
initial rxBitNumber = 0;
initial dataIn = 6'b11_1111;
initial byteReady = 0;

always @(posedge clk_i) begin
    if(reset_i) begin
        rxState <= RX_STATE_IDLE;
        rxCounter <= 0;
        rxBitNumber <= 0;
        byteReady <= 0;
        dataIn <= 6'b11_1111;
    end else begin
        case (rxState)
            RX_STATE_IDLE: begin
                if (uart_rx_i == 0) begin
                    rxState <= RX_STATE_START_BIT;
                    rxCounter <= 1;
                    rxBitNumber <= 0;
                    byteReady <= 0;
                end
            end 
            RX_STATE_START_BIT: begin
                if (rxCounter == HALF_DELAY_WAIT) begin
                    rxState <= RX_STATE_READ_WAIT;
                    rxCounter <= 1;
                end else 
                    rxCounter <= rxCounter + 1;
            end
            RX_STATE_READ_WAIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_READ;
                end
            end
            RX_STATE_READ: begin
                rxCounter <= 1;
                dataIn <= {uart_rx_i, dataIn[7:1]};
                rxBitNumber <= rxBitNumber + 1;
                if (rxBitNumber == 3'b111)
                    rxState <= RX_STATE_STOP_BIT;
                else
                    rxState <= RX_STATE_READ_WAIT;
            end
            RX_STATE_STOP_BIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_IDLE;
                    rxCounter <= 0;
                    byteReady <= 1;
                end
            end
        endcase
    end
end

always @(posedge clk_i) begin
    if(reset_i)
        led_o <= 6'b11_1111;
    else
        if (byteReady)
            led_o <= ~dataIn[5:0];
end


//
// FORMAL VERIFICATION
//
`ifdef FORMAL

    `ifdef UART
		`define	ASSUME	assume
	`else
		`define	ASSUME	assert
	`endif

    // f_past_valid
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge clk_i)
		f_past_valid <= 1'b1;

    // Prove rxState is always in a valid state
    always @(*)
        if(f_past_valid)
            assert(rxState <= RX_STATE_STOP_BIT);

    // Prove rxCount is always in a valid state
    always @(*)
        if(f_past_valid)
            assert(rxCounter <= DELAY_FRAMES);

    always@(posedge clk_i)
        `ASSUME(uart_rx_i == $past(uart_rx_i));

    // Prove that after a reset, registers get initialized
    always @(posedge clk_i) begin
        if(($past(f_past_valid))&&($past(reset_i))) begin
            assert(rxState == RX_STATE_IDLE);
            assert(rxCounter == 0);
            assert(rxBitNumber == 0);
            assert(byteReady == 0);
            assert(dataIn == 6'b11_1111);
        end
    end

    //
    // Contract
    //
    always@(posedge clk_i) begin
        if((f_past_valid)&&(!reset_i))
            case(rxState)
                RX_STATE_IDLE:          assert(rxCounter == 0);                     // No byte sent
                RX_STATE_START_BIT:     assert(rxCounter == ($past(rxCounter)+1));
                RX_STATE_READ_WAIT: begin
                    if(($past(rxState == RX_STATE_START_BIT))||($past(rxState == RX_STATE_READ))||($past(rxState == RX_STATE_STOP_BIT)))
                        assert(rxCounter == 1);
                    else
                        assert(rxCounter == ($past(rxCounter)+1));
                end
                RX_STATE_READ:          assert(rxCounter == DELAY_FRAMES);
                RX_STATE_STOP_BIT:  begin
                    if(($past(rxState == RX_STATE_READ)))
                        assert(rxCounter == 1);
                    else
                        assert(rxCounter == ($past(rxCounter)+1));
                end
            endcase
    end

    always @(posedge clk_i)
        if((f_past_valid)&&(!reset_i)&&($past(rxState) == RX_STATE_READ)&&(rxState == (RX_STATE_READ_WAIT || RX_STATE_STOP_BIT))) begin
            assert(rxBitNumber == ($past(rxBitNumber)+1));
            assert(dataIn == {uart_rx_i, dataIn[7:1]});
        end


`endif // FORMAL

endmodule   