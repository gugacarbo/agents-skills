# Runtime VPS distribuído (design planejado)

> **Status:** planejado, não implementado. A skill code-flow é o contrato; o
> runner descrito aqui é um componente externo futuro. Esta página documenta o
> design para alinhamento e para guiar a evolução da skill sem quebrar o
> contrato.

## Limitações atuais

A skill hoje oferece somente sinalização cooperativa por `stage:in-progress`:
dois workers VPS podem ler o mesmo estado, ambos publicarem início e ambos
começarem a trabalhar. Não há lock atômico, `worker_id`, TTL nem recuperação
automática de overlay órfão. `scripts/validate-evidence.sh` detecta
overlay/evidência inconsistentes e lease expirado, mas não remove nada
automaticamente — exige gate humano `activity reset`.

## Componente externo: `code-flow-runner`

O runner é separado da skill e responsável por:

1. **Descoberta:** poll ou webhook GitHub → label → papel elegível.
2. **Claim atômico:** adquirir atividade com `worker_id`, `run_id`, expiração e
   renovação, evitando que dois workers peguem a mesma issue.
3. **Retry/expiração:** regra de retry para falhas transitórias e expiração de
   lease abandonado (worker morto ou travado).
4. **Worktree por issue/run:** isolamento de filesystem entre workers.
5. **Invocação portátil:** CLI estável para despachar um papel em uma issue.

### Descoberta de trabalho elegível

Query canônica por papel (ex.: executor):

```sh
gh issue list --repo <owner/repo> \
  --label "code-flow:active,stage:ready-for-execution" \
  --search "-label:needs-human -label:stage:in-progress"
```

O runner mantém um mapa papel → `trigger_labels` (derivado de
`workflow-states.json`) e filtra por `needs-human` e `stage:in-progress`
ausentes.

### Claim atômico com lease

O claim deve ser atômico para evitar race. Opções de implementação:

- **GitHub Project V2 field:** usar um campo `code-flow-worker` no Project V2
  como lock; o claim faz `updateProjectV2FieldValue` condicional (compare-and-set).
- **Comentário canônico de lease:** publicar
  `<!-- code-flow:lease:start worker_id=... run_id=... ttl=... ts=... -->` antes
  de adicionar `stage:in-progress`; o runner relê e confirma que só o próprio
  `worker_id` está no lease. Não é atômico, mas reduz a janela de race.
- **Serviço externo:** Redis/Postgres com `SET NX` ou `SELECT FOR UPDATE` para
  lock distribuído real. Mais robusto, exige infra.

O campo `lease_ttl` no comentário `activity-start` (template 06) já é suportado
por `validate-evidence.sh` para detecção de expiração.

### Worktree por issue/run

Convenção de path para evitar colisão entre workers:

```text
<workspace>/code-flow/<owner>-<repo>/<issue>-<run_id-short>
```

Ex.: `~/vps/code-flow/acme-demo/42-a1b2c3d4`. O executor e o integrator usam a
mesma worktree dentro de um run; runs diferentes da mesma issue usam paths
diferentes.

### Invocação portátil

CLI estável para despachar um papel:

```sh
code-flow-worker --role executor --issue <URL> --lease <token> [--run-id <uuid>]
```

O runner resolve a issue, valida o estado via `transition-issue.sh --dry-run`,
faz o claim, invoca o agente (codex/claude/outra) com o prompt do papel
do executor, coleta o resultado e chama
`transition-issue.sh --finish-to` ou `--reset-activity`.

### Recuperação de overlay órfão

Quando `validate-evidence.sh` detecta lease expirado, o runner não remove
automaticamente. Fluxo de recuperação:

1. Runner detecta lease expirado via poll periódico.
2. Publica um comentário `activity-reset` com motivo e evidência.
3. Chama `transition-issue.sh --reset-activity --require-from <stage>`.
4. A issue volta a estar elegível para outro worker.

Se o worker original ainda estiver vivo, o reset é um conflito — o runner deve
usar backoff e confirmar via heartbeat antes de resetar.

### Runbook de recuperação

| Sintoma                                  | Ação                                                                         |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `stage:in-progress` sem `activity-start` | `validate-evidence.sh` reporta erro; humano decide `activity reset`          |
| Lease expirado, worker morto             | Runner reseta via `--reset-activity` após heartbeat negativo                 |
| Dois workers na mesma issue              | Segundo worker recua ao detectar overlay; se ambos publicaram, humano decide |
| `protocol_version` incompatível          | Worker recusa evidência; atualiza skill ou pede migração                     |

## Evolução da skill

A skill permanece como contrato: labels, estados, evidência, papéis e gates.
O runner consome o contrato via `workflow-states.json`, `transition-issue.sh`,
`validate-evidence.sh` e os templates. Mudanças no contrato exigem bump de
`schema_version` em `workflow-states.json` e são detectadas via
`protocol_version` nas evidências.
