@ ====================================================================
@ BATERIA D - TESTE 05: ISOLAMENTO DE PILHAS (sp) E INTEGRIDADE
@ ====================================================================
@ Mapa da RAM (enderecos <= 511):
@   399..400 : Pilha privada do Processo 1 (sp inicial = 400)
@   419..420 : Pilha privada do Processo 2 (sp inicial = 420)
@   452..453 : PCB Processo 1 (450 + 2*PID)
@   454..455 : PCB Processo 2 (450 + 2*PID)
@   499      : PID_ATUAL (1 ou 2)
@ Objetivo:
@   Empilhar/desempilhar assinatura (r4 = PID) durante interrupcoes.
@   Se sp misturar ou corromper memoria entre processos, exibe 404!
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

@ --- Inicializacao (RAM 11+) ---
main_so:
    CLI

    @ Pre-inicializa PCB2 (454..455): contador=200, sp=420
    MOV r0, #454
    MOV r1, #200
    STR r1, [r0, #0]
    MOV r1, #420
    STR r1, [r0, #1]

    MOV r4, #1
    MOV r0, #499
    STR r4, [r0, #0]
    MOV r0, #1007
    STR r4, [r0, #0]

    @ Timer (limit=65 ciclos > duracao da ISR) para multiplas trocas
    MOV r0, #1004
    MOV r2, #65
    STR r2, [r0, #0]
    MOV r0, #1005
    STR r4, [r0, #0]

    MOV r2, #10
    MOV sp, #400
    STI
    B loop_pilha

isr_cont:
    MOV r6, #3
    SUB r4, r6, r3
    STR r4, [r0, #0]
    MOV r0, #1007
    STR r4, [r0, #0]

    MOV r0, #450
    ADD r0, r0, r3
    ADD r0, r0, r3
    STR r2, [r0, #0]
    STR sp, [r0, #1]

    MOV r0, #450
    ADD r0, r0, r4
    ADD r0, r0, r4
    LDR r2, [r0, #0]
    LDR sp, [r0, #1]
    RETI

falha_pilha:
    CLI
    MOV r2, #404
    OUT r2
    B falha_pilha

loop_pilha:
    SUBI sp, sp, #1
    STR r4, [sp, #0]

    OUT r2
    ADDI r2, r2, #1

    CLI
    LDR r7, [sp, #0]
    ADDI sp, sp, #1
    SUB r3, r7, r4
    BEQ
    B falha_pilha
    STI
    B loop_pilha
