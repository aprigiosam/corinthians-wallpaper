# Corinthians Wallpaper

Baixa fotos públicas da Agência Corinthians e aplica como wallpaper no Ubuntu/GNOME.

- Script: `~/Scripts/corinthians-wallpaper/corinthians-wallpaper` (link em `~/.local/bin`)
- Acervo: `~/Pictures/Corinthians-Agencia`
- Dependências: Python 3, Pillow, `xrandr`, `gsettings`

## Instalação

```bash
git clone <repo> ~/Scripts/corinthians-wallpaper   # as units usam este caminho (%h/Scripts/...)
~/Scripts/corinthians-wallpaper/install.sh
```

O `install.sh` cria symlinks do script em `~/.local/bin` e das units de `systemd/` em
`~/.config/systemd/user`, e ativa os timers. O repo é a fonte da verdade: editou a unit,
basta rodar `systemctl --user daemon-reload`.

## Comandos

| Comando   | O que faz |
|-----------|-----------|
| `sync`    | Baixa fotos novas (até 30 por execução, acervo máximo de 90) |
| `rotate`  | Troca o wallpaper pela próxima foto da fila |
| `daily`   | Uma foto fixa por dia |
| `prepare` | Re-renderiza todo o `wallpaper-ready/` e apaga renders antigos |

Opções do `sync`: `--limit`, `--max-photos`, `--max-pages`, `--page-url`.

## Como funciona

**sync** — percorre a Agência da página mais recente para trás até achar fotos já
conhecidas. Com o acervo cheio, as mais antigas saem para dar lugar às novas.
- Erro em um álbum ou foto é registrado e ignorado; o resto continua.
- Download vai para `.part`, é validado como imagem e só então é movido.
- O manifesto é salvo mesmo com erro/Ctrl+C no meio, evitando downloads duplicados.
- Site inacessível → sai com código 1 (aparece como falha no systemd).

**rotate** — fila embaralhada: passa por todas as fotos antes de repetir.
Fotos do último `sync` têm prioridade por **48h** (`RECENT_TTL`); depois, o acervo
inteiro volta para a fila.

**daily** — escolhe uma foto e registra no `state.json`; ela fica fixa o dia todo,
mesmo se o acervo mudar.

**Renderização** (`wallpaper-ready/`) — as fotos públicas têm no máximo ~1000px,
então ampliar para 1920x1080 borra. Regra:
- formato próximo de 16:9 **e** ampliação ≤ 1.3x (`MAX_UPSCALE`) → preenche a tela;
- caso contrário → foto centralizada (ampliada no máximo 1.3x) sobre fundo desfocado.
- Resolução vem do monitor primário (`xrandr`), fallback 1920x1080.
- Arquivo: `<foto>-<W>x<H>-v<RENDER_VERSION>.jpg`. Ao mudar a regra, incremente
  `RENDER_VERSION` e rode `prepare`.

A marca d'água é mantida, e os créditos ficam em `CREDITOS.txt`.

## Automação (systemd --user)

| Timer | Quando | Ação |
|-------|--------|------|
| `corinthians-wallpaper.timer` | 1 min após login e depois a cada 1h | `rotate` |
| `corinthians-wallpaper-sync.timer` | diário às 09:00 (±15 min; roda depois se o note estava desligado) | `sync` |

```bash
systemctl --user list-timers | grep corinthians
journalctl --user -u corinthians-wallpaper-sync.service -n 20
```

## Arquivos de controle (`~/Pictures/Corinthians-Agencia`)

- `manifest.json` — acervo, da foto mais recente para a mais antiga
- `state.json` — última foto aplicada, fila do `rotate` e foto do dia
- `recent-downloads.json` — último lote baixado (vale por 48h no `rotate`)
- `CREDITOS.txt` — créditos e fontes, gerado a cada `sync`

Os JSONs são gravados de forma atômica (`.tmp` + rename); JSON corrompido é tratado como vazio.

## Changelog

### 2026-10-15
- **rotate**: o lote recente tinha prioridade para sempre, e 60 das 90 fotos nunca
  apareciam. Agora a prioridade expira em 48h, e a escolha usa fila embaralhada.
- **sync automático**: novo timer diário (antes o sync só rodava na mão).
- **render**: ampliação limitada a 1.3x (as fotos eram ampliadas ~2x e ficavam borradas);
  versionamento dos renders; `prepare` limpa renders antigos.
- **sync robusto**: erro por álbum/foto, download atômico e validado, manifesto salvo
  no `finally`, exit 1 com site fora do ar.
- **daily**: foto do dia fixada no `state.json`.
- `xrandr` usa o monitor primário e é consultado uma vez por execução.
- Timer do rotate: removido o `Persistent=true` (sem efeito com `OnUnitActiveSec`).
- Projeto versionado em git; units movidas para `systemd/` (com `%h`) e `install.sh`.
