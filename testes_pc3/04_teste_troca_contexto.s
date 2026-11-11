@ ====================================================================
@ BATERIA C - TESTE 04: TROCA DE CONTEXTO COM PCBs, LCD (1007) E RETI
@ ====================================================================
@ Mapa da RAM (enderecos <= 511):
@   450..452 : PCB Processo 1 (r2 = contador, r5 = passo +1, sp = 400)
@   460..462 : PCB Processo 2 (r2 = contador, r5 = passo +2, sp = 420)
@   499      : PID_ATUAL (1 ou 2)
@ Comportamento esperado:
@   P:1 conta 0, 1, 2, 3...  |  P:2 conta 100, 102, 104...
@   Ao retornar para P:1, retoma exatamente do ultimo valor salvo em PCB1!
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
    LDR r3, [r0, #0]
    B isr_cont

@ --- Inicializacao dos PCBs e Timer (RAM 11+) ---
main_so:
    CLI

    @ Pre-inicializa PCB2 (PID 2: contador=100, passo=+2, sp=420)
    MOV r0, #450
    MOV r1, #100
    STR r1, [r0, #10]
    MOV r1, #2
    STR r1, [r0, #11]
    MOV r1, #420
    STR r1, [r0, #12]

    @ Processo 1 comeca ativo (PID 1 no 499 e LCD 1007)
    MOV r1, #1
    MOV r0, #499
    STR r1, [r0, #0]
    MOV r0, #1007
    STR r1, [r0, #0]

    @ Configura Timer (limit = 70 ciclos, > duracao da ISR)
    MOV r0, #1004
    MOV r2, #70
    STR r2, [r0, #0]
    MOV r0, #1005
    STR r1, [r0, #0]

    MOV r2, #0
    MOV r5, #1
    MOV sp, #400
    B fase_sti

isr_cont:
    MOV r0, #450
    SUB r6, r3, r1
    BEQ
    ADDI r0, r0, #10

    STR r2, [r0, #0]
    STR r5, [r0, #1]
    STR sp, [r0, #2]

    MOV r6, #3
    SUB r4, r6, r3
    MOV r0, #499
    STR r4, [r0, #0]
    MOV r0, #1007
    STR r4, [r0, #0]

    MOV r0, #450
    SUB r6, r4, r1
    BEQ
    ADDI r0, r0, #10

    LDR r2, [r0, #0]
    LDR r5, [r0, #1]
    LDR sp, [r0, #2]
    RETI

fase_sti:
    STI
    NOP

loop_processo:
    OUT r2
    ADD r2, r2, r5
    B loop_processo
