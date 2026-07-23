# Protocolo GitHub da code-flow

`code-flow:active` ativa o protocolo. Enquanto presente, exatamente um estado
principal de `workflow-states.json` identifica o próximo responsável. O overlay
`stage:in-progress` pode coexistir com esse estado durante uma execução.

| Label | Próximo responsável | Exige `needs-human` |
| --- | --- | --- |
| `stage:needs-triage` | issue-writer | não |
| `stage:awaiting-triage-approval` | humano | sim |
| `stage:needs-architect` | architect | não |
| `stage:awaiting-execution-approval` | humano | sim |
| `stage:ready-for-execution` | executor | não |
| `stage:needs-changes` | executor | não |
| `stage:needs-delivery-review` | reviewer | não |
| `stage:ready-to-merge` | humano | sim |
| `stage:integration-authorized` | integrator | não |
| `stage:blocked` | responsável do Resume | sim |

## Invariantes

- Issue ativa: `code-flow:active` + um estado principal.
- Atividade: estado principal + `stage:in-progress`, nunca `needs-human`.
- Gate: estado humano + `needs-human`, nunca `stage:in-progress`.
- Overlay observado bloqueia cooperativamente novo início; não é lock atômico.
- Evidência precede toda mutação e a confirmação remota a sucede.
- Um agente aplica a transição causada por seu próprio artefato; `gate` aplica
  apenas uma decisão humana já fornecida.

Use `scripts/transition-issue.sh` com `--require-from`. `--start-work` adiciona
somente o overlay. `--finish-to` substitui o estado principal e remove overlay.
`--activate` inicia uma issue; `--complete` limpa labels após fechamento/saída.

## Migração segura

Issue sem `code-flow:active` nunca é adotada automaticamente. Se houver labels
legadas, publique primeiro a proposta:

| Legado | Destino após confirmação |
| --- | --- |
| `stage:needs-architect` | mesmo estado |
| `stage:approved` | `stage:awaiting-execution-approval + needs-human` |
| `stage:needs-delivery-review` | mesmo estado |
| `stage:needs-changes` | mesmo estado |
| `stage:ready-to-merge` | mesmo estado + `needs-human` |
| `stage:ready-to-close` | `stage:integration-authorized` |
| `stage:blocked` | mesmo estado + `needs-human` |
| `stage:in-progress` sozinho | ambíguo; reconstruir por evidência e pedir escolha |

Não escreva `Workflow` no body. A skill continua lendo branch protection,
forms, comandos e método de merge do repositório; somente seu estado de entrega
usa labels canônicas.

## Falha parcial

As APIs de label não formam uma transação. O helper relê e confirma cada
resultado, retorna erro em drift e aceita reparo somente com `--allow-repair`.
Não alegue exclusão concorrente ou sucesso quando a confirmação final falhar.
