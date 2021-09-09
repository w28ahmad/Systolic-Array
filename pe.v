`timescale 1 ps / 1 ps

module pe
#(
    parameter   D_W_ACC  = 64, //accumulator data width
    parameter   D_W      = 32  //operand data width
)
(
    input   wire                    clk,
    input   wire                    rst,
    input   wire                    init,
    input   wire    [D_W-1:0]       in_a,
    input   wire    [D_W-1:0]       in_b,
    output  reg     [D_W-1:0]       out_b,
    output  reg     [D_W-1:0]       out_a,

    input   wire    [(D_W_ACC)-1:0] in_data,
    input   wire                    in_valid,
    output  reg     [(D_W_ACC)-1:0] out_data,
    output  reg                     out_valid=0
);

// Insert your RTL here
reg [D_W_ACC-1:0] out_data_temp=0;

reg valid_r0=0;
reg [D_W_ACC-1:0] out_data_r0=0;

/* Set valid and out_data for current pe */
always @(posedge clk) begin
    if(rst) begin
        out_data <= 0;
        out_valid <= 0;
    end else if(init) begin
        out_valid <= 1'b1;
        out_data <= out_data_temp;
    end else begin
        out_valid <= 1'b0;
    end

    /* Transfer in_data to out_data */
    if(valid_r0) begin
        out_valid <= valid_r0;
        out_data <= out_data_r0;
    end
end

/* Set valid and out_data from previous pe */
always @(posedge clk) begin
    if(rst) begin
        valid_r0 <= 0;
        out_data_r0 <= 0;
    end else if(in_valid) begin
        valid_r0 <= 1'b1;
        out_data_r0 <= in_data;
    end else begin
        valid_r0 <= 1'b0;
        out_data_r0 <= 0;
    end

end

/* Multiply and accumulate */
always @(posedge clk) begin
    if(rst) begin
        out_data_temp <= 0;
        out_a <= 0;
        out_b <= 0;
    end else begin
        if(init)    out_data_temp <= in_a * in_b;
        else        out_data_temp <= in_a * in_b + out_data_temp;
        out_a <= in_a;
        out_b <= in_b;
    end
end
 
endmodule
