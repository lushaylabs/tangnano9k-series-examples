module clock_divisor (
    input  wire clk,
    output wire clk_out
);
    reg[4:0] counter = 0;
    assign clk_out = counter[4];
    always @(posedge clk) counter <= counter + 1;
endmodule
