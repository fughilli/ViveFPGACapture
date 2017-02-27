module spi_memory (
    input clk,  // clock
    input rst,  // reset
    input reset_addr,
    input incr,
    input [15 : 0] F, 
    input [15 : 0] C, 
    input [15 : 0] L, 
    input [15 : 0] R,
    output [7:0] out_byte
  );
  
  wire [7 : 0] bytes [7:0];
  
  reg [3:0] addr;
  
  reg incr_d;
  
  assign bytes[0] = {F[15:8],F[7:0]};
  assign bytes[1] = {C[15:8],C[7:0]};
  assign bytes[2] = {L[15:8],L[7:0]};
  assign bytes[3] = {R[15:8],R[7:0]};
  
  always @(posedge clk) begin
    if (rst || reset_addr) begin
      addr <= 0;
      incr_d <= 0;
    end else begin
      if (incr && !incr_d) begin
        addr <= addr + 1;
      end
    end
    
    incr_d <= incr;
  end
  
  assign out_byte = bytes[addr];
  
endmodule
