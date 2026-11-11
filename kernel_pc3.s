// ====================================================================
// VETOR DE RESET (0 a 3)
// ====================================================================
    B main_so
    NOP
    NOP
    NOP

// ====================================================================
// VETOR 4: INTERRUPÇÃO LIMPA (Sem saltos cruzados)
// ====================================================================
isr_timer:
    // 1. Limpa o pedido de interrupção no hardware (Timer Ack em 1006)
    MOV r0, #1006
    MOV r1, #0
    STR r1, [r0, #0]
    
    // 2. Alterna o PID no LCD (1007): lê 499, inverte e grava
    MOV r0, #499
    LDR r1, [r0, #0]
    
    MOV r3, #1
    SUB r3, r1, r3
    BEQ vira_pid2
    
vira_pid1:
    MOV r1, #1
    B atualiza_pid

vira_pid2:
    MOV r1, #2

atualiza_pid:
    // Salva novo PID na memória e no LCD
    MOV r0, #499
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]
    
    // 3. Retorna imediatamente para o processo que estava rodando!
    RETI

// ====================================================================
// MAIN_SO (Inicialização)
// ====================================================================
main_so:
    CLI
    
    // PID inicial = 1
    MOV r1, #1
    MOV r0, #499
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]
    
    // Configura Timer (limite = 50 ciclos para dar tempo visível no clock de 5 Hz)
    MOV r0, #1004
    MOV r1, #50
    STR r1, [r0, #0]
    
    // Limpa Timer
    MOV r0, #1006
    MOV r1, #0
    STR r1, [r0, #0]
    
    // Liga Timer
    MOV r0, #1005
    MOV r1, #1
    STR r1, [r0, #0]
    
    // Registrador de contagem inicial
    MOV r2, #0
    
    // Liga interrupções
    STI
    B loop_contador

// ====================================================================
// LOOP CONTADOR PRINCIPAL
// ====================================================================
loop_contador:
    OUT r2
    ADDI r2, r2, #1
    B loop_contador