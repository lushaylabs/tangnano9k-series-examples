`timescale 1ns/1ns

module test();
  reg clk = 0;
  reg sync = 0;
  wire sclk, sdin, dc, reset, cs;

  top #(10) t (
    clk,
    sclk,
    sdin,
    cs,
    dc,
    reset
);

  always
    #1  clk=~clk;

  initial
    begin
      #25000 $finish;
    end
  initial
     begin
       $dumpfile("text.vcd");
       $dumpvars(0,test);
      end
endmodule
