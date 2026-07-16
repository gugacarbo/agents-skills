## Revisão independente do plano

Agent: `plan-reviewer`
Phase/scope: `ciclo de plano <k>/3`
Summary: `<resultado da review>`
Sources/evidence: `<URL do comentário do plano, links imutáveis e base SHA>`
Decisions: `<veredito literal e decisões necessárias>`
Changes/validation: `<checagens e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `<humano aprova este snapshot exato | revisar plano | decisão humana, owner>`

### Metadados da review

| Campo                         | Valor                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------- |
| **Ciclo de plano**            | `<URL do comentário do plano>`                                                  |
| **Base SHA do plano**         | `<SHA completo>`                                                                |
| **Independência do reviewer** | `Não autorizei este plano e não tenho assignment de implementação neste ciclo.` |
| **Veredito**                  | `APROVO \| APROVO COM RESSALVAS \| PEÇO AJUSTES \| NÃO APROVO`                  |

---

## Achados

| Severidade                                        | Seção / fonte               | Impacto e ação     |
| ------------------------------------------------- | --------------------------- | ------------------ |
| `Critical \| Important \| Minor \| Cannot verify` | `<seção do plano ou fonte>` | `<impacto e ação>` |

---

## Evidência checada

- [ ] ADR/spec aceito ou racional no-spec aprovado
- [ ] Links imutáveis e base SHA conferidos
- [ ] Objetivo, limites, critérios de aceite e ordem de implementação
- [ ] Casos EARS, verificação/TDD e DoD binário

---

## Próximo passo (humano)

> Um veredito aprovador (`APROVO` ou `APROVO COM RESSALVAS`) ainda exige que o
> **humano aprova este snapshot exato** antes da implementação.

| Veredito               | Ação esperada                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------- |
| `APROVO`               | Humano aprova snapshot → `stage:approved`                                           |
| `APROVO COM RESSALVAS` | Humano aprova snapshot com ressalvas documentadas                                   |
| `PEÇO AJUSTES`         | Reviewer atribui `stage:needs-plan-fix`; plan-writer revisa e publica novo snapshot |
| `NÃO APROVO`           | Bloquear até novo plano ou decisão humana                                           |

---

_Processo: code-flow — review append-only do plano, independente da autoria e
não é review de código. Um veredito aprovador ainda exige aprovação humana do
snapshot antes da implementação._
