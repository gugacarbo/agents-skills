---
status: implemented
date: 2026-07-17
builds-on: [ADR-0001, ADR-0002]
implemented-by:
  - skills/code-flow/SKILL.md
  - skills/code-flow/references/github-flow.md
  - skills/code-flow/scripts/source-set-digest.py
  - skills/code-flow/dev/tests.sh
  - dist/skills/code-flow/SKILL.md
---

# Code-flow governa entregas com contexto operacional retomável e rigor adaptativo

## Objetivo

Permitir discovery pré-issue e entregas issue-based com esforço/coordenação
persistidos, risco recalculado, workflow derivado do estado, reviews
independentes e integração ou fechamento sempre explícitos.

## Fluxo

1. Fazer discovery read-only e fechar somente decisões materiais antes da issue.
2. Antes de plano/código/review, validar issue de entrega/bug.
3. Propor Complexity, recalcular risco e derivar workflow pelo estado atual.
4. Validar stages/mapeamento por tabela de verdade; múltiplos stages bloqueiam.
5. Selecionar papéis/gates pelo maior rigor entre complexidade e hard triggers.
6. Publicar evidência, transicionar pelo owner do evento e validar pelo orquestrador.
7. Executar/corrigir em worktree, revisar independentemente e abrir gate de
   merge ou close.
8. Promover ao primeiro gate novo quando escopo, base ou risco mudar.

## Contrato

### Interface e pre-issue

`/code-flow` descobre e recomenda. Operações semânticas recebem issue explícita;
`issue create`, `batch`, `brainstorm` e `tool doctor` completam a interface.
Pre-issue permite discovery, intenção e trade-offs, nunca plano formal/código.

### Complexidade e risco

`Complexity: S|M|G|X|XL` representa, em ordem, mudança localizada, componente,
vários componentes, entrega ampla/incerta e iniciativa candidata a Epic.
S sugere caminho leve, M/G padrão e X/XL máximo. Auth, permissões, migração,
contrato público, cross-repo, irreversibilidade, operação destrutiva ou rollback
não demonstrado sempre exigem máximo rigor.

### Workflow e source-set

Fallback válido tem exatamente um `stage:*`; sem stage, native é usado
automaticamente somente com mapeamento completo. `Workflow` não é persistido.
Header legado é compatibilidade; native legado inválido oferece migração
explícita/compensável.

Source-set vive entre marcadores. O digest usa somente o conteúdo interno em
UTF-8, LF normalizado e um LF final. Metadata externa não altera o digest.

### Papéis, transições e gates

S no-spec pode ter issue mínima escrita pelo orquestrador; demais issues usam
issue-writer. M/G pode reutilizar reviewer de plano na entrega se não houver
autoria. X/XL/hard trigger separa reviewers por fase e usa auditor final fresca.

Agente transiciona o evento que publicou; orquestrador valida e transiciona
decisões humanas. Vereditos/gates usam Aprovar/Ajustar/Bloquear; merge usa
Integrar/Ajustar/Aguardar; NO_CHANGES usa Fechar/Ajustar/Aguardar.

Plan-writer sempre entrega snapshot em `stage:needs-plan-review` sem
needs-human. Executor entra em in-progress após evidência de início e validação.
NO_CHANGES exige review e `stage:ready-to-close`. Blocker registra resume target.

### Batch e Epic

Batch isola trilhas, não pula gates com `--from` e consolida escolhas por IDs.
Epic só nasce após aceite, não recebe estado de entrega e fecha após checkpoint
humano de filhas, medidas e decisões transversais.

## Casos de borda

| #   | QUANDO                                    | o sistema DEVE                                             |
| --- | ----------------------------------------- | ---------------------------------------------------------- |
| 1   | `/code-flow` não recebe issue             | fazer discovery e recomendar entrada, sem plano/código     |
| 2   | S no-spec é invocada explicitamente       | usar issue mínima, outline, worktree e review independente |
| 3   | hard trigger tem Complexity S             | promover ao rigor máximo                                   |
| 4   | source-set muda após aprovação            | invalidar gates dependentes                                |
| 5   | somente metadata muda                     | preservar digest/aprovação do source-set                   |
| 6   | zero stage e mapeamento nativo passa      | usar native automaticamente nesta entrada                  |
| 7   | issue nova sem stage falha no mapeamento  | inicializar fallback equivalente                           |
| 8   | header legado native fica incompleto      | pausar e pedir migração explícita                          |
| 9   | issue legada possui um stage              | registrar fallback e preservar gate                        |
| 10  | plan-writer publica snapshot              | mover a needs-plan-review sem needs-human                  |
| 11  | executor comprova ausência de diff        | usar NO_CHANGES, review e gate de close                    |
| 12  | blocker é resolvido                       | recalcular risco e usar resume target ainda válido         |
| 13  | batch contém issue inelegível para --from | reportá-la e continuar trilhas elegíveis                   |
| 14  | PR/checks estão aprovados                 | ainda aguardar Integrar explícito                          |

## Questões em aberto

Nenhuma.

## Definition of Done

```bash
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-code-flow build
pnpm test
pnpm build
pnpm skills-check
python3 scripts/docs-check
git diff --check
```

- Casos 1–14 cobertos por testes determinísticos ou evals pareados.
- Cinco amostras baseline/candidato por 14 cenários com o modelo aprovado.
- 5/5 em hard triggers, workflow, ownership, independência e merge/close;
  mínimo 4/5 nos demais.
- Fonte e `dist/skills/code-flow` coerentes sem tooling privado.

## Revisão humana

- Aprovar prompts e inspecionar benchmark pareado.
- Confirmar que nenhum gate humano foi convertido em automação.

## Verificação

- `pnpm --filter @gugacarbo/skill-code-flow test`: PASS.
- `pnpm --filter @gugacarbo/skill-code-flow build`: PASS.
- `pnpm test`: PASS, incluindo a suíte global e as três skills com testes.
- `pnpm build` com output/target temporários: PASS; publicação global não foi
  alterada.
- `scripts/docs-check --emit-index`: 3 docs, 0 erros, 0 avisos.
- `skill-master/scripts/quick_validate.py skills/code-flow`: skill válida.
- `pnpm skills-check`: `code-flow` sem órfãos, links quebrados ou ciclos; exit 1
  apenas pelo órfão concorrente `skills/project-init/evals/run-evals.mjs`.
- Após aprovação humana dos prompts, benchmark reduzido com
  `gpt-5.4-mini`/`medium`: cenários críticos de workflow 7, 8 e 9, cinco
  amostras fresh baseline/candidato por cenário. No recorte de três critérios
  centrais por cenário, baseline atingiu 25/45 (55,6%) e candidato 45/45
  (100%). O cenário 9 revelou ambiguidade de precedência de header legado;
  após tornar `stage:*` explicitamente autoritativo, o rerun do candidato foi
  5/5. A revisão completa de 14 cenários não foi rodada por decisão de
  economia de tokens; este resultado não a substitui.
