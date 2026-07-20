# Workflow GitHub: nativo ou fallback

Plano, código, review e integração exigem issue de entrega/bug. Epic, auditoria
avulsa e tracker genérico não recebem mutação de entrega.

## Metadata no body

O header operacional, fora dos marcadores do source-set, contém:

```markdown
| Complexity | `S | M | G | X | XL` |
| Workflow | `native | fallback` |
```

O orquestrador propõe `Complexity`; a primeira escolha de workflow segue o
mapeamento de [`templates/16-native-workflow-mapping.md`](../templates/16-native-workflow-mapping.md).

## Tabela de verdade

| Header           | Estado observado                                  | Resultado obrigatório                                      |
| ---------------- | ------------------------------------------------- | ---------------------------------------------------------- |
| `fallback`       | exatamente um `stage:*`                           | válido                                                     |
| `native`         | zero `stage:*` e mapeamento nativo ainda `PASS`   | válido; reutilize a escolha                                |
| `native`         | qualquer `stage:*`                                | `WORKFLOW_DRIFT`; pare e peça reparo                       |
| `fallback`       | zero/múltiplos `stage:*` ou marcador nativo ativo | `WORKFLOW_DRIFT`; pare e peça reparo                       |
| ausente (legado) | exatamente um `stage:*`                           | registre fallback, proponha Complexity, preserve o gate    |
| ausente          | zero `stage:*`                                    | discovery; valide nativo e obtenha a escolha inicial       |
| `native`         | mapeamento perdeu qualquer capacidade obrigatória | `NATIVE_INVALID`; ofereça migração explícita para fallback |

Não escolha silenciosamente entre fontes contraditórias. Metadata operacional
fica fora do digest do source-set; adicioná-la a issue legada não invalida o
gate de fonte.

Na resposta sobre legado, diga explicitamente que o stage/gate atual e o bloco
protegido permanecem intactos: adicionar `Complexity`/`Workflow` fora dos
marcadores não muda o digest nem invalida o source-set.

## Seleção inicial

1. Descubra guidance, forms, labels, estados, gates, evidência e entregas
   recentes sem mutar.
2. Recalcule risco/complexidade antes de interpretar estado.
3. Sem metadata, preencha o mapeamento nativo. Se alguma linha falhar, declare
   `NATIVE_INCOMPLETE`, selecione fallback e crie o stage inicial aplicável.
4. Com todas as linhas `PASS`, declare `NATIVE_ELIGIBLE` e peça opt-in
   explícito. `Yes` persiste `Workflow: native`; ausência/recusa persiste
   `Workflow: fallback` e segue fallback.
5. Em retomada válida, não peça novamente. Revalide somente após mudança
   material de escopo, guidance ou capacidades do workflow.

Não resuma a seleção apenas como “todos PASS”: antes do opt-in, apresente cada
linha do mapeamento nativo → gate/evidência. Persista `Workflow` no header,
explicitamente fora dos marcadores protegidos do source-set.

## Migração native → fallback

Nunca migre silenciosamente. Após aceite humano:

1. capture o estado original: body, estados nativos e gate equivalente;
2. publique evidência com alvo e estratégia de compensação;
3. atualize `Workflow: fallback` e aplique exatamente um `stage:*` equivalente;
4. se uma metade falhar, restaure o snapshot anterior ou marque drift sem
   avançar o gate;
5. confirme body e labels/status finais antes de continuar.

Fallback → native não é automático; `stage:*` existente exige reparo/migração
explícita.

## Stages fallback

Exatamente um `stage:*` representa o próximo ator/gate enquanto a issue está
ativa.

| Label                         | Próxima ação                                               |
| ----------------------------- | ---------------------------------------------------------- |
| `stage:spec-approval`         | Review/gate de source-set conforme rigor.                  |
| `stage:needs-issue-fix`       | Corrigir source-set.                                       |
| `stage:needs-plan`            | Produzir plano formal.                                     |
| `stage:needs-plan-review`     | Review independente e depois gate humano.                  |
| `stage:needs-plan-fix`        | Novo ciclo de plano.                                       |
| `stage:approved`              | Aguardar ordem explícita; criar worktree.                  |
| `stage:in-progress`           | Implementar/corrigir escopo autorizado.                    |
| `stage:needs-delivery-review` | Review independente de `DONE`, ressalvas ou `NO_CHANGES`.  |
| `stage:needs-changes`         | Executor corrige achados.                                  |
| `stage:ready-to-merge`        | Auditoria aplicável e gate `Integrar/Ajustar/Aguardar`.    |
| `stage:ready-to-close`        | Gate `Fechar/Ajustar/Aguardar` para `NO_CHANGES` aprovado. |
| `stage:blocked`               | Resolver blocker e usar o resume target publicado.         |

`needs-human` é ortogonal e aparece somente quando o próximo ator é humano.
Remova-o ao devolver trabalho a agente. Após merge/close, limpe ambos.

## Ownership

- Agente aplica a transição causada pelo artefato/veredito que publicou.
- Orquestrador valida precondição, evidência e estado final.
- Orquestrador aplica transições causadas por decisão humana: source gate,
  plan gate, unblock, merge, close e checkpoint de Epic/batch.
- Executor entra em `stage:in-progress` somente após evidência de início e
  validação do orquestrador.

A matriz canônica completa vive em
[`label-mutation-matrix.md`](label-mutation-matrix.md). Comentário ou texto de
stage nunca substitui mutação.

## Mutação fallback

Use `scripts/transition-issue.sh` internamente com `--require-from` quando
aplicável, publique evidência primeiro e confirme via `gh issue view`. O helper
é idempotente, allow-listed e não decide workflow/gate. `--dry-run` não cria ou
altera labels; `--allow-repair` exige reparo explicitamente autorizado.
