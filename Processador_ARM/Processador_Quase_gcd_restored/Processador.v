module Processador(/*saida_ula*/, escrita_reg, operacao, negativo, positivo, endereco_escrita, endereco_leitura, escrita_mem, operando_ula, /*saida_mult3,*/ 
clk, instrucao, zero, dado_escrita, /*saida_mult2,*/ rn, rm, r3, rd, cond, sinal_mult2, endereco_pc, prox_pc, prox_pc_final, clk0, reset, saida_reg2, saida_reg1,
pc_fonte, fonte_reg, /*operando2, saida_extensor,*/ reg_display1, reg_display0, reg_display2, reg_display3, imm8, imm8_2, entrada_io, controle_out, dado_leitura,
seg0, seg1, seg2, seg3, dado_reg, imediato, botao_bruto, botao_pressionado, aguarda_botao, pulso_fim, travado, contador2, key, seg4, seg5, seg6, seg7, reg_display4, reg_display5, reg_display6, reg_display7,
lcd_data, lcd_rs, lcd_rw, lcd_en, lcd_on, lcd_blon);
input clk0, reset;
output clk;
output botao_pressionado;
input botao_bruto;
output travado;
input key;
wire[1:0] contador;
output reg [1:0] contador2;
input [7:0] imm8, imm8_2;
output escrita_reg, sinal_mult2, escrita_mem, operando_ula, fonte_reg, pc_fonte, entrada_io, controle_out, imediato;
output [3:0] operacao;
output [31:0] instrucao, endereco_escrita, endereco_leitura;
wire [31:0] saida_ula;
output negativo, positivo, zero;
wire [31:0] operando2, saida_extensor;
output wire [31:0] saida_reg2, saida_reg1;
output reg [4:0]  rd, cond;
output reg [4:0] rn, rm;
reg [1:0] op;
reg [5:0] funct;
output wire [31:0] dado_escrita;
output wire [31:0] dado_leitura;
wire [31:0] saida_mult2, saida_mult3;
wire [1:0] imediato;
reg [9:0] imm10;
reg [23:0] imm24;
output [31:0] r3, dado_reg;
output [9:0] endereco_pc, prox_pc, prox_pc_final;
output [3:0] reg_display1, reg_display0, reg_display2, reg_display3, reg_display4, reg_display5, reg_display6, reg_display7;
output [6:0] seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7;
output wire aguarda_botao;

output wire [7:0] lcd_data;
output wire       lcd_rs;
output wire       lcd_rw;
output wire       lcd_en;
output wire       lcd_on;
output wire       lcd_blon;

always@(*)
begin
contador2 = contador;
end

wire zero_travado, negativo_travado;
 
wire [9:0] pular_endereco;
wire [9:0] alvo_desvio;
 
output wire pulso_fim;
wire escrita_reg_real;

wire retorno_pc;
assign retorno_pc = (op == 2'b00) && (funct == 6'b000010) && (rd == 5'd15);

assign travado = (aguarda_botao & botao_bruto) | espera_dma;
 
wire pc_fonte_real;
wire [9:0] alvo_final;
//assign pc_fonte_real = pc_fonte | retorno_pc | travado;
//assign alvo_final = travado ? endereco_pc : (retorno_pc ? saida_ula[9:0] : alvo_desvio);

assign pc_fonte_real = pc_fonte | retorno_pc | travado | toma_interrupcao | sinal_reti;

assign alvo_final = travado ? endereco_pc:
	toma_interrupcao ? 10'd4:
	sinal_reti ? epc:
	retorno_pc ? saida_ula[9:0]:
		alvo_desvio;

 
assign pular_endereco = prox_pc + 10'd1;
assign alvo_desvio = (cond == 4'b1110) ? imm10 : pular_endereco;

wire precisa_gate_reg = (op == 2'b00) && (funct != 6'b111111);
assign escrita_reg_real = precisa_gate_reg ? (escrita_reg & pulso_fim) : escrita_reg;

always @(*)
begin
rm = instrucao[9:5];
rn = instrucao[19:15];
rd = instrucao[14:10];
cond = instrucao[31:28];
op = instrucao[27:26];
funct = instrucao[25:20];
imm10 = instrucao[9:0];
imm24 = instrucao[23:0];
end

wire [31:0] dma_rdata;
wire [11:0] hd_addr_wire;
wire [31:0] hd_data_wire;
wire [9:0] dma_ram_addr;
wire [31:0] dma_ram_data;
wire dma_ram_we;
wire dma_busy;

wire [31:0] dado_memoria_final;
assign dado_memoria_final = (endereco_leitura >= 10'd1000) ? dma_rdata : dado_leitura;

wire sinal_cli, sinal_sti, sinal_reti;
wire irq_timer;
wire [31:0] timer_rdata;

reg interrupt_enable;
reg [9:0] epc;
reg epc_flag_z;
reg epc_flag_n;

wire toma_interrupcao;
assign toma_interrupcao = irq_timer & interrupt_enable & pulso_fim;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		interrupt_enable <= 1'b0;
		epc <= 10'd0;
		epc_flag_z <= 1'b0;
		epc_flag_n <= 1'b0;
	end else begin
		if (sinal_cli) begin
			interrupt_enable <= 1'b0;
		end else if (sinal_sti || sinal_reti) begin
			interrupt_enable <= 1'b1;
		end else if (toma_interrupcao) begin
			interrupt_enable <= 1'b0;
			epc <= prox_pc[9:0];
			epc_flag_z <= zero_travado;
			epc_flag_n <= negativo_travado;
		end
	end
end		

reg [3:0] reg_pid_atual;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_pid_atual <= 4'd0;
    end else if (escrita_mem && (endereco_escrita[9:0] == 10'd1007)) begin
        reg_pid_atual <= saida_reg2[3:0]; // Grava o PID informado pelo Kernel
    end
end

//sem bios por enquanto
reg modo_boot;
wire espera_dma = modo_boot && dma_busy;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        modo_boot <= 1'b1;
    end else if (modo_boot && (endereco_pc == 10'd11)) begin
        modo_boot <= 1'b0;
    end
end

contato1 (.clk0(clk0),.key(key),.clk(clk));
banco_de_registradores A1(.clk(clk),.sinal_escrita(escrita_reg_real),.r1(saida_reg1),.r2(saida_reg2),.dado(dado_reg),.rn(rn),.rd(rd),.rm(saida_mult3),.r3(r3));
Ula T2(.r(saida_ula),.sel(operacao),.N(negativo),.Z(zero),.a(saida_reg1),.b(operando2));
//memoria_de_instrucoes B1(.clk(clk),.q(instrucao),.addr(endereco_pc));

wire [31:0] instrucao_bios;
wire [31:0] instrucao_ram;

bios_rom BIOS1(.clk(clk),.addr(endereco_pc[4:0]),.q(instrucao_bios));

memoria_ram_intrucoes B2(.clk(clk),.addr(endereco_pc),.q(instrucao_ram),.dma_we(dma_ram_we),.dma_addr(dma_ram_addr),.dma_data(dma_ram_data));

assign instrucao = modo_boot ? instrucao_bios : instrucao_ram;

hd_emulado HD1(.clk(clk),.addr(hd_addr_wire),.q(hd_data_wire));

dma_controller DMA1(.clk(clk),.reset(reset),.cpu_addr(endereco_escrita[9:0]),.cpu_wdata(saida_reg2),.cpu_we(escrita_mem),.cpu_rdata(dma_rdata),.hd_addr(hd_addr_wire),.hd_data(hd_data_wire),.ram_inst_addr(dma_ram_addr),.ram_inst_data(dma_ram_data),.ram_inst_we(dma_ram_we),.dma_busy(dma_busy));

timer TIMER1(.clk(clk),.reset(reset),.cpu_addr(endereco_escrita[9:0]),.cpu_wdata(saida_reg2),.cpu_we(escrita_mem),.cpu_rdata(timer_rdata),.irq(irq_timer));

memoria_de_dados C1(.clk(clk),.q(dado_leitura),.data(saida_reg2),.read_addr(endereco_leitura),.write_addr(endereco_escrita),.we(escrita_mem));
multiplexador1 D1(.entrada1(saida_reg2),.saida(operando2),.entrada2(saida_extensor),.sel(operando_ula));
extensor_bit E1(.saida(saida_extensor),.entrada1(imm10),.entrada2(imm24),.entrada3(imm8),.entrada4(imm8_2),.sel(imediato));
multiplexador2 F1(.entrada1(saida_ula),.entrada2(/*dado_memoria_final*/dado_memoria_final),.saida(saida_mult2),.sel(sinal_mult2));

flags_reg FLAGS1(.clk(clk),.opcode(op),.Z_in(zero),.N_in(negativo),.Z_out(zero_travado),.N_out(negativo_travado));

/*unidade_de_controle G1(.funct(funct),.opcode(op),.cond(cond),.N(negativo_travado),.Z(zero_travado),.OperacaoULA(operacao),.PCFonte(pc_fonte),.entrada_io(entrada_io),
.Imediato(imediato),.EscritaReg(escrita_reg),.MemToReg(sinal_mult2),.EscritaMem(escrita_mem),.OperandoULA(operando_ula),.RegFonte(fonte_reg),
.controle_out(controle_out),.aguarda_botao(aguarda_botao));*/

unidade_de_controle G1 (
    .funct(funct),
    .opcode(op),
    .cond(cond),
    .N(negativo_travado),
    .Z(zero_travado),
    .OperacaoULA(operacao),
    .PCFonte(pc_fonte),
    .entrada_io(entrada_io),
    .Imediato(imediato),
    .EscritaReg(escrita_reg),
    .MemToReg(sinal_mult2),
    .EscritaMem(escrita_mem),
    .OperandoULA(operando_ula),
    .RegFonte(fonte_reg),
    .controle_out(controle_out),
    .aguarda_botao(aguarda_botao),
    .sinal_cli(sinal_cli),
    .sinal_sti(sinal_sti),
    .sinal_reti(sinal_reti)
);

wire [3:0] prox_p1 = (reg_pid_atual == 4'd10) ? 4'd1 : reg_pid_atual + 4'd1;
wire [3:0] prox_p2 = (prox_p1 == 4'd10)        ? 4'd1 : prox_p1 + 4'd1;
wire [3:0] prox_p3 = (prox_p2 == 4'd10)        ? 4'd1 : prox_p2 + 4'd1;

lcd_controller LCD1 (
    .clk50M(clk0),
    .reset(reset),
    .pc_instrucao(endereco_pc),
    .pid_processo(reg_pid_atual),
    .prox_proc1(prox_p1),
    .prox_proc2(prox_p2),
    .prox_proc3(prox_p3),
    .lcd_data(lcd_data),
    .lcd_rs(lcd_rs),
    .lcd_rw(lcd_rw),
    .lcd_en(lcd_en),
    .lcd_on(lcd_on),
    .lcd_blon(lcd_blon)
);

logica_memoria_de_dados H1(.escrita_mem(escrita_mem),.entrada(saida_ula),.saida1(endereco_leitura),.saida2(endereco_escrita));
multiplexador3 I1(.sinal_controle_reg(fonte_reg),.entrada1(rm),.entrada2(rd),.saida(saida_mult3));
PC J1(.pc(endereco_pc),.clk(clk),.prox_endereco(prox_pc_final),.reset(reset));

ula_pc K1(.entrada1(endereco_pc),.saida_pc(prox_pc),.clk(clk),.pulso_fim(pulso_fim),.reset(reset));

multiplexador_pc L1(.entrada1(prox_pc),.entrada2(alvo_final),.saida(prox_pc_final),.pc_fonte(pc_fonte_real));
out M1(.entrada(saida_mult2),.clock(clk),.d0(reg_display0),.d1(reg_display1),.d2(reg_display2),.d3(reg_display3),.controle(controle_out),.reset(reset));
mult_in N1(.controle(entrada_io),.entrada_in(saida_extensor),.saida_io(dado_reg),.saida_mult2(saida_mult2));

debounce BTN1(.clk(clk0),.botao_bruto(botao_bruto),.pulso_pressionado(botao_pressionado));

bcd chamada0 (.bcd(reg_display0),.seg(seg0));
bcd chamada1 (.bcd(reg_display1),.seg(seg1));
bcd chamada2 (.bcd(reg_display2),.seg(seg2));
bcd chamada3 (.bcd(reg_display3),.seg(seg3));
bcd chamada4 (.bcd(reg_display4),.seg(seg4));
bcd chamada5 (.bcd(reg_display5),.seg(seg5));
bcd chamada6 (.bcd(reg_display6),.seg(seg6));
bcd chamada7 (.bcd(reg_display7),.seg(seg7));
endmodule