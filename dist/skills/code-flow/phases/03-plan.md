# Fase 3: Plano e review independente

A partir de `stage:needs-plan`, despache `agents/03-plan-writer.md`. Ele cria
um ciclo de plano append-only com links imutáveis das fontes, base SHA, impacto
de spec, objetivo e limites, critérios de aceite, abordagem de verificação/TDD,
casos EARS, riscos, rollback e DoD binário. Não peça decomposição em task IDs —
o plano é uma unidade de implementação. O envelope completo de oito campos
acompanha o comentário do plano.

Publique `templates/05-plan-template.md` e então mutue labels para
`stage:needs-plan-review` (remova `stage:*` anterior primeiro), sem adicionar
`needs-human`. Não trate o comentário do plano como mudança de stage. Preferir
`scripts/transition-issue.sh`.

Despache imediatamente um `agents/04-plan-reviewer.md` fresco com o snapshot
literal. Ele publica `templates/06-review-template.md` com todos os oito campos
e um veredito literal:

| Resultado                                                         | Ação                                                                                                                                                                   |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `APROVO` / `APROVO COM RESSALVAS`                                 | O `plan-reviewer` adiciona `needs-human`; manter `stage:needs-plan-review` e apresentar o snapshot revisado para aprovação humana.                                     |
| `PEÇO AJUSTES`                                                    | O `plan-reviewer` atribui `stage:needs-plan-fix`; o `plan-writer` publica o próximo ciclo e retorna a `stage:needs-plan-review`. No ciclo 3, bloquear + `needs-human`. |
| `NÃO APROVO`, erro, veredito ausente ou decisão de produto/acesso | O `plan-reviewer` adiciona `needs-human`; mutar labels para `stage:blocked`.                                                                                           |

Após um veredito independente aprovador, o humano aprova ou rejeita o snapshot
exato do comentário do plano com `templates/13-human-gate-plan.md`. Só a
aprovação humana muta a issue para `stage:approved`; rejeição ou pedido de
mudança a devolve a `stage:needs-plan-fix` (ou bloqueia no ciclo 3). A aprovação do
source-set e a aprovação do plano são gates obrigatórios separados. Preferir
`scripts/transition-issue.sh` para mutar labels.
