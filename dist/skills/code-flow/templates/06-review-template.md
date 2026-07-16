## Revisão independente do plano

Agent: `plan-reviewer`
Phase/scope: `ciclo de plano <k>/3`
Summary: `<resultado da review>`
Sources/evidence: `<URL do comentário do plano, links imutáveis e base SHA>`
Decisions: `<veredito literal e decisões necessárias>`
Changes/validation: `<checagens e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `<humano aprova este snapshot exato | revisar plano | decisão humana, owner>`

**Ciclo de plano:** `<URL do comentário do plano>`
**Base SHA do plano:** `<SHA completo>`
**Independência do reviewer:** `Não autorizei este plano e não tenho assignment de implementação neste ciclo.`
**Veredito:** `APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO`

## Achados

- `Critical | Important | Minor | Cannot verify` — `<seção do plano ou fonte>` — `<impacto e ação>`

## Evidência checada

- ADR/spec aceito ou racional no-spec aprovado: …
- Links imutáveis e base SHA: …
- Objetivo, limites, critérios de aceite e ordem de implementação: …
- Casos EARS, verificação/TDD e DoD binário: …

---

*Processo: code-flow — review append-only do plano, independente da autoria e
não é review de código. Um veredito aprovador ainda exige aprovação humana do
snapshot antes da implementação.*
