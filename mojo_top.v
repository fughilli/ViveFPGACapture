module mojo_top (
    input clk,
    input rst_n,
    output reg [7:0] led,
    input cclk,
    output reg spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    output reg [3:0] spi_channel,
    input avr_tx,
    output reg avr_rx,
    input avr_rx_busy,
    input sens_F,
    input sens_C,
    input sens_L,
    input sens_R,
    output reg [7:0] la,
    output reg s_spi_miso,
    input s_spi_mosi,
    input s_spi_clk,
    input s_spi_ss,
    output reg data_ready,
    output which_sweep_out
  );

  reg rst;

  reg sens_and_all_buf;

  reg which_sweep;

  reg sens_F_mask;
  reg sens_C_mask;
  reg sens_L_mask;
  reg sens_R_mask;

  reg all_ready;

  reg n_sens_F;
  reg n_sens_C;
  reg n_sens_L;
  reg n_sens_R;

  wire [1-1:0] M_reset_cond_out;
  reg [1-1:0] M_reset_cond_in;
  reset_conditioner reset_cond (
    .clk(clk),
    .in(M_reset_cond_in),
    .out(M_reset_cond_out)
  );
  wire [18-1:0] M_all_locktimer_count_out;
  wire [1-1:0] M_all_locktimer_out;
  wire [1-1:0] M_all_locktimer_mask_out;
  wire [1-1:0] M_all_locktimer_back_porch;
  wire [1-1:0] M_all_locktimer_front_porch;
  wire [1-1:0] M_all_locktimer_locked_out;
  reg [1-1:0] M_all_locktimer_sync_pulse;
  locktimer #(.WIDTH(5'h12), .PERIOD(15'h65ba), .DIV(3'h4), .DUTY_CYCLE(8'hdc)) all_locktimer (
    .clk(clk),
    .rst(rst),
    .sync_pulse(M_all_locktimer_sync_pulse),
    .count_out(M_all_locktimer_count_out),
    .out(M_all_locktimer_out),
    .mask_out(M_all_locktimer_mask_out),
    .back_porch(M_all_locktimer_back_porch),
    .front_porch(M_all_locktimer_front_porch),
    .locked_out(M_all_locktimer_locked_out)
  );
  wire [1-1:0] M_spi_out_miso;
  wire [1-1:0] M_spi_out_done;
  wire [8-1:0] M_spi_out_dout;
  reg [1-1:0] M_spi_out_ss;
  reg [1-1:0] M_spi_out_mosi;
  reg [1-1:0] M_spi_out_sck;
  reg [8-1:0] M_spi_out_din;
  spi_slave spi_out (
    .clk(clk),
    .rst(rst),
    .ss(M_spi_out_ss),
    .mosi(M_spi_out_mosi),
    .sck(M_spi_out_sck),
    .din(M_spi_out_din),
    .miso(M_spi_out_miso),
    .done(M_spi_out_done),
    .dout(M_spi_out_dout)
  );
  wire [8-1:0] M_spi_mem_out_byte;
  wire [4-1:0] M_spi_mem_addr_out;
  reg [1-1:0] M_spi_mem_reset_addr;
  reg [1-1:0] M_spi_mem_incr;
  reg [16-1:0] M_spi_mem_F;
  reg [16-1:0] M_spi_mem_C;
  reg [16-1:0] M_spi_mem_L;
  reg [16-1:0] M_spi_mem_R;
  reg [1-1:0] M_spi_mem_latch;
  spi_memory spi_mem (
    .clk(clk),
    .rst(rst),
    .reset_addr(M_spi_mem_reset_addr),
    .incr(M_spi_mem_incr),
    .F(M_spi_mem_F),
    .C(M_spi_mem_C),
    .L(M_spi_mem_L),
    .R(M_spi_mem_R),
    .latch(M_spi_mem_latch),
    .out_byte(M_spi_mem_out_byte),
    .addr_out(M_spi_mem_addr_out)
  );
  wire [18-1:0] M_cap_F_center_out;
  wire [1-1:0] M_cap_F_ready;
  reg [1-1:0] M_cap_F_signal;
  capture_center #(.WIDTH(5'h12)) cap_F (
    .clk(clk),
    .rst(rst),
    .counter(M_all_locktimer_count_out),
    .clr_ready(M_all_locktimer_out),
    .signal(M_cap_F_signal),
    .center_out(M_cap_F_center_out),
    .ready(M_cap_F_ready)
  );
  wire [18-1:0] M_cap_C_center_out;
  wire [1-1:0] M_cap_C_ready;
  reg [1-1:0] M_cap_C_signal;
  capture_center #(.WIDTH(5'h12)) cap_C (
    .clk(clk),
    .rst(rst),
    .counter(M_all_locktimer_count_out),
    .clr_ready(M_all_locktimer_out),
    .signal(M_cap_C_signal),
    .center_out(M_cap_C_center_out),
    .ready(M_cap_C_ready)
  );
  wire [18-1:0] M_cap_L_center_out;
  wire [1-1:0] M_cap_L_ready;
  reg [1-1:0] M_cap_L_signal;
  capture_center #(.WIDTH(5'h12)) cap_L (
    .clk(clk),
    .rst(rst),
    .counter(M_all_locktimer_count_out),
    .clr_ready(M_all_locktimer_out),
    .signal(M_cap_L_signal),
    .center_out(M_cap_L_center_out),
    .ready(M_cap_L_ready)
  );
  wire [18-1:0] M_cap_R_center_out;
  wire [1-1:0] M_cap_R_ready;
  reg [1-1:0] M_cap_R_signal;
  capture_center #(.WIDTH(5'h12)) cap_R (
    .clk(clk),
    .rst(rst),
    .counter(M_all_locktimer_count_out),
    .clr_ready(M_all_locktimer_out),
    .signal(M_cap_R_signal),
    .center_out(M_cap_R_center_out),
    .ready(M_cap_R_ready)
  );

  reg M_all_locktimer_out_q;

  always @(posedge clk) begin
    M_reset_cond_in = ~rst_n;
    rst = M_reset_cond_out;
    led = {M_all_locktimer_locked_out, 7'h00};
    spi_miso = 1'bz;
    spi_channel = 4'bzzzz;
    avr_rx = 1'bz;
    n_sens_F = !sens_F;
    n_sens_C = !sens_C;
    n_sens_L = !sens_L;
    n_sens_R = !sens_R;
    sens_and_all_buf = n_sens_F & n_sens_C & n_sens_L & n_sens_R;
    M_all_locktimer_sync_pulse = sens_and_all_buf;
    sens_F_mask = n_sens_F & M_all_locktimer_mask_out;
    sens_C_mask = n_sens_C & M_all_locktimer_mask_out;
    sens_L_mask = n_sens_L & M_all_locktimer_mask_out;
    sens_R_mask = n_sens_R & M_all_locktimer_mask_out;
    M_cap_F_signal = sens_F_mask;
    M_cap_C_signal = sens_C_mask;
    M_cap_L_signal = sens_L_mask;
    M_cap_R_signal = sens_R_mask;
    all_ready = (M_cap_F_ready & M_cap_C_ready & M_cap_L_ready & M_cap_R_ready) | M_all_locktimer_back_porch;
    M_spi_mem_incr = M_spi_out_done;
    M_spi_out_din = M_spi_mem_out_byte;
    M_spi_mem_latch = all_ready;
    data_ready = all_ready;
    M_spi_mem_reset_addr = !all_ready;
    M_spi_out_mosi = s_spi_mosi;
    M_spi_out_sck = s_spi_clk;
    M_spi_out_ss = s_spi_ss;
    s_spi_miso = M_spi_out_miso;
    M_spi_mem_F = M_cap_F_center_out[0+15-:16];
    M_spi_mem_C = M_cap_C_center_out[0+15-:16];
    M_spi_mem_L = M_cap_L_center_out[0+15-:16];
    M_spi_mem_R = M_cap_R_center_out[0+15-:16];
    la[0+0-:1] = sens_and_all_buf;
    la[1+0-:1] = M_all_locktimer_out;
    la[2+0-:1] = sens_F_mask;
    la[4+0-:1] = sens_C_mask;
    la[3+0-:1] = M_cap_F_ready;
    la[5+0-:1] = M_cap_C_ready;
    la[6+0-:1] = all_ready;
    la[7+0-:1] = M_all_locktimer_mask_out;

    if (M_all_locktimer_out && !M_all_locktimer_out_q)
    begin
        which_sweep = !which_sweep;
    end
    M_all_locktimer_out_q = M_all_locktimer_out;
  end

  assign which_sweep_out = which_sweep;
endmodule
