module screen #(
`ifdef FORMAL
    parameter STARTUP_WAIT = 32'd25
`else
    parameter STARTUP_WAIT = 32'd10000000
`endif
)
(
    input   clk_i,
    input   reset_i,
    // OLED
    output  io_sclk_o,
    output  io_sdin_o,
    output  io_cs_o,
    output  io_dc_o,
    output  io_reset_o,
    output  [9:0] pixelAddress_i,
    input   [7:0] pixelData_i
);
  localparam STATE_INIT_POWER = 8'd0;
  localparam STATE_LOAD_INIT_CMD = 8'd1;
  localparam STATE_SEND = 8'd2;
  localparam STATE_CHECK_FINISHED_INIT = 8'd3;
  localparam STATE_LOAD_DATA = 8'd4;

  localparam STARTUP_WAIT_2x = 2 * STARTUP_WAIT;
  localparam STARTUP_WAIT_3x = 3 * STARTUP_WAIT;
  localparam STARTUP_WAIT_MAX = STARTUP_WAIT_3x;

  localparam MAX_NUMBER_OF_PIXELS = 136;

  reg [32:0] counter = 0;
  reg [2:0] state = STATE_INIT_POWER;
  
  reg dc = 1;
  reg sclk = 1;
  reg sdin = 0;
  reg reset = 1;
  reg cs = 0;
  
  reg [7:0] dataToSend = 0;
  reg [3:0] bitNumber = 0;  
  reg [9:0] pixelCounter = 0;

  localparam SETUP_INSTRUCTIONS = 23;
  reg [(SETUP_INSTRUCTIONS*8)-1:0] startupCommands = {
                                                        8'hAE,  // display off
                                                        8'h81,  // contast value to 0x7F according to datasheet
                                                        8'h7F,  
                                                        8'hA6,  // normal screen mode (not inverted)
                                                        8'h20,  // horizontal addressing mode
                                                        8'h00,  
                                                        8'hC8,  // normal scan direction
                                                        8'h40,  // first line to start scanning from
                                                        8'hA1,  // address 0 is segment 0
                                                        8'hA8,  // mux ratio
                                                        8'h3f,  // 63 (64 -1)
                                                        8'hD3,  // display offset
                                                        8'h00,  // no offset
                                                        8'hD5,  // clock divide ratio
                                                        8'h80,  // set to default ratio/osc frequency
                                                        8'hD9,  // set precharge
                                                        8'h22,  // switch precharge to 0x22 default
                                                        8'hDB,  // vcom deselect level
                                                        8'h20,  // 0x20 
                                                        8'h8D,  // charge pump config
                                                        8'h14,  // enable charge pump
                                                        8'hA4,  // resume RAM content
                                                        8'hAF   // display on
                                                    };
  reg [7:0] commandIndex = SETUP_INSTRUCTIONS * 8;

  assign io_sclk_o = sclk;
  assign io_sdin_o = sdin;
  assign io_dc_o = dc;
  assign io_reset_o = reset;
  assign io_cs_o = cs;

  // State Machine
  always @(posedge clk_i) begin
    if(reset_i) begin
        counter <= 0;
        state <= STATE_INIT_POWER;
        dc <= 1;
        sclk <= 1;
        sdin <= 0;
        reset <= 1;
        cs <= 0;
        dataToSend <= 0;
        bitNumber <= 0;  
        pixelCounter <= 0;
    end else begin
        case (state)
            STATE_INIT_POWER: begin
                counter <= counter + 1;
                if (counter < STARTUP_WAIT)
                    reset <= 1;
                else if (counter < STARTUP_WAIT_2x)
                    reset <= 0;
                else if (counter < STARTUP_WAIT_3x)
                    reset <= 1;
                else begin
                    state <= STATE_LOAD_INIT_CMD;
                    counter <= 32'b0;
                end
            end
            STATE_LOAD_INIT_CMD: begin
                dc <= 0;
                dataToSend <= startupCommands[(commandIndex-1)-:8'd8];
                state <= STATE_SEND;
                bitNumber <= 3'd7;
                cs <= 0;
                commandIndex <= commandIndex - 8'd8;
            end
            STATE_SEND: begin
                if (counter == 32'd0) begin
                    sclk <= 0;
                    sdin <= dataToSend[bitNumber];
                    counter <= 32'd1;
                end else begin
                    counter <= 32'd0;
                    sclk <= 1;
                    if (bitNumber == 0)
                        state <= STATE_CHECK_FINISHED_INIT;
                    else
                        bitNumber <= bitNumber - 1;
                end
            end
            STATE_CHECK_FINISHED_INIT: begin
                cs <= 1;
                if (commandIndex == 0)
                    state <= STATE_LOAD_DATA; 
                else
                    state <= STATE_LOAD_INIT_CMD; 
            end
            STATE_LOAD_DATA: begin
                pixelCounter <= pixelCounter + 1;
                cs <= 0;
                dc <= 1;
                bitNumber <= 3'd7;
                state <= STATE_SEND;
                dataToSend <= pixelData_i;
            end
        endcase
    end
  end

  assign pixelAddress_i = pixelCounter;

//
// FORMAL VERIFICATION
//
`ifdef FORMAL

    `ifdef SCREEN
		`define	ASSUME	assume
	`else
		`define	ASSUME	assert
	`endif

    // f_past_valid
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge clk_i)
		f_past_valid <= 1'b1;

    // Prove that state is always in a valid state
    always@(*)
        if((f_past_valid)&&(!reset_i))
            assert(state <= STATE_LOAD_DATA);

    // Prove that counter is always valid
    always @(*)
        if((f_past_valid)&&(!reset_i))
            assert(counter <= STARTUP_WAIT_MAX);

    // Prove that after a reset registers get initialized
    always @(posedge clk_i) begin
        if(($past(f_past_valid))&&($past(reset_i))) begin
            assert(counter == 0);
            assert(state == STATE_INIT_POWER);
            assert(dc == 1);
            assert(sclk == 1);
            assert(sdin == 0);
            assert(reset == 1);
            assert(cs == 0);
            assert(dataToSend == 0);
            assert(bitNumber == 0);  
            assert(pixelCounter == 0);
        end
    end

    //
    // Contract
    //
    always @(posedge clk_i) begin
        if((f_past_valid)&&($past(f_past_valid))&&(!reset_i)&&(!$past(reset_i))) begin
            case($past(state))
                STATE_INIT_POWER: begin
                    if(state == STATE_INIT_POWER)
                        assert(counter == ($past(counter)+1));
                    // reset
                    if (counter <= STARTUP_WAIT)
                        assert(reset == 1);
                    else if (counter <= STARTUP_WAIT_2x)
                        assert(reset == 0);
                    else if (counter <= STARTUP_WAIT_3x)
                        assert(reset == 1);
                end
                STATE_LOAD_INIT_CMD: begin
                    assert(dc == 0);
                    assert(cs == 0);
                    assert(bitNumber == 3'd7);
                    assert(commandIndex == $past(commandIndex - 8'd8));
                    assert(dataToSend == startupCommands[($past(commandIndex)-1)-:8'd8]);
                end
                STATE_SEND: begin
                    if ($past(counter) == 32'd0) begin
                        assert(sclk == 0);
                        assert(sdin == $past(dataToSend[bitNumber]));
                        assert(counter == 32'd1);
                    end else begin
                        assert(counter == 32'd0);
                        assert(sclk == 1);
                        if (bitNumber != 0)
                            assert(bitNumber == $past(bitNumber-1));
                    end
                end
                STATE_CHECK_FINISHED_INIT:  assert(cs == 1);
                STATE_LOAD_DATA: begin
                    if(pixelCounter != 0)
                        assert(pixelCounter == $past(pixelCounter+1));
                    assert(cs == 0);
                    assert(dc == 1);
                    assert(bitNumber == 3'd7);
                    assert(dataToSend == $past(pixelData_i));
                end
                default: assert(0); // We should never ever be here
            endcase
        end
    end



`endif // FORMAL

endmodule