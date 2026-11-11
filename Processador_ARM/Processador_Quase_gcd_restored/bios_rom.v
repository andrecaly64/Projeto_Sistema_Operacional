module bios_rom(clk, addr, q);

input wire clk;
input wire [4:0] addr;
output reg [31:0] q;

reg [31:0] rom [0:31];

initial begin
	rom[0]  = 32'hE3F007E8;
   rom[1]  = 32'hE3F00801;
   rom[2]  = 32'hE4008800;
	rom[3]  = 32'hE3F007E9;
   rom[4]  = 32'hE3F00800;
   rom[5]  = 32'hE4008800;
	rom[6]  = 32'hE3F007EA;
   rom[7]  = 32'hE3F00801;
   rom[8]  = 32'hE4008800;
	rom[9]  = 32'hEE000000;
   rom[10] = 32'hEE000000;
	rom[11] = 32'hE8000000;
   rom[12] = 32'hEE000000;
   rom[13] = 32'hEE000000;
   rom[14] = 32'hEE000000;
   rom[15] = 32'hEE000000;
end
	
always @(posedge clk) begin
	q <= rom[addr];
end

endmodule
