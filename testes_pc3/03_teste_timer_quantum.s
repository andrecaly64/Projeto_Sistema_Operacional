@ ====================================================================
@ BATERIA B2 - TESTE 03: TEMPORIZADOR PROGRAMAVEL E QUANTUM MMIO
@ ====================================================================
@ Objetivo:
@   1. Testar programacao dinamica do limit (1004), enable (1005) e ack (1006)
@   2. Fase 1 (P:1): quantum curto (limit = 40) -> display zera a cada IRQ
@   3. Fase 2 (P:2): quantum longo (limit = 100) -> contagem atinge > 2x mais
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
    MOV r0, #499
    LDR r1, [r0, #0]
    B isr_cont

@ --- Inicializacao (RAM 11+) ---
main_so:
    CLI

    MOV r1, #1
    MOV r0, #499
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]

    @ Inicia com quantum curto = 40 ciclos
    MOV r0, #1004
    MOV r1, #40
    STR r1, [r0, #0]
    MOV r0, #1005
    MOV r1, #1
    STR r1, [r0, #0]

    MOV r2, #0
    B fase_sti

isr_cont:
    @ Pausa e zera counter do Timer (enable=0) durante reconfiguracao
    MOV r5, #1005
    MOV r4, #0
    STR r4, [r5, #0]

    MOV r3, #1
    SUB r4, r1, r3
    BEQ
    B vira_pid1_curto

vira_pid2_longo:
    MOV r1, #2
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]
    MOV r0, #1004
    MOV r1, #100
    STR r1, [r0, #0]
    B fim_isr

vira_pid1_curto:
    MOV r1, #1
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]
    MOV r0, #1004
    MOV r1, #40
    STR r1, [r0, #0]

fim_isr:
    @ Religa Timer com counter zerado para garantir fatia completa
    MOV r1, #1
    STR r1, [r5, #0]
    MOV r2, #0
    RETI

fase_sti:
    STI
    NOP

loop_quantum:
    OUT r2
    ADDI r2, r2, #1
    B loop_quantum
