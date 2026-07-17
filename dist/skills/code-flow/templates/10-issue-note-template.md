## Nota de correção do source-set

Agent: `issue-writer`
Phase/scope: `fase 2 / correção após needs-issue-fix`
Summary: `<resumo conciso do que foi alterado no body em resposta aos achados do reviewer>`
Sources/evidence: `<URL da issue, comentário do issue-reviewer que motivou a correção, padrão do repositório e ADR/spec aceitos>`
Decisions: `<ajustes aplicados no body; nenhum ADR/spec formal materializado sem aprovação>`
Changes/validation: `<seções reescritas, diff resumido e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `<stage:spec-approval → nova review do issue-reviewer | decisão humana, owner>`

### Mudanças aplicadas

| Achado do reviewer                         | Seção do body alterada | Ação tomada                                                 |
| ------------------------------------------ | ---------------------- | ----------------------------------------------------------- |
| `<referência ao achado do issue-reviewer>` | `<seção do body>`      | `<correção aplicada, justificativa ou rejeição com motivo>` |

### Validação

- [ ] Body reescrito reflete todos os achados do `issue-reviewer`
- [ ] Source-set permanece só no body (não duplicado em comentário)
- [ ] Nenhum ADR/spec formal materializado antes da aprovação humana
- [ ] Labels mutadas via `scripts/transition-issue.sh` de volta a `stage:spec-approval`

---

_Processo: code-flow — nota append-only do `issue-writer` registrando o resumo
da correção do body após `stage:needs-issue-fix`; o source-set completo
continua vivendo só no body da issue, nunca neste comentário._
