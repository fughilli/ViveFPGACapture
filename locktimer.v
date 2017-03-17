module locktimer (
    input clk,  // clock
    input rst,  // reset

    input sync_pulse, // pulse train of same period as this locktimer

    output [WIDTH - 1 : 0] count_out,
    output reg out,
    output wire mask_out,
    output wire back_porch,
    output wire front_porch,
    output wire locked_out
  );

  parameter WIDTH = 32;
  parameter DIV = 2;
  parameter PERIOD = 1000;
  parameter DUTY_CYCLE = 10;

  parameter __DIV_C = 8'b01 << DIV;
  parameter __FZ_MARK = DUTY_CYCLE * 2;
  parameter __CZ_MARK = PERIOD - (__FZ_MARK);

  parameter LOCKED_MAX = 5'b11111;
  parameter LOCKED_THRESH = LOCKED_MAX / 2;
  // The maximum phase offset in a cycle for which the PLL is still considered "locked"
  parameter LOCKED_PHASE_THRESH = DUTY_CYCLE / 4;

  /* The amount to adjust the phase by when a signal is detected in the center of a
   * pulse window
   */
  parameter PHASE_CENTER_ADJ = DUTY_CYCLE / 4;

  reg signed [WIDTH - 1 : 0] count;
  reg [7 : 0] div_count;

  reg [4 : 0] locked;

  /* Front, center, and back zone counters. The marks for these zones are given by
   * __FZ_MARK and __CZ_MARK.
   */
  reg signed [WIDTH - 1 : 0] fz_count;
  reg signed [WIDTH - 1 : 0] cz_count;
  reg signed [WIDTH - 1 : 0] bz_count;

  reg signed [WIDTH - 1 : 0] phase_offset;

  // The masked sync pulse (masked when PLL is locked)
  wire sync_pulse_p;

  always @(posedge clk) begin

    if (rst) begin
      count <= 0;
      div_count <= 0;
      out <= 0;
      locked <= 0;
    end else begin

      // Divide the clock by DIV
      div_count <= ((div_count + 8'b01) == __DIV_C) ? (0) : (div_count + 1);

      if(div_count == 0) begin

        if (count >= /*$signed*/(PERIOD - 1)) begin
          /* If the counter has elapsed, compute the phase offset for this period,
           * and apply that phase offset to the count. If the counter has been offset
           * backwards, don't output a pulse at the next match so that the next period
           * gets stretched by the offset (as opposed to having a short period of
           * length abs(phase_offset)).
           */
          phase_offset <= (((bz_count - fz_count) / 2) +
                           (cz_count ? PHASE_CENTER_ADJ : 0)); /* +
                           ((((bz_count > fz_count) ? (bz_count - fz_count) : (fz_count - bz_count)) > (DUTY_CYCLE * 2)) ? (PERIOD / 4) : (0)) +
                           (((bz_count + fz_count) > (DUTY_CYCLE / 2)) ? (PERIOD / 8) : (0))); */

          out <= 1;
          count <= phase_offset;

          if(phase_offset < LOCKED_PHASE_THRESH && phase_offset > -LOCKED_PHASE_THRESH) begin
            if(locked < LOCKED_MAX) begin
              locked <= locked + 1;
            end
          end else begin
            if(locked > 0) begin
              locked <= locked - 1;
            end
          end

          // Reset the zone counters
          fz_count <= 0;
          cz_count <= 0;
          bz_count <= 0;

        end else begin
          count <= count + 1;
          out <= 0;
        end

        if (sync_pulse_p) begin
          if (count < (__FZ_MARK - 1)) begin
            fz_count <= fz_count + 1;
          end else if (count < (__CZ_MARK - 1)) begin
            cz_count <= cz_count + 1;
          end else begin
            bz_count <= bz_count + 1;
          end
        end
      end
    end
  end

  assign sync_pulse_p = (locked > LOCKED_THRESH) ? (sync_pulse & ~mask_out) : (sync_pulse);
  assign locked_out = (locked > LOCKED_THRESH);
  assign mask_out = ((count >= (__FZ_MARK + DUTY_CYCLE - 1)) && (count < (__CZ_MARK - DUTY_CYCLE - 1)));
  assign back_porch = (count >= (__CZ_MARK - 1));
  assign front_porch = (count <= (__FZ_MARK - 1));
  assign count_out = count;

endmodule
