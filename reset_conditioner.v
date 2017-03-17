module reset_conditioner (
    input clk,  // clock
    input in,   // async reset
    output reg out  // snyc reset
  );

  parameter STAGES = 4;
  //dff stage[STAGES] (.clk(clk), .rst(in), #INIT(STAGESx{1}));

  reg [STAGES - 1:0] stage;

  always @(posedge clk) begin
    if(in) begin
      stage <= {STAGES{1'b1}};
      out <= 1;
    end else begin
      stage <= {stage[STAGES-2:0],1'b0};
      out <= stage[STAGES-1];
    end
  end

endmodule
