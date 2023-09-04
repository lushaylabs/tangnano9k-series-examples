module composite_count_test (
    input wire clk,
    output reg [9:0] y = 0,
    output wire hsync,
    output wire vsync,
    output wire hblank,
    output wire vblank,
    output wire active_video
);
  localparam CLOCK_CYCLES_PER_LINE = 12'd1718;
  localparam CLOCK_CYCLES_FOR_HALF_LINE = CLOCK_CYCLES_PER_LINE/2;
  localparam CLOCK_CYCLES_FOR_HSYNC = 12'd128;
  localparam CLOCK_CYCLES_FOR_BACK_PORCH = 12'd120;
  localparam CLOCK_CYCLES_FOR_FRONT_PORCH = 12'd41;
  localparam CLOCK_CYCLES_FOR_VIDEO = CLOCK_CYCLES_PER_LINE - CLOCK_CYCLES_FOR_HSYNC - CLOCK_CYCLES_FOR_BACK_PORCH - CLOCK_CYCLES_FOR_FRONT_PORCH;
  localparam CLOCK_CYCLES_FOR_VSYNC = 12'd738;
  localparam CLOCK_CYCLES_FOR_VSYNC_BLANK = CLOCK_CYCLES_FOR_HALF_LINE - CLOCK_CYCLES_FOR_VSYNC;

  reg is_vsync_line = 1;
  reg is_blanking_line = 0;
  reg is_active_line = 0;
  reg [11:0] clock_counter = 0;
  
  always @(posedge clk) begin
    clock_counter <= clock_counter + 1;
    if (clock_counter == CLOCK_CYCLES_PER_LINE) begin
        clock_counter <= 0;
        y <= (y == 10'd261) ? 0 : y + 10'd1;
        if (is_vsync_line & y == 2) begin
          is_blanking_line <= 1;
          is_active_line <= 0;
          is_vsync_line <= 0;
        end
        else if (is_blanking_line & y == 16) begin
          is_blanking_line <= 0;
          is_active_line <= 1;
          is_vsync_line <= 0;
        end
        else if (is_active_line & y == 256) begin
          is_blanking_line <= 1;
          is_active_line <= 0;
          is_vsync_line <= 0;
        end
        else if (is_blanking_line & y == 261) begin
          is_blanking_line <= 0;
          is_active_line <= 0;
          is_vsync_line <= 1;
        end
    end
  end

  wire first_half = clock_counter < CLOCK_CYCLES_FOR_HALF_LINE;
  assign vsync = is_vsync_line & (
    first_half ? 
      clock_counter < CLOCK_CYCLES_FOR_VSYNC : 
      clock_counter < (CLOCK_CYCLES_FOR_VSYNC + CLOCK_CYCLES_FOR_HALF_LINE)
    );
  assign hsync = clock_counter < CLOCK_CYCLES_FOR_HSYNC & ~is_vsync_line;
  
  localparam START_OF_VIDEO = CLOCK_CYCLES_FOR_HSYNC + CLOCK_CYCLES_FOR_BACK_PORCH;
  localparam END_OF_VIDEO = START_OF_VIDEO + CLOCK_CYCLES_FOR_VIDEO;
  assign vblank =  ~is_active_line;
  assign hblank = clock_counter < START_OF_VIDEO | clock_counter >= END_OF_VIDEO;

  assign active_video = is_active_line;
endmodule