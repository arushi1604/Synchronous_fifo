`timescale 1ns/1ps
module fifo_tb;
parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=16;

logic clk;
logic rst;
logic wr_en;
logic rd_en;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH-1:0] data_out;
logic full;
logic empty;
logic overflow;
logic underflow;
logic [$clog2(FIFO_DEPTH+1)-1:0] count;

fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) dut (.clk(clk), .rst(rst), .wr_en(wr_en), .rd_en(rd_en), .data_in(data_in), .data_out(data_out), .full(full), .empty(empty), .overflow(overflow), .underflow(underflow), .count(count));

always #5 clk=~clk;
logic [DATA_WIDTH-1:0] expected_queue [0:FIFO_DEPTH-1];
integer queue_count;
integer pass_count;
integer fail_count;
integer i;

task write_data(input [DATA_WIDTH-1:0] data);
begin
@(negedge clk);
data_in=data;
wr_en=1;
rd_en=0;
@(negedge clk);
wr_en=0;
end
endtask

task read_data;
logic [DATA_WIDTH-1:0] expected;
begin
@(negedge clk);
rd_en=1;
wr_en=0;
expected=expected_queue[0];
@(negedge clk);
rd_en=0;
if(data_out===expected) begin
$display("PASS: READ = %h | EXPECTED = %h", data_out, expected);
pass_count=pass_count+1;
end
else begin
$display("FAIL: READ = %h | EXPECTED = %h", data_out, expected);
fail_count=fail_count+1;
end
for(i=0;i<FIFO_DEPTH-1;i=i+1)
expected_queue[i]=expected_queue[i+1];
queue_count=queue_count-1;
end
endtask

initial begin
$dumpfile("fifo.vcd");
$dumpvars(0,fifo_tb);

clk=0;
rst=1;
wr_en=0;
rd_en=0;
data_in=0;
queue_count=0;
pass_count=0;
fail_count=0;

#20;rst=0;

$display("\nTEST 1: BASIC FIFO ORDER");
write_data(8'h11);
expected_queue[queue_count]=8'h11;
queue_count++;
write_data(8'h22);
expected_queue[queue_count]=8'h22;
queue_count++;
write_data(8'h33);
expected_queue[queue_count]=8'h33;
queue_count++;
read_data;
read_data;
read_data;

$display("\nTEST 2: FIFO FULL");
for(i=0;i<FIFO_DEPTH;i=i+1) begin
write_data(i);
expected_queue[queue_count]=i;
queue_count++;
end
#10;
if(full) begin
$display("PASS: FIFO FULL detected");
pass_count++;
end else begin
$display("FAIL: FIFO FULL not detected");
fail_count++;
end

$display("\nTEST 3: OVERFLOW");
write_data(8'hFF);
#1;
if(overflow) begin
$display("PASS: Overflow detected");
pass_count++;
end else begin
$display("FAIL: Overflow not detected");
fail_count++;
end

$display("\nTEST 4: FIFO ORDER CHECK");
while(queue_count>0)
read_data;
#10;
if(empty) begin
$display("PASS: FIFO EMPTY detected");
pass_count++;
end else begin
$display("FAIL: FIFO EMPTY not detected");
fail_count++;
end

$display("\nTEST 5: UNDERFLOW");
@(negedge clk);
rd_en=1;
@(negedge clk);
rd_en=0;
#1;
if (underflow) begin
$display("PASS: Underflow detected");
pass_count++;
end else begin
$display("FAIL: Underflow not detected");
fail_count++;
end

$display("\nTEST 6: SIMULTANEOUS READ AND WRITE");
write_data(8'hA5);
expected_queue[queue_count]=8'hA5;
queue_count++;
@(negedge clk);
data_in=8'h5A;
wr_en=1;
rd_en=1;
@(negedge clk);
wr_en=0;
rd_en=0;
#1;
if (count==1) begin
$display("PASS: Simultaneous R/W maintained correct count=%0d", count);
pass_count++;
end else begin
$display("FAIL: Count mismatch during simultaneous R/W. Expected=1, Got=%0d", count);
fail_count++;
end

$display("\nFINAL RESULT");
$display("PASS COUNT=%0d", pass_count);
$display("FAIL COUNT=%0d", fail_count);
if (fail_count == 0)
$display("FIFO TEST PASSED");
else
$display("FIFO TEST FAILED");
$finish;
end
endmodule