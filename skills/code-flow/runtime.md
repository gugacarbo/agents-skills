# Runtime compartilhado

## Discovery e ativação

Redescubra sempre o guidance nearest-wins, forms, ADR/spec, código, testes,
labels, comentários, PRs, branch protection e workflow Git. Registre paths e
comandos em `project_guidance`; não pergunte fatos descobríveis.

`/code-flow` sem issue é read-only. Com issue, rejeite labels `stage:*`
desconhecidas. Se as labels canônicas não existirem, provisione somente as
ausentes; uma issue inativa e limpa recebe `code-flow:active +
stage:needs-triage`. Issue ativa é retomada a partir do estado remoto.

O orquestrador relê labels após cada papel e despacha uma instância nova. Pare
em estado humano, blocker, conclusão, overlay incompatível ou após dez papéis;
no limite, publique handoff e preserve o estado atual.

## Complexidade e risco

O dispatcher persiste `Complexity: XS | S | M | L | XL` e evidencia:

| Dimensão        | Pergunta                                       |
| --------------- | ---------------------------------------------- |
| Áreas           | Quantos componentes e contratos são tocados?   |
| Acoplamento     | Quantas mudanças dependem umas das outras?     |
| Validação       | O caminho de prova é conhecido e rotineiro?    |
| Reversibilidade | O rollback é simples e demonstrável?           |
| Dependências    | Há coordenação interna, externa ou cross-repo? |
| Incerteza       | Existem decisões materiais ainda abertas?      |

- XS: interna, uma área, caminho conhecido, reversível e sem acoplamento.
- S: um componente, poucas mudanças acopladas e validação rotineira.
- M: vários componentes ou coordenação relevante no repositório.
- L: mudança transversal ou incerteza significativa.
- XL: múltiplos resultados/dependências; recomende decomposição ou Epic.

Comportamento observável começa em S até todos os critérios de XS serem
comprovados. Hard triggers: autenticação/autorização, permissões/segredos,
migração de dados/esquema, contrato público, conflito com ADR/spec, cross-repo,
irreversibilidade, alto blast radius, operação destrutiva/privilegiada ou
rollback não demonstrado.

XS/S sem hard trigger seguem diretamente à execução. M+, hard trigger ou risco
promovido exigem triagem humana e architect. Risco é efêmero e deve ser
recalculado em retomada, mudança de base ou escopo.

## Protocolo GitHub

Issue ativa tem `code-flow:active` e exatamente um estado principal do registry.
Atividade acrescenta `stage:in-progress` e nunca `needs-human`. Estado humano
acrescenta `needs-human` e nunca overlay. Evidência precede mutação; confirmação
remota a sucede. Labels são sinalização cooperativa, não lock atômico.

Todo comentário operacional começa com `agent`, `run_id`, `event`,
`state_before`, `state_after`, `sources_evidence` e `project_guidance`, seguido
de `## Resume`. Antes do overlay, publique `activity-start` com papel, estado,
fontes, Base/Head e branch/worktree quando aplicável.

Overlay existente só pode ser retomado pelo mesmo papel, estado e run_id
comprovados no último `activity-start`. Sem correspondência, exija gate humano
`activity reset`, que remove somente o overlay.

Blocker deixa `stage:blocked + needs-human`, sem overlay, e registra no `Resume`
o estado exato a restaurar, responsável, impedimento e evidência. `resume`
restaura somente esse estado.

## Gates e saída

- triage: `approve | adjust | block`;
- execution: `authorize | adjust | block`;
- merge: `integrate | adjust | wait`;
- resume: estado registrado no `Resume`;
- activity: `reset`.

Gate valida estado, ausência de overlay, evidência, Base/Head e opção; publica
decisão antes da transição. Merge com diff exige `integrate`; `NO_CHANGES`
aprovado segue sem gate de merge.

`stop` mostra trabalho não integrado e oferece encerrar/manter. Com atividade,
publique handoff e resete o overlay antes de `--stop`. Encerrar remove somente
labels do protocolo; nunca fecha issue/PR, apaga worktree/branch ou reverte
código.

## Independência e drift

Code-reviewer roda em instância nova e recebe somente issue, guidance e
artefatos publicados. Pode usar a mesma conta GitHub, mas seu run_id não pode
coincidir com run_ids de dispatcher, architect ou executor; registre os run_ids
revisados. Sem instância nova comprovável, peça review humana.

Drift não material atualiza Base e repete checks. Mudança material na área,
contrato ou dependência exige nova code review; hard trigger novo retorna ao
architect. Falha parcial nunca é sucesso: preserve o estado observável e
publique recuperação.
