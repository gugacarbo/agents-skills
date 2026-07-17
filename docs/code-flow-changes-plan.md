# Plano final: governança adaptativa da `code-flow`

Este plano é não normativo. O contrato vigente após a implementação é a
SPEC-0001 em `docs/specs/0001-code-flow-adaptive-governance.md`.

## Decisões

- Classificação efêmera em três níveis, recalculada antes de todo resume.
- Seis papéis publicados, com invocações e gates selecionados pelo risco.
- Issue obrigatória; modo `direct`, bootstrap e `.code-flow` removidos.
- Workflow nativo somente após opt-in explícito; a escolha não é persistida.
- Retomada nativa sempre reconfirma; sem confirmação a skill encerra sua
  atuação sem mutar ou fechar a issue.
- No caminho interno, `stage:approved + needs-human` aguarda somente a ordem de
  execução; a worktree é criada automaticamente.
- Merge é sempre explícito.

## Implementação

1. Substituir a SPEC-0001 e alinhar router, fases semânticas, referências,
   agentes e templates.
2. Limitar `transition-issue.sh` ao fallback, criar labels allow-listed sob
   demanda e tornar `doctor.sh` independente de instalação local.
3. Reescrever testes estruturais e evals para classificação, promoção,
   independência, opt-in nativo e consentimento do brainstorm.
4. Comparar o snapshot antigo com a versão nova em amostras fresh, revisar os
   resultados e somente então publicar `dist/`.
5. Finalizar a SPEC como `implemented` após DoD verde.

## Verificação

```bash
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-code-flow build
pnpm test
pnpm build
pnpm skills-check
python3 scripts/docs-check
git diff --check
```
