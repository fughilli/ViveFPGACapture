module capture_center (
    input clk,
    input rst,  // reset
    input signal,
    input clr_ready,

    input [WIDTH - 1:0] counter,
    output reg [WIDTH - 1:0] center_out,
    output reg ready
  );

  parameter WIDTH = 32;

  reg [WIDTH - 1:0] center_buffer;

  reg signal_d;

  always @(posedge clk) begin
    if (rst) begin
      center_out <= 0;
      ready <= 0;
      signal_d <= 0;
    end else begin
      if (clr_ready) begin
        ready <= 0;
      end else begin
        if (!signal && signal_d) begin // Falling edge
          center_out <= (center_buffer + counter) / 2;
          ready <= 1;
        end

        if (signal && !signal_d) begin // Rising edge
          center_buffer <= counter;
          ready <= 0;
        end

        signal_d <= signal;
      end
    end
  end
endmodule
