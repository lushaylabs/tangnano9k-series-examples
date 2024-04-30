`ifdef FORMAL
`default_nettype none
`endif

module counter
(
    input clk,
    output [5:0] led
);

localparam WAIT_TIME = 13500000;
reg [5:0] ledCounter = 0;
reg [23:0] clockCounter = 0;

always @(posedge clk) begin
    clockCounter <= clockCounter + 1;
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 0;
        ledCounter <= ledCounter + 1;
    end
end

assign led = ~ledCounter;

//
// FORMAL VERIFICATION
//
`ifdef FORMAL

    // f_past_valid
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge clk)
		f_past_valid <= 1'b1;

    //
    // clockCounter
    //

    // Prove that counter can't be higher than WAIT_TIME
    always @(*)
        assert(clockCounter <= WAIT_TIME);

    // Prove that counter counts up
    always @(posedge clk)
    if((f_past_valid)&&($past(f_past_valid))) begin
        if(clockCounter == 0)
            assert($past(clockCounter)==WAIT_TIME);
        else
            assert(clockCounter == ($past(clockCounter)+1));
    end

    //
    // ledCounter
    //

    // Prove that counter counts up
    always @(posedge clk)
    if((f_past_valid)&&($past(f_past_valid))) begin
        if(clockCounter == 0) begin
            if(ledCounter == 0)
                assert($past(ledCounter) == 6'b11_1111);
            else
                assert(ledCounter == ($past(ledCounter)+1));
        end
    end

`endif // FORMAL

endmodule