module timer(clk, reset, cpu_addr, cpu_wdata, cpu_we, cpu_rdata, irq);

input wire clk;
input wire reset;
input wire [9:0] cpu_addr;
input wire [31:0] cpu_wdata;
input wire cpu_we;
output reg [31:0] cpu_rdata;
output reg irq;

reg [31:0] counter;
reg [31:0] limit;
reg enable;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		counter <= 32'd0;
		limit <= 32'd50000;
		enable <= 1'b0;
		irq <= 1'b0;
	end else begin
		if(cpu_we) begin
			case (cpu_addr)
				10'd1004: limit <= cpu_wdata;
				10'd1005: enable <= cpu_wdata;
				10'd1006: irq <= 1'b0;
			endcase
		end
		
		if (enable) begin
			if(counter >= limit) begin
				counter <= 32'd0;
				irq <= 1'b1;
			end else begin
				counter <= counter + 1'b1;
			end
		end else begin
			counter <= 32'd0;
		end
	end
end

always @(*) begin
	case (cpu_addr)
		10'd1004: cpu_rdata = limit;
		10'd1005: cpu_rdata = {31'd0, enable};
		10'd1006: cpu_rdata = {31'd0, irq};
		default: cpu_rdata = 32'd0;
	endcase
end

endmodule
