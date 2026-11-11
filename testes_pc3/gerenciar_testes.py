#!/usr/bin/env python3
"""
Gerenciador, montador e simulador comportamental dos testes modulares do PC3.

Uso:
  python3 testes_pc3/gerenciar_testes.py --gerar-todos
  python3 testes_pc3/gerenciar_testes.py --executar-todos
  python3 testes_pc3/gerenciar_testes.py --executar 4
  python3 testes_pc3/gerenciar_testes.py --aplicar 4
  python3 testes_pc3/gerenciar_testes.py --restaurar
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

BASE_DIR = Path(__file__).resolve().parent
REPO_DIR = BASE_DIR.parent
HEX_DIR = BASE_DIR / "hex"
QUARTUS_DIR = REPO_DIR / "Processador_ARM" / "Processador_Quase_gcd_restored"
HD_DEST_PATH = QUARTUS_DIR / "hd_conteudo.hex"
HD_VERILOG_PATH = QUARTUS_DIR / "hd_emulado.v"
BACKUP_PATH = BASE_DIR / "backup_hd_conteudo.hex"
QUARTUS_SH = Path("/home/andre/intelFPGA_lite/20.1/quartus/bin/quartus_sh")

COND_MAP = {
    "BEQ": 0b0000,
    "BNE": 0b0001,
    "BCS": 0b0010,
    "BGE": 0b0010,
    "BHI": 0b0011,
    "BGT": 0b0011,
    "BLS": 0b0100,
    "BLE": 0b0100,
    "BCC": 0b0101,
    "BLT": 0b0101,
}

ALU_FUNCT = {
    "ADD":  0b001000,
    "ADDI": 0b101000,
    "SUB":  0b001010,
    "SUBI": 0b101010,
    "MUL":  0b001100,
    "UDIV": 0b001110,
    "CPY":  0b000010,
}

SYS_FUNCT = {
    "NOP":  0b100000,
    "BTN":  0b000010,
    "CLI":  0b000100,
    "STI":  0b000101,
    "RETI": 0b000110,
}

TESTS = {
    1: ("01_teste_bios_dma.s", "01_teste_bios_dma.hex", "Bateria A: BIOS ROM, HD Emulado e DMA"),
    2: ("02_teste_cli_sti_interrupcao.s", "02_teste_cli_sti_interrupcao.hex", "Bateria B1: CLI/STI, Vetor PC=4 e RETI"),
    3: ("03_teste_timer_quantum.s", "03_teste_timer_quantum.hex", "Bateria B2: Quantum Programavel (timer.v)"),
    4: ("04_teste_troca_contexto.s", "04_teste_troca_contexto.hex", "Bateria C: Troca de Contexto (PCBs + LCD 1007)"),
    5: ("05_teste_pilhas_isoladas.s", "05_teste_pilhas_isoladas.hex", "Bateria D: Isolamento de Pilhas (sp) e Integridade"),
}


def parse_reg(tok: str) -> int:
    tok = tok.strip()
    if tok == "fp":
        return 11
    if tok == "sp":
        return 13
    if tok == "lr":
        return 14
    if tok == "pc":
        return 15
    if tok.startswith("r"):
        return int(tok[1:])
    raise ValueError(f"Registrador desconhecido: {tok}")


def clean_tok(tok: str) -> str:
    return tok.replace(",", "").replace("[", "").replace("]", "").replace("#", "").strip()


def assemble_lines(lines: List[str], base_addr: int = 0) -> Tuple[List[int], Dict[str, int]]:
    labels: Dict[str, int] = {}
    parsed_instrs: List[Tuple[str, List[str]]] = []

    valid_ops = (
        set(ALU_FUNCT)
        | {"MOV", "LDR", "STR", "B", "IN", "IN2", "OUT"}
        | set(COND_MAP)
        | set(SYS_FUNCT)
    )

    pc_idx = 0
    for raw in lines:
        line = raw.split("@")[0].split("//")[0].strip()
        if not line:
            continue
        first = line.split()[0]
        if first.endswith(":"):
            labels[first[:-1]] = base_addr + pc_idx
            continue
        if first.startswith("."):
            continue
        if first not in valid_ops:
            raise ValueError(f"Mnemonico invalido: {first} na linha '{raw.strip()}'")
        tokens = [clean_tok(t) for t in line.split()]
        parsed_instrs.append((tokens[0], tokens[1:]))
        pc_idx += 1

    words: List[int] = []
    for op, args in parsed_instrs:
        cond = COND_MAP.get(op, 0b1110)
        word = (cond & 0xF) << 28

        if op in ALU_FUNCT:
            word |= (0b00 << 26) | (ALU_FUNCT[op] << 20)
            if op == "CPY":
                rd = parse_reg(args[0])
                rn = parse_reg(args[1])
                src2 = 0
            else:
                rd = parse_reg(args[0])
                rn = parse_reg(args[1])
                if op.endswith("I"):
                    src2 = int(args[2]) & 0x3FF
                else:
                    src2 = (parse_reg(args[2]) & 0x1F) << 5
            word |= (rn << 15) | (rd << 10) | src2

        elif op in ("LDR", "STR"):
            funct = 0b000001 if op == "LDR" else 0b000000
            rd = parse_reg(args[0])
            rn = parse_reg(args[1])
            imm = int(args[2]) & 0x3FF
            word |= (0b01 << 26) | (funct << 20) | (rn << 15) | (rd << 10) | imm

        elif op == "MOV":
            rd = parse_reg(args[0])
            imm_tok = args[1]
            imm = labels[imm_tok] if imm_tok.startswith(".") else int(imm_tok)
            word |= (0b00 << 26) | (0b111111 << 20) | (rd << 10) | (imm & 0x3FF)

        elif op in SYS_FUNCT:
            word |= (0b11 << 26) | (SYS_FUNCT[op] << 20)

        elif op == "OUT":
            rn = parse_reg(args[0])
            word |= (0b11 << 26) | (0b000001 << 20) | (rn << 15)

        elif op in ("IN", "IN2"):
            funct = 0b001000 if op == "IN2" else 0b010000
            rd = parse_reg(args[0])
            word |= (0b11 << 26) | (funct << 20) | (rd << 10)

        elif op == "B":
            target_tok = args[0]
            dest = labels[target_tok] if target_tok in labels else int(target_tok)
            word |= (0b10 << 26) | (dest & 0xFFFFF)

        elif op in COND_MAP:
            word |= (0b10 << 26)

        words.append(word & 0xFFFFFFFF)

    return words, labels


def build_hex_image(test_id: int) -> Path:
    HEX_DIR.mkdir(parents=True, exist_ok=True)
    src_name, hex_name, desc = TESTS[test_id]
    src_path = BASE_DIR / src_name
    lines = src_path.read_text(encoding="utf-8").splitlines()
    sector1_words, labels = assemble_lines(lines, base_addr=0)

    if len(sector1_words) > 64:
        raise ValueError(
            f"{src_name} gerou {len(sector1_words)} palavras (> 64 palavras do Setor 1)!"
        )

    # Rede de protecao para RETI nos loops finais (testes 2..5)
    pad_word = 0xE8000000  # B 0 default (para teste 1 nunca usado)
    for loop_label in ("loop_pos_sti", "loop_quantum", "loop_processo", "loop_pilha"):
        if loop_label in labels:
            pad_word = (0b1110 << 28) | (0b10 << 26) | (labels[loop_label] & 0xFFFFF)
            break

    while len(sector1_words) < 64:
        sector1_words.append(pad_word)

    # Payload de Setor 2 para o Teste 1 (DMA em runtime copiando Setor 2 -> RAM[48])
    sector2_words: List[int] = []
    if test_id == 1:
        payload_asm = [
            "    MOV r1, #1007",
            "    MOV r2, #9",
            "    STR r2, [r1, #0]",
            "    MOV r2, #42",
            "    OUT r2",
            "fim_setor2:",
            "    B fim_setor2",
        ]
        sector2_words, _ = assemble_lines(payload_asm, base_addr=48)
        while len(sector2_words) < 64:
            sector2_words.append(0xEE000000)

    out_lines = [
        f"// ====================================================================",
        f"// IMAGEM HD PARA: {desc}",
        f"// Fonte: {src_name} ({len(labels)} labels)",
        f"// ====================================================================",
        "// SETOR 0: SUPERBLOCO (Palavras 0 a 63)",
        "0000CAFE",
        "00000040",
        "0000000A",
    ]
    out_lines.extend(["00000000"] * 61)
    out_lines.append("// SETOR 1: KERNEL DE TESTE (Palavras 64 a 127 -> RAM 0 a 63)")
    for w in sector1_words:
        out_lines.append(f"{w:08X}")

    if sector2_words:
        out_lines.append("// SETOR 2: PAYLOAD PARA TESTE DE DMA EM RUNTIME (RAM 40+)")
        for w in sector2_words:
            out_lines.append(f"{w:08X}")

    out_path = HEX_DIR / hex_name
    out_path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
    return out_path


def sign_ext_10(val: int) -> int:
    val &= 0x3FF
    return val - 0x400 if (val & 0x200) else val


def u32(val: int) -> int:
    return val & 0xFFFFFFFF


class ArmPc3Simulator:
    """Simulador comportamental fiel ao RTL em Processador.v, bios_rom.v, dma_controller.v, timer.v e ula_pc.v."""

    BIOS_ROM = [
        0xE3F007E8, 0xE3F00801, 0xE4008800,
        0xE3F007E9, 0xE3F00800, 0xE4008800,
        0xE3F007EA, 0xE3F00801, 0xE4008800,
        0xEE000000, 0xEE000000, 0xE8000000,
        0xEE000000, 0xEE000000, 0xEE000000, 0xEE000000,
    ] + [0] * 16

    def __init__(self, hex_path: Path):
        self.hd = [0] * 4096
        idx = 0
        for raw in hex_path.read_text(encoding="utf-8").splitlines():
            clean = raw.split("//")[0].strip()
            if clean:
                self.hd[idx] = int(clean, 16)
                idx += 1

        self.ram_inst = [0] * 1024
        self.ram_data = [0] * 1024
        self.regs = [0] * 32
        self.regs[1] = 2  # banco_de_registradores.v initial

        # CPU / Control state
        self.pc = 0
        self.prox_pc = 0
        self.pulso_fim = 0
        self.contador_ula_pc = 1
        self.instrucao = 0  # synchronous fetch register
        self.modo_boot = 1
        self.interrupt_enable = 0
        self.epc = 0
        self.zero_travado = 0
        self.neg_travado = 0
        self.reg_pid_atual = 0
        self.out_display = 0

        # DMA controller state
        self.dma_sector = 0
        self.dma_dest = 0
        self.dma_start = 0
        self.dma_state = 0  # 0=IDLE, 1=READ_HD, 2=WRITE_RAM, 3=DONE
        self.dma_wcount = 0
        self.hd_data_reg = 0

        # Timer state
        self.timer_counter = 0
        self.timer_limit = 50000
        self.timer_enable = 0
        self.irq_timer = 0

        # Trace logs
        self.lcd_events: List[Tuple[int, int]] = [(0, 0)]
        self.out_events: List[Tuple[int, int, int]] = []  # (cycle, pid, val)
        self.irq_entries: List[int] = []
        self.boot_exit_cycle: Optional[int] = None

    def step(self, cycle: int) -> None:
        instr = self.instrucao
        cond = (instr >> 28) & 0xF
        op = (instr >> 26) & 0x3
        funct = (instr >> 20) & 0x3F
        rn = (instr >> 15) & 0x1F
        rd = (instr >> 10) & 0x1F
        rm = (instr >> 5) & 0x1F
        imm10 = instr & 0x3FF

        # Combinational control decode
        escrita_reg = 0
        escrita_mem = 0
        operando_ula = 0
        mem_to_reg = 0
        reg_fonte = 0
        pc_fonte = 0
        controle_out = 0
        sinal_cli = 0
        sinal_sti = 0
        sinal_reti = 0
        ula_sel = 1  # pass a

        if op == 0b00:
            if funct == 0b001000:
                ula_sel, operando_ula, escrita_reg = 0b0100, 0, 1
            elif funct == 0b101000:
                ula_sel, operando_ula, escrita_reg = 0b0100, 1, 1
            elif funct == 0b001010:
                ula_sel, operando_ula, escrita_reg = 0b0101, 0, 1
            elif funct == 0b101010:
                ula_sel, operando_ula, escrita_reg = 0b0101, 1, 1
            elif funct == 0b001100:
                ula_sel, operando_ula, escrita_reg = 0b0110, 0, 1
            elif funct == 0b001110:
                ula_sel, operando_ula, escrita_reg = 0b0111, 0, 1
            elif funct == 0b000010:
                ula_sel, operando_ula, escrita_reg = 0b0001, 0, 1
            elif funct == 0b111111:
                ula_sel, operando_ula, escrita_reg = 0b1001, 1, 1
        elif op == 0b01:
            reg_fonte = 1
            operando_ula = 1
            ula_sel = 0b0100
            if funct == 0b000000:
                escrita_mem = 1
            elif funct == 0b000001:
                escrita_reg = 1
                mem_to_reg = 1
        elif op == 0b10:
            reg_fonte = 1
            ula_sel = 0b0101
            if cond == 0b1110:
                pc_fonte = 1
            elif cond == 0b0000 and self.zero_travado == 1:
                pc_fonte = 1
            elif cond == 0b0001 and self.zero_travado == 0:
                pc_fonte = 1
        elif op == 0b11:
            if funct == 0b000001:
                controle_out = 1
            elif funct == 0b000100:
                sinal_cli = 1
            elif funct == 0b000101:
                sinal_sti = 1
            elif funct == 0b000110:
                sinal_reti = 1

        # ALU + Register read
        reg_b_idx = rd if reg_fonte else rm
        a = self.regs[rn]
        b_reg = self.regs[reg_b_idx]
        ext = u32(sign_ext_10(imm10))
        b = ext if operando_ula else b_reg

        if ula_sel == 0b0001:
            saida_ula = a
        elif ula_sel == 0b0100:
            saida_ula = u32(a + b)
        elif ula_sel == 0b0101:
            saida_ula = u32(a - b)
        elif ula_sel == 0b0110:
            saida_ula = u32(a * b)
        elif ula_sel == 0b0111:
            saida_ula = u32(a // b) if b != 0 else 0
        elif ula_sel == 0b1001:
            saida_ula = b
        else:
            saida_ula = a

        z_in = 1 if saida_ula == 0 else 0
        n_in = 1 if (saida_ula & 0x80000000) else 0

        # Negedge flags_reg behavior (happens before next posedge)
        if op == 0b00:
            self.zero_travado = z_in
            self.neg_travado = n_in

        dma_busy = 1 if self.dma_state != 0 else 0
        espera_dma = 1 if (self.modo_boot and dma_busy) else 0
        travado = espera_dma

        addr_mem10 = saida_ula & 0x3FF
        # Read memory / MMIO
        if mem_to_reg:
            if saida_ula >= 1000:
                if addr_mem10 == 1000:
                    dado_mem = self.dma_sector
                elif addr_mem10 == 1001:
                    dado_mem = self.dma_dest
                elif addr_mem10 == 1002:
                    dado_mem = self.dma_start
                elif addr_mem10 == 1003:
                    dado_mem = dma_busy
                else:
                    dado_mem = 0
            else:
                dado_mem = self.ram_data[addr_mem10]
            dado_mult2 = dado_mem
        else:
            dado_mult2 = saida_ula

        retorno_pc = 1 if (op == 0b00 and funct == 0b000010 and rd == 15) else 0
        toma_irq = 1 if (self.irq_timer and self.interrupt_enable and self.pulso_fim) else 0

        pc_fonte_real = 1 if (pc_fonte or retorno_pc or travado or toma_irq or sinal_reti) else 0
        alvo_desvio = imm10 if cond == 0b1110 else ((self.prox_pc + 1) & 0x3FF)
        if travado:
            alvo_final = self.pc
        elif toma_irq:
            alvo_final = 4
        elif sinal_reti:
            alvo_final = self.epc
        elif retorno_pc:
            alvo_final = saida_ula & 0x3FF
        else:
            alvo_final = alvo_desvio

        prox_pc_final = alvo_final if pc_fonte_real else self.prox_pc

        # Gate register write on op==00 (except MOV)
        precisa_gate = 1 if (op == 0b00 and funct != 0b111111) else 0
        escrita_reg_real = (escrita_reg & self.pulso_fim) if precisa_gate else escrita_reg

        # --- POSEDGE CLK UPDATES ---
        old_pc = self.pc

        # Register file write
        if escrita_reg_real:
            self.regs[rd] = u32(dado_mult2)

        # Data memory & MMIO writes
        if escrita_mem:
            if addr_mem10 < 1000:
                self.ram_data[addr_mem10] = u32(b_reg)
            elif addr_mem10 == 1007:
                new_pid = b_reg & 0xF
                if new_pid != self.reg_pid_atual:
                    self.lcd_events.append((cycle, new_pid))
                self.reg_pid_atual = new_pid

        # OUT peripheral
        if controle_out and self.pulso_fim:
            self.out_display = u32(dado_mult2)
            self.out_events.append((cycle, self.reg_pid_atual, self.out_display))

        # IRQ / EPC state
        if sinal_cli:
            self.interrupt_enable = 0
        elif sinal_sti or sinal_reti:
            self.interrupt_enable = 1
        elif toma_irq:
            self.interrupt_enable = 0
            self.epc = self.prox_pc & 0x3FF
            self.irq_entries.append(cycle)

        # modo_boot transition
        if self.modo_boot and old_pc == 11:
            self.modo_boot = 0
            self.boot_exit_cycle = cycle

        # DMA controller MMIO + FSM
        next_dma_start = 0
        if escrita_mem:
            if addr_mem10 == 1000:
                self.dma_sector = b_reg & 0x3F
            elif addr_mem10 == 1001:
                self.dma_dest = b_reg & 0x3FF
            elif addr_mem10 == 1002:
                next_dma_start = b_reg & 0x1

        old_dma_start = self.dma_start
        self.dma_start = next_dma_start

        if self.dma_state == 0:
            if old_dma_start:
                self.dma_wcount = 0
                self.dma_state = 1
        elif self.dma_state == 1:
            self.dma_state = 2
        elif self.dma_state == 2:
            ram_addr = (self.dma_dest + self.dma_wcount) & 0x3FF
            self.ram_inst[ram_addr] = self.hd_data_reg
            if self.dma_wcount == 63:
                self.dma_state = 3
            else:
                self.dma_wcount += 1
                self.dma_state = 1
        elif self.dma_state == 3:
            self.dma_state = 0

        # Synchronous HD read for next cycle
        hd_idx = ((self.dma_sector & 0x3F) << 6) | (self.dma_wcount & 0x3F)
        self.hd_data_reg = self.hd[hd_idx]

        # Timer update
        if escrita_mem:
            if addr_mem10 == 1004:
                self.timer_limit = u32(b_reg)
            elif addr_mem10 == 1005:
                self.timer_enable = 1 if b_reg else 0
            elif addr_mem10 == 1006:
                self.irq_timer = 0

        if self.timer_enable:
            if self.timer_counter >= self.timer_limit:
                self.timer_counter = 0
                self.irq_timer = 1
            else:
                self.timer_counter += 1
        else:
            self.timer_counter = 0

        # ula_pc
        if self.contador_ula_pc == 2:
            self.prox_pc = (old_pc + 1) & 0x3FF
            self.contador_ula_pc = 1
            self.pulso_fim = 1
        else:
            self.contador_ula_pc += 1
            self.pulso_fim = 0

        # PC & synchronous instruction memory read
        next_pc = prox_pc_final & 0x3FF
        self.pc = next_pc
        next_modo_boot = 0 if (self.modo_boot and old_pc == 11) else self.modo_boot
        if next_modo_boot:
            self.instrucao = self.BIOS_ROM[old_pc & 0x1F]
        else:
            self.instrucao = self.ram_inst[old_pc & 0x3FF]


def run_test(test_id: int) -> bool:
    hex_path = build_hex_image(test_id)
    sim = ArmPc3Simulator(hex_path)
    _, _, desc = TESTS[test_id]
    print(f"\n=== Executando Teste 0{test_id}: {desc} ===")
    print(f"    HEX: {hex_path}")

    max_cycles = 2500
    for c in range(1, max_cycles + 1):
        sim.step(c)

    assert sim.boot_exit_cycle is not None, "BIOS nunca comutou modo_boot para 0!"
    print(f"    Boot BIOS -> RAM concluido no ciclo {sim.boot_exit_cycle}")
    print(f"    Sequencia LCD (P:X): {[pid for _, pid in sim.lcd_events]}")
    outs_sample = [(pid, val) for _, pid, val in sim.out_events[:24]]
    print(f"    Amostra 7-Seg (PID, valor): {outs_sample}")

    if test_id == 1:
        pids = [p for _, p in sim.lcd_events]
        vals = [v for _, _, v in sim.out_events]
        assert pids == [0, 1, 9], f"Esperado LCD [0, 1, 9], obtido {pids}"
        assert 11 in vals and 42 in vals, f"Esperado 11 e 42 no 7-Seg, obtido {vals}"
        assert 404 not in vals, "Erro de DMA detectado (404)!"
        print("    [PASS] Boot BIOS + DMA Setor 1 + DMA runtime Setor 2 -> RAM[48] validado!")

    elif test_id == 2:
        pids = [p for _, p in sim.lcd_events]
        vals = [v for _, _, v in sim.out_events]
        assert 404 not in vals, "Falha no teste CLI: IRQ entrou antes do STI!"
        assert pids[:3] == [0, 1, 2], f"Esperado transicao P:0 -> P:1 -> P:2, obtido {pids}"
        p1_vals = [v for _, pid, v in sim.out_events if pid == 1]
        p2_vals = [v for _, pid, v in sim.out_events if pid == 2]
        assert p1_vals == list(range(8)), f"Com CLI esperava contagem limpa 0..7, obtido {p1_vals}"
        assert len(p2_vals) > 0 and p2_vals[0] >= 108, f"Apos STI esperava >= 108, obtido {p2_vals[:5]}"
        print(f"    IRQs disparadas nos ciclos: {sim.irq_entries[:5]} (apos CLI liberar)")
        print("    [PASS] CLI mascarou o Timer; STI ativou vetor PC=4 e RETI retomou corretamente!")

    elif test_id == 3:
        # Agrupa blocos consecutivos por interrupcao para comparar fatia curta vs longa
        slices: List[Tuple[int, int]] = []
        for _, pid, val in sim.out_events:
            if not slices or slices[-1][0] != pid or val == 0:
                slices.append((pid, 1))
            else:
                slices[-1] = (pid, slices[-1][1] + 1)
        p1_counts = [cnt for pid, cnt in slices[1:-1] if pid == 1]
        p2_counts = [cnt for pid, cnt in slices[1:-1] if pid == 2]
        print(f"    Contagens por fatia -> P:1 (limit=40): {p1_counts}, P:2 (limit=100): {p2_counts}")
        assert len(p1_counts) >= 2 and len(p2_counts) >= 2, "Poucas preempcoes observadas!"
        assert min(p2_counts) >= 2 * max(p1_counts), "Quantum longo (100) nao gerou fatia maior que curto (40)!"
        print("    [PASS] Reprogramacao dinamica de quantum (porta 1004) validada!")

    elif test_id == 4:
        p1_seq = [v for _, pid, v in sim.out_events if pid == 1]
        p2_seq = [v for _, pid, v in sim.out_events if pid == 2]
        print(f"    Processo 1 (7-Seg): {p1_seq[:14]}")
        print(f"    Processo 2 (7-Seg): {p2_seq[:14]}")
        assert p1_seq[:10] == list(range(10)), f"P1 nao preservou contagem +1 inicial: {p1_seq[:10]}"
        assert p2_seq[:3] == [100, 102, 104], f"P2 nao iniciou em 100 (+2): {p2_seq[:3]}"
        assert all(v < 100 for v in p1_seq) and p1_seq == sorted(p1_seq), f"Contexto de P1 corrompido: {p1_seq}"
        assert all(v >= 100 and v % 2 == 0 for v in p2_seq) and p2_seq == sorted(p2_seq), f"Contexto de P2 corrompido: {p2_seq}"
        assert len(sim.irq_entries) >= 8, "Poucas trocas de contexto observadas!"
        print(f"    Total de trocas de contexto validadas: {len(sim.irq_entries)}")
        print("    [PASS] PCBs isolados preservaram r2/r5/sp entre multiplas trocas de contexto!")

    elif test_id == 5:
        vals = [v for _, _, v in sim.out_events]
        assert 404 not in vals, "Corrupcao detectada na pilha isolada (codigo 404)!"
        assert len(sim.irq_entries) >= 10, f"Esperado >= 10 interrupcoes, ocorreram {len(sim.irq_entries)}"
        p1_stack_val = sim.ram_data[399]
        p2_stack_val = sim.ram_data[419]
        print(f"    IRQs suportadas: {len(sim.irq_entries)} | MEM[399] (pilha P1)={p1_stack_val} | MEM[419] (pilha P2)={p2_stack_val}")
        assert p1_stack_val == 1 and p2_stack_val == 2, "Regioes de pilha P1(399) e P2(419) nao ficaram isoladas!"
        print("    [PASS] Zero corrupcao e isolamento total entre pilhas sp=400 e sp=420!")

    return True


def invalidate_quartus_hd_cache() -> None:
    """Remove MIF cache do hd_emulado em db/ e atualiza mtime para forcar re-leitura no Quartus."""
    db_dir = QUARTUS_DIR / "db"
    if db_dir.exists():
        for mif in db_dir.glob("*hd_emulado*.hdl.mif"):
            mif.unlink()
            print(f"[CACHE] Removido cache antigo do Quartus: {mif.name}")
    if HD_VERILOG_PATH.exists():
        os.utime(HD_VERILOG_PATH, None)


def compile_quartus() -> None:
    """Executa compilacao completa do Quartus para gerar novo output_files/Processador.sof."""
    if not QUARTUS_SH.exists():
        print(f"quartus_sh nao encontrado em {QUARTUS_SH}", file=sys.stderr)
        sys.exit(1)
    print("[QUARTUS] Iniciando compilacao completa (quartus_sh --flow compile Processador)...")
    res = subprocess.run(
        [str(QUARTUS_SH), "--flow", "compile", "Processador"],
        cwd=str(QUARTUS_DIR),
    )
    if res.returncode != 0:
        sys.exit(res.returncode)
    print(f"[OK] Bitstream atualizado: {QUARTUS_DIR / 'output_files' / 'Processador.sof'}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Gerenciador de Testes Modulares do PC3")
    parser.add_argument("--gerar-todos", action="store_true", help="Gera todas as imagens .hex em testes_pc3/hex/")
    parser.add_argument("--executar-todos", action="store_true", help="Gera e simula todos os 5 testes do PC3")
    parser.add_argument("--executar", type=int, choices=list(TESTS.keys()), help="Simula apenas um teste (1..5)")
    parser.add_argument("--aplicar", type=int, choices=list(TESTS.keys()), help="Aplica imagem do teste escolhido em hd_conteudo.hex")
    parser.add_argument("--compilar", action="store_true", help="Recompila o projeto no Quartus apos aplicar/restaurar para gerar novo .sof")
    parser.add_argument("--restaurar", action="store_true", help="Restaura hd_conteudo.hex original a partir do backup")
    args = parser.parse_args()

    if args.gerar_todos:
        for tid in TESTS:
            p = build_hex_image(tid)
            print(f"[OK] Gerado {p}")

    if args.executar:
        run_test(args.executar)

    if args.executar_todos:
        for tid in TESTS:
            run_test(tid)
        print("\nTODOS OS 5 TESTES MODULARES DO PC3 PASSARAM COM SUCESSO!")

    if args.aplicar:
        if not BACKUP_PATH.exists():
            shutil.copy2(HD_DEST_PATH, BACKUP_PATH)
            print(f"[BACKUP] Salvo kernel original em {BACKUP_PATH}")
        hex_path = build_hex_image(args.aplicar)
        shutil.copy2(hex_path, HD_DEST_PATH)
        invalidate_quartus_hd_cache()
        print(f"[OK] Aplicado Teste 0{args.aplicar} em {HD_DEST_PATH}")

    if args.restaurar:
        if not BACKUP_PATH.exists():
            print("Nenhum backup encontrado em testes_pc3/backup_hd_conteudo.hex", file=sys.stderr)
            sys.exit(1)
        shutil.copy2(BACKUP_PATH, HD_DEST_PATH)
        invalidate_quartus_hd_cache()
        print(f"[OK] Restaurado kernel original em {HD_DEST_PATH}")

    if args.compilar:
        compile_quartus()

    if not any([args.gerar_todos, args.executar_todos, args.executar, args.aplicar, args.restaurar, args.compilar]):
        parser.print_help()


if __name__ == "__main__":
    main()
