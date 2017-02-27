module locktimer (
    input clk,  // clock
    input rst,  // reset
    
    input sync_pulse, // pulse train of same period as this locktimer
    
    output [WIDTH - 1 : 0] count_out,
    output reg out,
    output wire mask_out
  );
  
  parameter WIDTH = 32;
  parameter DIV = 2;
  parameter PERIOD = 1000;
  parameter DUTY_CYCLE = 10;
  
  parameter __DIV_C = 8'b01 << DIV;
  parameter __FZ_MARK = DUTY_CYCLE * 2;
  parameter __CZ_MARK = PERIOD - (__FZ_MARK);
  
  reg signed [WIDTH - 1 : 0] count;
  reg [7 : 0] div_count;
  
  /* Front, center, and back zone counters. The marks for these zones are given by
   * __FZ_MARK and __CZ_MARK.
   */
  reg signed [WIDTH - 1 : 0] fz_count;
  reg signed [WIDTH - 1 : 0] cz_count;
  reg signed [WIDTH - 1 : 0] bz_count;
  
  reg signed [WIDTH - 1 : 0] phase_offset;
  
  always @(posedge clk) begin
  
    if (rst) begin
      count <= 0;
      div_count <= 0;
      out <= 0;
      //mask_out <= 0;
    end else begin
    
      // Divide the clock by DIV
      div_count <= ((div_count + 8'b01) == __DIV_C) ? (0) : (div_count + 1);
      
      if(div_count == 0) begin
      
        if (count >= (PERIOD - 1)) begin
          /* If the counter has elapsed, compute the phase offset for this period,
           * and apply that phase offset to the count. If the counter has been offset
           * backwards, don't output a pulse at the next match so that the next period
           * gets stretched by the offset (as opposed to having a short period of
           * length abs(phase_offset)).
           */  
          phase_offset <= (((bz_count - fz_count) >>> 1) +
                           (cz_count ? 100 : 0)); /* +
                           ((((bz_count > fz_count) ? (bz_count - fz_count) : (fz_count - bz_count)) > (DUTY_CYCLE * 2)) ? (PERIOD / 4) : (0)) +
                           (((bz_count + fz_count) > (DUTY_CYCLE / 2)) ? (PERIOD / 8) : (0))); */
          
          out <= 1;
          count <= phase_offset;
          
          // Reset the zone counters
          fz_count <= 0;
          cz_count <= 0;
          bz_count <= 0;
                    
        end else begin
          count <= count + 1;
          out <= 0;
        end
        
        if (sync_pulse) begin
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
  
  assign mask_out = ((count >= (__FZ_MARK - 1)) && (count < (__CZ_MARK - 1)));
  
  assign count_out = count;
  
endmodule
