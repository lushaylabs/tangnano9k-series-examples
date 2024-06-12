
module framebuffer(
    input  wire       clk,    // main clock
    input  wire [5:0] column, // column index (6 bits for 64 pixels)
    input  wire [3:0] ADDR,   // ADDR input
    output wire [2:0] RGB0,   // RGB0 output
    output wire [2:0] RGB1    // RGB1 output
);
    wire[9:0] addr_rom;
    assign addr_rom = {ADDR, column};

    ROMTop  rom_low(.clk(clk), .addr(addr_rom),.data(RGB0));
    ROMBottom rom_high(.clk(clk), .addr(addr_rom),.data(RGB1));
endmodule


module framebuffer2Bit(
    input  wire       clk,    // main clock
    input  wire [5:0] column, // column index (6 bits for 64 pixels)
    input  wire [3:0] ADDR,   // ADDR input
    output wire [2:0] RGB0,   // RGB0 output
    output wire [2:0] RGB1,    // RGB1 output
    input wire[1:0] colorCycle
);
    wire[9:0] addr_rom;
    assign addr_rom = {ADDR, column};

    wire [5:0] topRGB;
    wire [5:0] bottomRGB;

    ROMTop  rom_low(.clk(clk), .addr(addr_rom),.data(topRGB));
    ROMBottom rom_high(.clk(clk), .addr(addr_rom),.data(bottomRGB));

    assign RGB0 = {
        (colorCycle < topRGB[5:4]),
        (colorCycle < topRGB[3:2]),
        (colorCycle < topRGB[1:0])
    };
    assign RGB1 = {
        (colorCycle < bottomRGB[5:4]),
        (colorCycle < bottomRGB[3:2]),
        (colorCycle < bottomRGB[1:0])
    };
endmodule
