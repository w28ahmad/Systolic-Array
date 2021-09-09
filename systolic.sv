`default_nettype none

module systolic
#
(
    parameter   D_W  = 8, //operand data width
    parameter   D_W_ACC = 16, //accumulator data width
    parameter   N1   = 4,
    parameter   N2   = 4,
    parameter   M    = 8
)
(
    input   wire                                        clk,
    input   wire                                        rst,
    input   wire                                        enable_row_count_A,
    output  wire    [$clog2(M)-1:0]                     pixel_cntr_A,
    output  wire    [($clog2(M/N1)?$clog2(M/N1):1)-1:0] slice_cntr_A,
    output  wire    [($clog2(M/N2)?$clog2(M/N2):1)-1:0] pixel_cntr_B,
    output  wire    [$clog2(M)-1:0]                     slice_cntr_B,
    output  wire    [$clog2((M*M)/N1)-1:0]              rd_addr_A,
    output  wire    [$clog2((M*M)/N2)-1:0]              rd_addr_B,
    input   wire    [D_W-1:0]                           A [N1-1:0], //m0
    input   wire    [D_W-1:0]                           B [N2-1:0], //m1
    output  wire    [D_W_ACC-1:0]                       D [N1-1:0], //m2
    output  wire    [N1-1:0]                             valid_D
);

wire    [D_W-1:0]         out_a      [N1-1:0][N2-1:0];
wire    [D_W-1:0]         out_b      [N1-1:0][N2-1:0];
wire    [D_W-1:0]         in_a       [N1-1:0][N2-1:0];
wire    [D_W-1:0]         in_b       [N1-1:0][N2-1:0];
wire    [N2-1:0]          in_valid   [N1-1:0];
wire    [N2-1:0]          out_valid  [N1-1:0];
wire    [(D_W_ACC)-1:0]   in_data    [N1-1:0][N2-1:0];
wire    [(D_W_ACC)-1:0]   out_data   [N1-1:0][N2-1:0];

wire    [N2-1:0] init_pe  [N1-1:0];
reg [($clog2(M/N1)?$clog2(M/N1):1)-1:0] slice_sync;
reg [($clog2(M/N2)?$clog2(M/N2):1)-1:0] pixel_sync;
reg init_pe_reg [N1-1:0][N2-1:0];

control #
(
  .N1       (N1),
  .N2       (N2),
  .M        (M),
  .D_W      (D_W),
  .D_W_ACC  (D_W_ACC)
)
control_inst
(

  .clk                  (clk),
  .rst                  (rst),
  .enable_row_count     (enable_row_count_A),

  .pixel_cntr_B         (pixel_cntr_B),
  .slice_cntr_B         (slice_cntr_B),

  .pixel_cntr_A         (pixel_cntr_A),
  .slice_cntr_A         (slice_cntr_A),

  .rd_addr_A            (rd_addr_A),
  .rd_addr_B            (rd_addr_B)
);


// enter your RTL here

/* Instantiate 2D grid of PEs */
genvar i;
genvar j;
generate
  for(i=0; i < N1; i=i+1) begin
    for(j=0; j < N2; j=j+1) begin
      pe #(.D_W_ACC(D_W_ACC), .D_W(D_W)) pe_dut(
        .clk          (clk),
        .rst          (rst),
        .init         (init_pe[i][j]),
        .in_a         (in_a[i][j]),
        .in_b         (in_b[i][j]),
        .out_a        (out_a[i][j]),
        .out_b        (out_b[i][j]),
        .in_data      (in_data[i][j]),
        .in_valid     (in_valid[i][j]),
        .out_data     (out_data[i][j]),
        .out_valid    (out_valid[i][j])
      );

      /* Horizontal PE connections */
      if(j==0) assign in_a[i][j] = A[i];
      else assign in_a[i][j] = out_a[i][j-1];

      /* Vertical PE connections */
      if(i==0) assign in_b[i][j] = B[j];
      else assign in_b[i][j] = out_b[i-1][j];

      /* Horizontal valid connections */
      if(j==0) assign in_valid[i][j] = 0;
      else assign in_valid[i][j] = out_valid[i][j-1];

      /* Horizontal data connections */
      if(j==0) assign in_data[i][j] = 0;
      else assign in_data[i][j] = out_data[i][j-1];

      /* Init PE connections */
      assign init_pe[i][j] = init_pe_reg[i][j];

      /* Assign output valid */
      if(j==N2-1) assign valid_D[i] = out_valid[i][j];

      /* Assign ouput Data */
      if(j==N2-1) assign D[i] = out_data[i][j];

      /* Connect regesters to registers to clock in delay */
      always @(posedge clk) begin
        if(rst && i!=0 && j!=0) begin
          init_pe_reg[i][j] <= 0;
        end else begin
          if(j==0 && i!=0) begin
            init_pe_reg[i][j] <= init_pe_reg[i-1][j];
          end else if(j!=0 && i==0) begin 
            init_pe_reg[i][j] <= init_pe_reg[i][j-1];
          end else if(i!=0 && j!=0) begin
            init_pe_reg[i][j] <= init_pe_reg[i][j-1];
          end
        end
      end
    end
  end
endgenerate

always @(posedge clk) begin
  if(rst) begin
    init_pe_reg[0][0] <= 1'b0;
    slice_sync <= 0;
    pixel_sync <= 0;
  end else if(slice_sync != slice_cntr_A || pixel_sync != pixel_cntr_B) begin
    init_pe_reg[0][0] <= 1'b1;
  end else begin
    init_pe_reg[0][0] <= 1'b0;
  end
  slice_sync <= slice_cntr_A;
  pixel_sync <= pixel_cntr_B;
end

endmodule
