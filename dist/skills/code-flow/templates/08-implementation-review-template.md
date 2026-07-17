## Revisão independente da implementação

Agent: `delivery-reviewer`
Phase/scope: `<plano ou outline / range implementado>`
Summary: `<resultado da review>`
Sources/evidence: `<URL da evidência do executor, range/PR e links das fontes>`
Decisions: `<veredito literal e decisões necessárias>`
Changes/validation: `<checagens e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `<aceitar | correção do executor | decisão humana, owner>`

### Resumo rápido

| Campo              | Valor                                                           |
| ------------------ | --------------------------------------------------------------- |
| Plano ou outline   | `<URL>`                                                         |
| Evidência revisada | `<URL do comentário>`                                           |
| Range / PR         | `<base..head ou URL>`                                           |
| Independência      | `Não produzi o artefato revisado nem implementei este range.`   |
| Veredito           | `APROVO \| APROVO COM RESSALVAS \| PEÇO AJUSTES \| NÃO APROVO`  |

### Achados

| Severidade                                        | Local         | Impacto e ação     |
| ------------------------------------------------- | ------------- | ------------------ |
| `Critical \| Important \| Minor \| Cannot verify` | `<file:line>` | `<impacto e ação>` |

### Evidência checada

- [ ] Conformidade com contrato/fontes: …
- [ ] Testes e DoD: …
- [ ] Escopo e ownership: …

---

_Processo: code-flow — review append-only da implementação (envelope de oito
campos). Para review de plano use `templates/06-review-template.md`._
