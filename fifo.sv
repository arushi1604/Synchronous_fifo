module fifo #(parameter DATA_WIDTH = 8, parameter FIFO_DEPTH = 16)
(input  logic clk,
 input  logic rst,
 input  logic wr_en,
 input  logic rd_en,
 input  logic [DATA_WIDTH-1:0] data_in,
 output logic [DATA_WIDTH-1:0] data_out,
 output logic full,
 output logic empty,
 output logic overflow,
 output logic underflow,
 output logic [$clog2(FIFO_DEPTH+1)-1:0] count);

localparam ADDR_WIDTH=$clog2(FIFO_DEPTH);
logic [DATA_WIDTH-1:0] mem[0:FIFO_DEPTH-1];
logic [ADDR_WIDTH-1:0] wr_ptr;
logic [ADDR_WIDTH-1:0] rd_ptr;

assign empty=(count==0);
assign full=(count==FIFO_DEPTH);

always_ff@(posedge clk) 
begin
 if(rst) 
  begin
    wr_ptr<=0;
    rd_ptr<=0;
    count<=0;
    data_out<=0;
    overflow<=0;
    underflow<=0;
  end
 else 
  begin
    overflow<=0;
    underflow<=0;

    //write logic
    if(wr_en) begin
    if(!full) begin
       mem[wr_ptr]<=data_in;
    if(wr_ptr==FIFO_DEPTH-1)
       wr_ptr<=0;
    else
       wr_ptr<=wr_ptr+1;
    end
    else begin
       overflow<=1;
    end
    end

    //read logic
    if(rd_en) begin
    if(!empty) begin
       data_out<=mem[rd_ptr];
    if(rd_ptr==FIFO_DEPTH-1)
       rd_ptr<=0;
    else
       rd_ptr<=rd_ptr+1;
    end
    else begin
       underflow<=1;
    end
    end

    //counter logic
    case ({wr_en && !full, rd_en && !empty})
         2'b10: count<=count+1;
         2'b01: count<=count-1;
         default: count<=count;
    endcase
    end
    end
endmodule