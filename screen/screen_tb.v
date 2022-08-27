`timescale 1ns/1ns

module test();
  reg clk = 0;
  wire sclk, sdin, dc, reset, cs;
  screen #(11'b10) s(
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
      #2000 $finish;
    end
  initial
     begin
       $dumpfile("screen.vcd");
       $dumpvars(0,test);
      end
endmodule
