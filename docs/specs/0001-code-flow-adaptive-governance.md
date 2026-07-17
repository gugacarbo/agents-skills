---
status: accepted
date: 2026-07-16
builds-on: []
implemented-by: []
---

# Code-flow aplica governança proporcional ao risco sem misturar workflows

## Objetivo

Reduzir cerimônia em entregas internas e reversíveis sem enfraquecer controles
de segurança, contratos ou migrações. A skill continua issue-based, mantém
reviews independentes e nunca faz merge sem decisão humana.

## Fluxo

1. Validar que o alvo é uma issue de entrega/bug e descobrir o padrão do
   repositório sem mutação.
2. Recalcular uma classificação efêmera antes de interpretar o estado.
3. Resolver uma única máquina: fallback se houver `stage:*`; workflow nativo
   elegível somente após opt-in explícito para a execução atual.
4. Escolher papéis e gates pelo nível mais restritivo.
5. Executar em worktree isolada, revisar independentemente e oferecer merge.
6. Em risco novo, promover e retornar ao primeiro gate que passou a ser
   obrigatório.

## Contrato

### Classificação efêmera

- `light`: mudança interna, localizada, reversível e `Spec impact: not required`.
- `standard`: default para mudança observável ou transversal moderada,
  reversível e concentrada em um repositório.
- `assured`: auth, autorização, permissões, segurança, segredos, migração,
  contrato público, conflito de fontes, cross-repo, irreversibilidade ou alto
  blast radius.

O nome nunca é persistido. O usuário pode aumentar rigor; hard trigger nunca é
rebaixado. O nível é recalculado em criação e resume.

`Spec impact: create` fica reservado a novo contrato público ou decisão
durável que precisa de fonte canônica; comportamento observável localizado não
abre source gate por si só quando nenhuma fonte aceita é afetada.

O source-set aprovado no body governa o plano. ADR/spec em arquivo é parte da
implementação e só é materializado pelo executor na worktree autorizada, nunca
pelo orquestrador antes do plano. O gate registra URL da decisão e SHA-256 do
body; plano e dispatch revalidam esse digest e invalidam aprovação divergente.

### Papéis

O pacote publica exatamente `issue-writer`, `issue-reviewer`, `plan-writer`,
`plan-reviewer`, `executor` e `delivery-reviewer`. Publicação não implica
invocação universal.

- `light`: issue-writer, executor que publica outline e implementa, e delivery
  reviewer fresco. Sem gates humanos de fonte/plano.
- `standard`: source gate somente em `create/update`; plan writer/reviewer,
  aprovação humana, executor e delivery review. Auditoria final é condicional.
- `assured`: source review/aprovação, plan review/aprovação, executor, delivery
  review e auditoria final por instância fresca.

Ninguém revisa, aprova ou audita trabalho próprio.

### Estado fallback

Uma issue ativa tem exatamente um `stage:*`. Em `light`,
`stage:approved + needs-human` significa que o racional no-spec está pronto e
aguarda a única autorização humana antes do código: a ordem explícita de
executar. Depois dela, a worktree é criada automaticamente e o estado vai para
`stage:in-progress`. Nos demais níveis, `stage:approved` exige plano aprovado.

Labels fallback ausentes são criadas idempotentemente apenas durante mutação
real. Dry-run não cria labels. O helper preserva precondição, confirmação e
reparo de drift.

### Workflow nativo

Discovery e validação são read-only. Workflow nativo precisa mapear estado
retomável, gates aplicáveis, evidência, review independente e merge explícito.
Mesmo elegível, exige opt-in humano.

O opt-in não é persistido. Em toda retomada nativa, a skill revalida o
mapeamento e pede nova confirmação. Sem confirmação, recusa ou incompatibilidade,
a skill encerra sua atuação naquela issue sem publicar, mutar ou fechar. Nunca
migra automaticamente para fallback. Qualquer `stage:*` existente fixa o
fallback.

### Brainstorm e merge

Brainstorm é prompt condicional: só é oferecido quando há decisão importante
aberta e só roda após aceite. O gate de design só existe quando brainstorm foi
executado. Merge é sempre uma decisão humana explícita.

## Casos de borda

| #   | QUANDO                                             | o sistema DEVE                                           |
| --- | -------------------------------------------------- | -------------------------------------------------------- |
| 1   | rename interno, reversível e no-spec               | criar issue no gate de execução, sem source/plan review. |
| 2   | hard trigger aparece em diff pequeno               | usar `assured`; tamanho não permite downgrade.           |
| 3   | `stage:approved` é retomado                        | recalcular risco antes de interpretar o stage.           |
| 4   | contrato público surge após caminho interno        | promover e voltar ao source gate.                        |
| 5   | issue nova tem workflow nativo elegível sem opt-in | usar fallback.                                           |
| 6   | issue nativa é retomada                            | revalidar e pedir novo opt-in.                           |
| 7   | opt-in nativo não é reconfirmado                   | encerrar sem qualquer mutação.                           |
| 8   | existe qualquer `stage:*`                          | manter fallback e não oferecer nativo.                   |
| 9   | label fallback necessária não existe               | criar idempotentemente em execução real.                 |
| 10  | brainstorming não foi aceito                       | não executá-lo nem abrir gate de design.                 |
| 11  | reviewer participou da autoria                     | rejeitar a combinação e usar instância independente.     |
| 12  | PR está aprovado                                   | ainda aguardar pedido explícito de merge.                |

## Questões em aberto

Nenhuma.

## Definition of Done

- [ ] Router, operações, agentes, templates e referências descrevem a mesma
      matriz adaptativa e cobrem os casos 1–12.
- [ ] Nenhum template/evidência persiste `light`, `standard` ou `assured`.
- [ ] Não existem rota bootstrap, `scripts/bootstrap.sh` ou suporte `.code-flow`.
- [ ] Testes fake-gh provam criação idempotente de labels e dry-run sem mutação.
- [ ] Evals pareados preservam 5/5 nos hard triggers/independência/opt-in/merge
      e obtêm ao menos 4/5 nos cenários não críticos.
- [ ] Fonte e `dist/skills/code-flow` estão coerentes e sem tooling privado.

```bash
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-code-flow build
pnpm test
pnpm build
pnpm skills-check
python3 scripts/docs-check
git diff --check
```

## Revisão humana

- Revisar os prompts e resultados pareados das avaliações comportamentais.
- Confirmar merge somente após PR, reviews e DoD.

## Verificação

```text
(preencher no fechamento)
```
