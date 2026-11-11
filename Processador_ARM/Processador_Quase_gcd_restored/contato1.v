module contato1 (clk, clk0 ,key);

input clk0;
input key;
output clk;

reg [27:0] count;
reg novo_clk;
wire reset_n;

assign reset_n = key;

always @(posedge clk0)
begin
if(~reset_n)
begin
count = 0;
end
if(count==5000000)
begin
count=0;
novo_clk=~novo_clk;
end
else
begin
count = count + 1;
end
end
assign clk = novo_clk;

endmodule
