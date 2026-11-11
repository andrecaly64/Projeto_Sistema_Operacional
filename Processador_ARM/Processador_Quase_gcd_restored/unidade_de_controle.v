/*module unidade_de_controle (cond, opcode, funct, OperacaoULA, OperandoULA, EscritaReg, controle_out,
Imediato, EscritaMem, MemToReg, PCFonte, RegFonte, N, Z, entrada_io, aguarda_botao);
input [3:0]cond;
input [1:0]opcode;
input [5:0]funct;
input N, Z;
output reg [3:0]OperacaoULA;
output reg PCFonte, OperandoULA, MemToReg, RegFonte, EscritaMem, EscritaReg, entrada_io, controle_out;
output reg [1:0]Imediato;
output reg aguarda_botao;
always@(*) 
begin
aguarda_botao = 1'b0;
case(opcode[1:0])
'b00: begin  //operacoes logicas
case(funct[5:0])
'b001000: begin  //add 
OperacaoULA[3:0]='b0100;
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b101000: begin  //addi
OperacaoULA[3:0]='b0100;
OperandoULA='b1;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b001010: begin  //sub
OperacaoULA[3:0]='b0101;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b101010: begin  //subi
OperacaoULA[3:0]='b0101;
OperandoULA='b1;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b001100: begin  //mult
OperacaoULA[3:0]='b0110;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b001110: begin //div
OperacaoULA[3:0]='b0111;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b000100: begin //and
OperacaoULA[3:0]='b0010;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b100100: begin  //andi
OperacaoULA[3:0]='b0010;
OperandoULA='b1;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b000110: begin  //or
OperacaoULA[3:0]='b0011;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b100110: begin  //ori
OperacaoULA[3:0]='b0011;  
OperandoULA='b1;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b000000: begin  //not
OperacaoULA[3:0]='b0000;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b000010: begin  //copy
OperacaoULA[3:0]='b0001;  
OperandoULA='b0;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
'b111111: begin  //mov (imediato direto pro registrador)
OperacaoULA[3:0]='b1001;  // r = b (repassa o imediato, ignora 'a'/rn)
OperandoULA='b1;           // seleciona o imediato como operando b
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b0;
PCFonte='b0;
RegFonte='b0;
entrada_io=1'b0;
controle_out=1'b0;
end
endcase
end
'b01: begin  //operacoes de memoria
case(funct[5:0])
'b000000: begin   //store word
OperacaoULA[3:0]='b0100;  
OperandoULA='b1;
EscritaReg='b0;
Imediato[1:0]='b00;
EscritaMem='b1;
MemToReg='b0;
PCFonte='b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
end
'b000001: begin  //load word
OperacaoULA[3:0]='b0100;  
OperandoULA='b1;
EscritaReg='b1;
Imediato[1:0]='b00;
EscritaMem='b0;
MemToReg='b1;
PCFonte='b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
end
//'b100001: begin  //ldri
//OperacaoULA[3:0]='b0100;  
//OperandoULA='b1;
//EscritaReg='b1;
//Imediato[1:0]='b10;
//EscritaMem='b0;
//MemToReg='b1;
//PCFonte='b0;
//RegFonte='b0;
//entrada_io=1'b0;
//end
endcase
end
'b10: begin  //operacoes de desvio
case(cond[3:0])
4'b1110: begin  //b
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b1;
RegFonte=1'b0;
entrada_io=1'b0;
controle_out=1'b0;
end
4'b0000: begin //beq
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(Z==1'b1)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
4'b0001: begin //bne
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(Z==1'b0)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
4'b0010: begin //bge (maior-igual: basta N==0; o termo Z e redundante mas sem erro)
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(N==1'b0)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
4'b0011: begin //bgt (estritamente MAIOR: precisa N==0 E Z==0, senao trata igualdade como maior)
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(N==1'b0 && Z==1'b0)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
4'b0100: begin //ble (menor-igual: precisa N==1 OU Z==1)
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(Z==1'b1||N==1'b1)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
4'b0101: begin //blt
OperacaoULA[3:0]=4'b0101;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
RegFonte=1'b1;
entrada_io=1'b0;
controle_out=1'b0;
if(N==1'b1)
    PCFonte=1'b1;
else
    PCFonte=1'b0;
end
endcase
end
2'b11: begin   //outras instrucoes
case(funct[5:0])
6'b100000: begin //nop
OperacaoULA[3:0]=4'b0001;  
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b0;
RegFonte=1'b0;
entrada_io=1'b0;
controle_out=1'b0;
end
6'b010000: begin //in1
OperacaoULA[3:0]=4'b0001;  
OperandoULA=1'b0;
EscritaReg=1'b1;
Imediato[1:0]=2'b10;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b0;
RegFonte=1'b0;
entrada_io=1'b1;
controle_out=1'b0;
end
6'b001000: begin //in2
OperacaoULA[3:0]=4'b0001;  
OperandoULA=1'b0;
EscritaReg=1'b1;
Imediato[1:0]=2'b11;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b0;
RegFonte=1'b0;
entrada_io=1'b1;
controle_out=1'b0;
end
6'b000001: begin //out
OperacaoULA[3:0]='b0001;
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b0;
RegFonte=1'b0;
entrada_io=1'b0;
controle_out=1'b1;
end
6'b000010: begin //btn
OperacaoULA[3:0]=4'b0001;
OperandoULA=1'b0;
EscritaReg=1'b0;
Imediato[1:0]=2'b00;
EscritaMem=1'b0;
MemToReg=1'b0;
PCFonte=1'b0;
RegFonte=1'b0;
entrada_io=1'b0;
controle_out=1'b0;
aguarda_botao=1'b1;
end
endcase
end
endcase
end
endmodule
*/
module unidade_de_controle (
    input  wire [3:0] cond,
    input  wire [1:0] opcode,
    input  wire [5:0] funct,
    input  wire       N, Z,
    output reg  [3:0] OperacaoULA,
    output reg        PCFonte, OperandoULA, MemToReg, RegFonte, EscritaMem, EscritaReg, entrada_io, controle_out,
    output reg  [1:0] Imediato,
    output reg        aguarda_botao,
    
    // Sinais adicionados para suporte ao SO
    output reg        sinal_cli,
    output reg        sinal_sti,
    output reg        sinal_reti
);

always @(*) begin
    aguarda_botao = 1'b0;
    sinal_cli     = 1'b0;
    sinal_sti     = 1'b0;
    sinal_reti    = 1'b0;
    
    // Valores padrão de segurança
    OperacaoULA   = 4'b0000;
    OperandoULA   = 1'b0;
    EscritaReg    = 1'b0;
    Imediato      = 2'b00;
    EscritaMem    = 1'b0;
    MemToReg      = 1'b0;
    PCFonte       = 1'b0;
    RegFonte      = 1'b0;
    entrada_io    = 1'b0;
    controle_out  = 1'b0;

    case(opcode[1:0])
        2'b00: begin // Operações lógicas e aritméticas
            case(funct[5:0])
                6'b001000: begin OperacaoULA = 4'b0100; EscritaReg = 1'b1; end // add
                6'b101000: begin OperacaoULA = 4'b0100; OperandoULA = 1'b1; EscritaReg = 1'b1; end // addi
                6'b001010: begin OperacaoULA = 4'b0101; EscritaReg = 1'b1; end // sub
                6'b101010: begin OperacaoULA = 4'b0101; OperandoULA = 1'b1; EscritaReg = 1'b1; end // subi
                6'b001100: begin OperacaoULA = 4'b0110; EscritaReg = 1'b1; end // mult
                6'b001110: begin OperacaoULA = 4'b0111; EscritaReg = 1'b1; end // div
                6'b000100: begin OperacaoULA = 4'b0010; EscritaReg = 1'b1; end // and
                6'b100100: begin OperacaoULA = 4'b0010; OperandoULA = 1'b1; EscritaReg = 1'b1; end // andi
                6'b000110: begin OperacaoULA = 4'b0011; EscritaReg = 1'b1; end // or
                6'b100110: begin OperacaoULA = 4'b0011; OperandoULA = 1'b1; EscritaReg = 1'b1; end // ori
                6'b000000: begin OperacaoULA = 4'b0000; EscritaReg = 1'b1; end // not
                6'b000010: begin OperacaoULA = 4'b0001; EscritaReg = 1'b1; end // copy
                6'b111111: begin OperacaoULA = 4'b1001; OperandoULA = 1'b1; EscritaReg = 1'b1; end // mov
            endcase
        end

        2'b01: begin // Operações de memória
            case(funct[5:0])
                6'b000000: begin OperacaoULA = 4'b0100; OperandoULA = 1'b1; EscritaMem = 1'b1; RegFonte = 1'b1; end // str
                6'b000001: begin OperacaoULA = 4'b0100; OperandoULA = 1'b1; EscritaReg = 1'b1; MemToReg = 1'b1; RegFonte = 1'b1; end // ldr
            endcase
        end

        2'b10: begin // Operações de desvio
            OperacaoULA = 4'b0101;
            RegFonte    = 1'b1;
            case(cond[3:0])
                4'b1110: begin PCFonte = 1'b1; RegFonte = 1'b0; end // b incondicional
                4'b0000: if(Z == 1'b1)               PCFonte = 1'b1; // beq
                4'b0001: if(Z == 1'b0)               PCFonte = 1'b1; // bne
                4'b0010: if(N == 1'b0)               PCFonte = 1'b1; // bge
                4'b0011: if(N == 1'b0 && Z == 1'b0) PCFonte = 1'b1; // bgt
                4'b0100: if(Z == 1'b1 || N == 1'b1) PCFonte = 1'b1; // ble
                4'b0101: if(N == 1'b1)               PCFonte = 1'b1; // blt
            endcase
        end

        2'b11: begin // Instruções de I/O e Sistema
            case(funct[5:0])
                6'b100000: begin OperacaoULA = 4'b0001; end // nop
                6'b010000: begin OperacaoULA = 4'b0001; EscritaReg = 1'b1; Imediato = 2'b10; entrada_io = 1'b1; end // in1
                6'b001000: begin OperacaoULA = 4'b0001; EscritaReg = 1'b1; Imediato = 2'b11; entrada_io = 1'b1; end // in2
                6'b000001: begin OperacaoULA = 4'b0001; controle_out = 1'b1; end // out
                6'b000010: begin OperacaoULA = 4'b0001; aguarda_botao = 1'b1; end // btn
                
                // Mapeamento para controle de interrupção
                6'b000100: begin OperacaoULA = 4'b0001; sinal_cli  = 1'b1; end // CLI
                6'b000101: begin OperacaoULA = 4'b0001; sinal_sti  = 1'b1; end // STI
                6'b000110: begin OperacaoULA = 4'b0001; sinal_reti = 1'b1; end // RETI
            endcase
        end
    endcase
end

endmodule
