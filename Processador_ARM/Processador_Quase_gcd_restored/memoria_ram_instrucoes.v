module memoria_ram_intrucoes #(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=10)
(
	input wire clk,
	input wire [(ADDR_WIDTH-1):0] addr,
	output reg [(DATA_WIDTH-1):0] q,
	input wire dma_we,
	input wire [(ADDR_WIDTH-1):0] dma_addr,
	input wire [(DATA_WIDTH-1):0] dma_data
);
reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

initial begin
	$readmemb("single_port_rom_init.txt", ram);
end

always @(posedge clk) begin
	if (dma_we) begin
		ram[dma_addr] <= dma_data;
	end
	q <= ram[addr];
end

endmodule
