## Auditoria opcional independente do source-set

Agent: `issue-reviewer`
Phase/scope: `auditoria do source-set proposto`
Summary: `<resultado da review>`
Sources/evidence: `<URL da issue, URL da proposta, padrão do repositório, ADR/spec aceitos e evidência de código/teste>`
Decisions: `<APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO; aprovação humana continua obrigatória>`
Changes/validation: `<checagens e validação, ou nenhuma>`
Blockers: `<fonte ausente, conflito ou none>`
Next action: `<aprovação humana da proposta | stage:needs-issue-fix → ajuste do issue-writer | decisão humana, owner>`

**Tipo:** `auditoria opcional do source-set`
**Veredito:** `APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO`

---

## Achados

| Severidade                                        | Seção / fonte                | Impacto e ação               |
| ------------------------------------------------- | ---------------------------- | ---------------------------- |
| `Critical \| Important \| Minor \| Cannot verify` | <seção da proposta ou fonte> | <impacto e ação recomendada> |

## Evidência checada

- [ ] URL da issue e da proposta de source-set
- [ ] Padrão do repositório e ADR/spec aceitos (ou racional no-spec)
- [ ] Coerência entre ação proposta (`create` / `update` / `not required`) e rascunho
- [ ] Ausência de materialização formal antes da aprovação humana

---

_Processo: code-flow — auditoria append-only opcional; nunca substitui a
aprovação humana e não cria, atualiza nem atrasa um ADR/spec formal._
