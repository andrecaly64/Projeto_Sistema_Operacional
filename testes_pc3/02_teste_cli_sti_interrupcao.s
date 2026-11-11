@ ====================================================================
@ BATERIA B1 - TESTE 02: MASCARAMENTO (CLI/STI), VETOR PC=4 E RETI
@ ====================================================================
@ Objetivo:
@   1. Inicia com CLI e configura Timer (limit=45, enable=1)
@   2. Conta r2 = 0..7 com CLI ativo: Timer estoura, mas IRQ NAO entra
@   3. Valida contador de IRQs em MEM[480] == 0 antes do STI
@   4. Executa STI: IRQ pendente dispara imediatamente no vetor PC=4
@   5. ISR limpa porta 1006, muda LCD para P:2, soma 100 em r6 e faz RETI
@ ====================================================================

@ --- Vetor de Reset (RAM 0..3) ---
    B main_so
    NOP
    NOP
    NOP

@ --- Vetor de Interrupcao (RAM 4..10) ---
isr_timer:
    NOP
    MOV r0, #1006
    MOV r1, #1
    STR r1, [r0, #0]
    MOV r0, #480
    LDR r1, [r0, #0]
    B isr_cont

@ --- Inicializacao (RAM 11+) ---
main_so:
    CLI

    MOV r0, #1007
    MOV r1, #1
    STR r1, [r0, #0]
    MOV r0, #480
    MOV r1, #0
    STR r1, [r0, #0]

    @ Configura Timer com limit = 45 ciclos (< 75 ciclos do loop CLI, > ISR)
    MOV r0, #1004
    MOV r1, #45
    STR r1, [r0, #0]
    MOV r0, #1006
    MOV r1, #1
    STR r1, [r0, #0]
    MOV r0, #1005
    STR r1, [r0, #0]

    MOV r2, #0
    MOV r6, #0
    MOV r3, #8

@ --- Fase 1: Executa com CLI ativo (Timer estoura, mas nao desvia!) ---
loop_cli:
    OUT r2
    ADDI r2, r2, #1
    SUB r4, r2, r3
    BEQ
    B loop_cli

    @ Checa que nenhuma IRQ entrou durante CLI (MEM[480] == 0)
    MOV r0, #480
    LDR r1, [r0, #0]
    MOV r4, #0
    SUB r5, r1, r4
    BEQ
    B erro_cli
    B fase_sti

isr_cont:
    ADDI r1, r1, #1
    STR r1, [r0, #0]
    ADDI r6, r6, #100
    MOV r0, #1007
    MOV r1, #2
    STR r1, [r0, #0]
    RETI

erro_cli:
    MOV r0, #1007
    MOV r1, #15
    STR r1, [r0, #0]
    MOV r2, #404
    OUT r2
    B erro_cli

@ --- Fase 2: Habilita interrupcoes (STI) ---
fase_sti:
    STI
    NOP

loop_pos_sti:
    ADD r7, r2, r6
    OUT r7
    ADDI r2, r2, #1
    B loop_pos_sti
