#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINHAS 1000
#define MAX_LABELS 200

typedef struct {
    char nome[50];
    int endereco;
} Label;

Label labels[MAX_LABELS];
int label_count = 0;

//remover virgula, colchetes e # da string
void limpar_string(char* str) {
    if (str == NULL) return;
    char temp[64];
    int j = 0, i;
    for (i = 0; str[i] != '\0'; i++) {
        if (str[i] != ',' && str[i] != '[') {
            if (str[i] != ']' && str[i] != '#') {
                temp[j++] = str[i];
            }
        }
    }
    temp[j] = '\0';
    strcpy(str, temp);
}

//Converter inteiro para binario de N bits
void int_bin (int num, int bits, char* saida) {
    int i;
    for (i = bits -1; i >= 0; i--) {
        saida[bits - 1 - i] = (num & (1 << i)) ? '1' : '0';
    }
    saida[bits] = '\0';
}

//mapeamento de registradores para binario
void get_reg_bin (char* reg, char* saida) {
    int num = 0;
    //âncora da função atual
    if (strcmp(reg, "fp") == 0) {
        num = 11;
    }
    //ponteiro da pilha
    else if (strcmp(reg, "sp") == 0) {
        num = 13;
    }
    //endereço de retorno
    else if (strcmp(reg, "lr") == 0) {
        num = 14;
    }
    //program counter
    else if (strcmp(reg, "pc") == 0) {
        num = 15;
    }
    else if (reg[0] == 'r') {
        num = atoi(&reg[1]);
    }
    int_bin(num, 5, saida);
}

//buscar endereco de instrucao de um label
int get_label_endereco(char* nome) {
    int i;
    for (i = 0; i < label_count; i++) {
        if (strcmp(labels[i].nome, nome) == 0) {
            return labels[i].endereco;
        }
    }
    printf("\nO Label '%s' foi chamado, mas nao existe no codigo!\n", nome);
    exit(1);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Uso: ./assembler codigo_assembly.s\n");
        return 1;
    }
    FILE* arquivo = fopen(argv[1], "r");
    if (!arquivo) {
        printf("Erro ao abrir arquivo.\n");
        return 1;
    }

    char linha[256];
    int endereco_counter = 0;

    while(fgets(linha, sizeof(linha), arquivo)) {
        if(linha[0] == '@' || linha[0] == '\n') {
            continue;
        }
        char primeira_palavra[50] = "";
        sscanf(linha, "%s", primeira_palavra);

        if (primeira_palavra[0] == '\0' || primeira_palavra[0] == '@') {
            continue;
        }

        if (primeira_palavra[0] == '.' && primeira_palavra[strlen(primeira_palavra)-1] != ':') {
            continue;
        }

        if (primeira_palavra[strlen(primeira_palavra) - 1] == ':') {
            if (label_count >= MAX_LABELS) {
                printf("[ERRO FATAL] Estouro do limite de Labels (MAX %d)\n", MAX_LABELS);
                exit(1);
            }
            primeira_palavra[strlen(primeira_palavra) - 1] = '\0';
            strcpy(labels[label_count].nome, primeira_palavra);
            labels[label_count].endereco = endereco_counter;
            label_count++;
        }
        else {
            if (strcmp(primeira_palavra, "ADD") == 0 || strcmp(primeira_palavra, "SUB") == 0 ||
                strcmp(primeira_palavra, "ADDI") == 0 || strcmp(primeira_palavra, "SUBI") == 0 ||
                strcmp(primeira_palavra, "MUL") == 0 || strcmp(primeira_palavra, "UDIV") == 0 ||
                strcmp(primeira_palavra, "LDR") == 0 || strcmp(primeira_palavra, "STR") == 0 ||
                strcmp(primeira_palavra, "B") == 0 || strcmp(primeira_palavra, "BEQ") == 0 ||
                strcmp(primeira_palavra, "BNE") == 0 || strcmp(primeira_palavra, "BCC") == 0 || 
                strcmp(primeira_palavra, "BHI") == 0 || strcmp(primeira_palavra, "BLS") == 0 || 
                strcmp(primeira_palavra, "BCS") == 0 || strcmp(primeira_palavra, "CPY") == 0 ||
                strcmp(primeira_palavra, "IN") == 0 || strcmp(primeira_palavra, "IN2") == 0 ||
                strcmp(primeira_palavra, "OUT") == 0 || strcmp(primeira_palavra, "MOV") == 0 ||
                strcmp(primeira_palavra, "NOP") == 0 || strcmp(primeira_palavra, "BTN") == 0 || 
                strcmp(primeira_palavra, "CLI") == 0 || strcmp(primeira_palavra, "STI") == 0 ||
                strcmp(primeira_palavra, "RETI") == 0){
                endereco_counter++;
            }
        }
    }

    rewind(arquivo);

    printf("\nGerando Codigo de Maquina....\n");
    FILE* arquivo_saida = fopen("Processador_ARM/Processador_Quase_gcd_restored/single_port_rom_init.txt", "w");

    while (fgets(linha, sizeof(linha), arquivo)){
        //conta instrucoes
        if (linha[0] == '@' || linha[0] == '\n' || linha[0] == '.') {
            continue;
        }
        char op[32] = "", arg1[32] = "", arg2[32] = "", arg3[32] = "";

        sscanf(linha, "%31s %31s %31s %31s", op, arg1, arg2, arg3);

        limpar_string(op); limpar_string(arg1); limpar_string(arg2); limpar_string(arg3);

        int eh_instrucao = (strcmp(op, "ADD") == 0 || strcmp(op, "SUB") == 0 || 
                            strcmp(op, "ADDI") == 0 || strcmp(op, "SUBI") == 0 ||
                            strcmp(op, "MUL") == 0 || strcmp(op, "UDIV") == 0 ||
                            strcmp(op, "LDR") == 0 || strcmp(op, "STR") == 0 ||
                            strcmp(op, "B") == 0 || strcmp(op, "BEQ") == 0 ||
                            strcmp(op, "BNE") == 0 || strcmp(op, "BCC") == 0 || 
                            strcmp(op, "BHI") == 0 || strcmp(op, "BLS") == 0 || 
                            strcmp(op, "BCS") == 0 || strcmp(op, "CPY") == 0 ||
                            strcmp(op, "IN") == 0 || strcmp(op, "OUT") == 0 ||
                            strcmp(op, "MOV") == 0 || strcmp(op, "IN2") == 0 ||
                            strcmp(op, "NOP") == 0 || strcmp(op, "BTN") == 0 ||
                            strcmp(op, "CLI") == 0 || strcmp(op, "STI") == 0 ||
                            strcmp(op, "RETI") == 0);

        if (!eh_instrucao) {
            continue;
        }


        if (op[0] == '\0' || op[0] == '@') {
            continue;
        }
        if (op[0] == '.' && op[strlen(op)-1] != ':') {
            continue;
        }
        if (op[strlen(op) - 1] == ':') {
            continue;
        }

        limpar_string(arg1);
        limpar_string(arg2);
        limpar_string(arg3);

        char binario[33] = "00000000000000000000000000000000";
        char rn[6], rd[6], src2[11];

        char cond[5] = "1110";
        if (strcmp(op, "BEQ") == 0) strcpy(cond, "0000"); 
        else if (strcmp(op, "BNE") == 0) strcpy(cond, "0001");
        else if (strcmp(op, "BCS") == 0 || strcmp(op, "BGE") == 0) strcpy(cond, "0010"); 
        else if (strcmp(op, "BHI") == 0 || strcmp(op, "BGT") == 0) strcpy(cond, "0011");
        else if (strcmp(op, "BLS") == 0 || strcmp(op, "BLE") == 0) strcpy(cond, "0100");
        else if (strcmp(op, "BCC") == 0 || strcmp(op, "BLT") == 0) strcpy(cond, "0101");

        strncpy(&binario[0], cond, 4);


        if (strcmp(op, "ADD") == 0 || strcmp(op, "SUB") == 0 || strcmp(op, "MUL") == 0 || 
            strcmp(op, "UDIV") == 0 || strcmp(op, "ADDI") == 0 || strcmp(op, "CPY") == 0 || strcmp(op, "SUBI") == 0) {
            strncpy(&binario[4], "00", 2);
                
            char funct[7] = "000000";
            if (strcmp(op, "ADD") == 0)  strcpy(funct, "001000"); 
            if (strcmp(op, "ADDI") == 0) strcpy(funct, "101000"); 
            if (strcmp(op, "SUB") == 0)  strcpy(funct, "001010");
            if (strcmp(op, "SUBI") == 0) strcpy(funct, "101010");
            if (strcmp(op, "MUL") == 0)  strcpy(funct, "001100");
            if (strcmp(op, "UDIV") == 0) strcpy(funct, "001110");
            if (strcmp(op, "CPY") == 0)  strcpy(funct, "000010");
                
            strncpy(&binario[6], funct, 6); 

            if (strcmp(op, "CPY") == 0) {
                // CPY Rd, Rn
                get_reg_bin(arg2, rn);
                get_reg_bin(arg1, rd);
                int_bin(0, 10, src2); 
            } else {
                // ADD/SUB/MUL/UDIV Rd, Rn, Src2
                get_reg_bin(arg1, rd); 
                get_reg_bin(arg2, rn); 
                
                if (op[strlen(op)-1] == 'I') { 
                    int_bin(atoi(arg3), 10, src2);
                } else { 
                    get_reg_bin(arg3, src2);
                    int_bin(0, 5, &src2[5]);
                }
            }
            strncpy(&binario[12], rn, 5); // Rn (19:15)
            strncpy(&binario[17], rd, 5); // Rd (14:10)
            strncpy(&binario[22], src2, 10); 
        }

        else if (strcmp(op, "LDR") == 0 || strncmp(op, "STR", 3) == 0) {
            strncpy(&binario[4], "01", 2);
            
            char funct[7] = "000000"; 
            if (strcmp(op, "STR") == 0) strcpy(funct, "000000");
            if (strcmp(op, "LDR") == 0) strcpy(funct, "000001");
            strncpy(&binario[6], funct, 6); 

            get_reg_bin(arg1, rd);
            get_reg_bin(arg2, rn);
            int_bin(atoi(arg3), 10, src2); 
            
            strncpy(&binario[12], rn, 5);
            strncpy(&binario[17], rd, 5);
            strncpy(&binario[22], src2, 10);
        }

        // FORMATO: MOV
        else if (strcmp(op, "MOV") == 0) {
            strncpy(&binario[4], "00", 2);
            
            strncpy(&binario[6], "111111", 6); 
            
            get_reg_bin(arg1, rd);
            strncpy(&binario[17], rd, 5); 
            
            int imm_val = 0;
            if (arg2[0] == '.') {
                imm_val = get_label_endereco(arg2);
            } else {
                imm_val = atoi(arg2);
            }
            
            int_bin(imm_val, 10, src2);
            strncpy(&binario[22], src2, 10);
        }

        // FORMATO: NOP
        else if (strcmp(op, "NOP") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "100000", 6);
        }

        else if (strcmp(op, "BTN") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "000010", 6); 
        }

        else if (strcmp(op, "CLI") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "000100", 6);
        }

        else if (strcmp(op, "STI") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "000101", 6);
        }

        else if (strcmp(op, "RETI") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "000110", 6);
        }

        else if (op[0] == 'B') {
            strncpy(&binario[4], "10", 2);

            if (strcmp(op, "B") == 0) {
                if (arg1[0] == '\0') {
                    printf("Instrucao de desvio '%s' sem argumento na linha: %s\n", op, linha);
                    exit(1);
                }
                int dest_address = get_label_endereco(arg1);
                char imm20[21];
                int_bin(dest_address, 20, imm20);
                strncpy(&binario[12], imm20, 20);
            }
        }

        // FORMATO 6: IN (Mapeando in1 e in2)
        else if (strncmp(op, "IN", 2) == 0) { 
            strncpy(&binario[4], "11", 2);
            
            if (strcmp(op, "IN2") == 0) {
                strncpy(&binario[6], "001000", 6);
            } else {
                strncpy(&binario[6], "010000", 6); 
            }
            
            get_reg_bin(arg1, rd);
            strncpy(&binario[17], rd, 5);
        }

        // FORMATO 7: OUT
        else if (strcmp(op, "OUT") == 0) {
            strncpy(&binario[4], "11", 2);
            strncpy(&binario[6], "000001", 6);
            get_reg_bin(arg1, rn); 
            strncpy(&binario[12], rn, 5);
        }

        // Imprime a linha final e salva
        printf("%s\n", binario);
        fprintf(arquivo_saida, "%s\n", binario);
    }

    fclose(arquivo);
    fclose(arquivo_saida);
    printf("Binario gerado com sucesso em 'single_port_rom.txt'!\n");
    return 0;
}