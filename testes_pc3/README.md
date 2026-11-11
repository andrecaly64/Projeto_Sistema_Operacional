# Testes Modulares do PC3 (`testes_pc3/`)

Conjunto de **5 testes independentes** em Assembly ARM customizado (`.s`) com imagens de HD geradas em `testes_pc3/hex/` e simulador/gerenciador em [`gerenciar_testes.py`](gerenciar_testes.py).

## Bateria de Testes

| Teste | Bateria / Foco | Arquivo Assembly | Comportamento Esperado na DE2-115 (5 Hz) |
| :--- | :--- | :--- | :--- |
| **01** | **Bateria A** — BIOS ROM, HD Emulado e DMA | `01_teste_bios_dma.s` | LCD: `P: 0` (BIOS) → `P: 1` (RAM) → `P: 9` (Setor 2 carregado por DMA em `RAM[48]`). 7-Seg: `11` → `42`. |
| **02** | **Bateria B1** — Mascaramento `CLI`/`STI`, Vetor `PC=4` e `RETI` | `02_teste_cli_sti_interrupcao.s` | LCD fica `P: 1` e 7-Seg conta `0..7` com `CLI` (sem interromper apesar do Timer em `45`); ao executar `STI`, muda para `P: 2` e pula para `108, 109`, `210, 211`... |
| **03** | **Bateria B2** — Quantum Programável (`timer.v` `1004..1006`) | `03_teste_timer_quantum.s` | Alterna `P: 1` (quantum curto `limit=40`, conta `0..5`) e `P: 2` (quantum longo `limit=100`, conta `0..15`). |
| **04** | **Bateria C** — Troca de Contexto (PCBs + LCD `1007` + `RETI`) | `04_teste_troca_contexto.s` | `P: 1` conta `+1` (`0, 1, 2...`); `P: 2` conta `+2` (`100, 102, 104...`); cada retorno via `RETI` preserva os valores salvos em `PCB1` (`450..452`) e `PCB2` (`460..462`). |
| **05** | **Bateria D** — Pilhas Isoladas (`sp=400` vs `sp=420`) | `05_teste_pilhas_isoladas.s` | Empilha/desempilha assinatura de PID sob interrupções (`limit=65`). Alterna `P: 1` (`10, 11, 12...`) e `P: 2` (`200, 201, 202...`). Em caso de corrupção, trava exibindo `404`. |

## Comandos

```bash
# Rodar todos os 5 testes no simulador comportamental (gera os .hex e verifica assercoes):
python3 testes_pc3/gerenciar_testes.py --executar-todos

# Rodar apenas um teste especifico (1 a 5):
python3 testes_pc3/gerenciar_testes.py --executar 4

# Aplicar um teste em hd_conteudo.hex e já recompilar o bitstream (.sof) no Quartus:
python3 testes_pc3/gerenciar_testes.py --aplicar 2 --compilar

# Restaurar o hd_conteudo.hex original salvo em backup_hd_conteudo.hex (e recompilar se desejar):
python3 testes_pc3/gerenciar_testes.py --restaurar --compilar
```

## Observações de Arquitetura Observadas nos Testes
- **`RAM[11]` após `modo_boot` (`1 -> 0`):** na implementação de `Processador.v`, `modo_boot` é desativado quando `endereco_pc == 11`, transferindo a execução diretamente para `RAM[11]`. Por isso todos os testes posicionam `main_so` em `RAM[11]`.
- **Proteção no Vetor `PC=4` (`NOP` em `RAM[4]`):** previne salto indevido quando uma interrupção coincide exatamente com o ciclo final de uma instrução `B` com leitura síncrona de memória.
- **Preenchimento após o loop final:** os endereços livres finais do Setor 1 são preenchidos com `B <loop>` para garantir retorno seguro do `RETI`.
