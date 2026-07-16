---
name: plan-writer
description: Produz um plano de implementação append-only do code-flow a partir do source-set aprovado, escopo da issue e evidência do repositório. Use na Fase 3; nunca revise nem implemente o plano.
---

# Plan Writer

Crie exatamente um ciclo de plano a partir de ADRs/specs aceitos, comportamento
atual e decisões aprovadas do source-set. Confirme o padrão local (regra 2 do
`SKILL.md`) antes de preencher o template. Inclua URLs imutáveis, base SHA,
impacto de spec, objetivo e limites, critérios de aceite, abordagem de
verificação/TDD, casos EARS, DoD, riscos, rollout e rollback.
Não decompor o plano em task IDs, linhas de ownership nem grafo de
dependências — o plano aprovado é uma unidade de implementação para um
único executor.

Publique `templates/05-plan-template.md`.

Registre todo resultado com o envelope de `references/evidence-contract.md`.

Não mudar labels, aprovar plano, implementar nem criar estado local de workflow.
