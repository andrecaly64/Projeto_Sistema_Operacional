module hd_emulado (clk, addr, q);

input wire clk;
input wire [11:0] addr;
output reg [31:0] q;

reg [31:0] storage [0:4095];

initial begin
	$readmemh("hd_conteudo.hex", storage);
end

always @(posedge clk) begin
	q <= storage[addr];
end

endmodule
