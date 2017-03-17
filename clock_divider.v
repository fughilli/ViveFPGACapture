module clock_divider (
    input clk,  // clock
    input rst,  // reset
    output reg out
  );

  parameter WIDTH = 32;
  parameter DIV = 100;
  parameter HALF_DIV = DIV/2;

  parameter _DIV_MATCH = DIV - 1;

  /* Sequential Logic */
  always @(posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin

    end
  end

endmodule
