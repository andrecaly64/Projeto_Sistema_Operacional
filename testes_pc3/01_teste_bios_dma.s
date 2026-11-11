@ ====================================================================
@ BATERIA A - TESTE 01: BIOS ROM, HD EMULADO E CONTROLADOR DMA
@ ====================================================================
@ Alinhamento hardware (Processador.v):
@   RAM 0..3   : Vetor de Reset
@   RAM 4..10  : Vetor de Interrupcao (nao usado aqui, RETI seguro)
@   RAM 11+    : main_so (ponto de entrada exato apos modo_boot 1 -> 0)
@ Objetivo:
@   1. Boot automatico via bios_rom.v copia Setor 1 -> RAM 0..63
@   2. No PC=11 da BIOS, modo_boot comuta para 0 entrando em main_so (RAM 11)
@   3. Kernel valida dma_busy == 0 (porta 1003), sinaliza P:1 / 11
@   4. Dispara DMA via MMIO (1000..1002) copiando Setor 2 -> RAM[44]
@   5. Aguarda dma_busy zerar, salta para RAM[44] e executa payload (P:9 / 42)
@ ====================================================================

@ --- Vetor de Reset (RAM 0..3) ---
    B main_so
    NOP
    NOP
    NOP

@ --- Vetor de Interrupcao (RAM 4..10) ---
isr_vazia:
    RETI
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

@ --- Rotina Principal (RAM 11+) ---
main_so:
    CLI

    @ Marca etapa 1: BIOS transferiu controle para RAM (LCD P:1, 7-Seg: 11)
    MOV r1, #1007
    MOV r2, #1
    STR r2, [r1, #0]
    MOV r2, #11
    OUT r2

    @ Verifica se DMA pos-boot ja terminou (porta 1003 == 0)
    MOV r1, #1003
    LDR r3, [r1, #0]
    MOV r4, #0
    SUB r5, r3, r4
    BEQ
    B erro_dma

    @ Programa nova transferencia DMA em runtime: Setor 2 -> RAM[48]
    MOV r1, #1000
    MOV r2, #2
    STR r2, [r1, #0]

    MOV r1, #1001
    MOV r2, #48
    STR r2, [r1, #0]

    MOV r1, #1002
    MOV r2, #1
    STR r2, [r1, #0]

espera_dma_hw:
    MOV r1, #1003
    LDR r3, [r1, #0]
    MOV r4, #0
    SUB r5, r3, r4
    BEQ
    B espera_dma_hw

    @ Salta para o codigo recem-carregado pelo DMA em RAM[48]
    MOV r6, #48
    CPY pc, r6

erro_dma:
    MOV r1, #1007
    MOV r2, #15
    STR r2, [r1, #0]
    MOV r2, #404
    OUT r2
    B erro_dma
