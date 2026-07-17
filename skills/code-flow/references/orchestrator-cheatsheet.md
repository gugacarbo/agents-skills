# Cheatsheet do orquestrador

## Ordem de resume

1. validar elegibilidade da issue;
2. descobrir fontes e workflow sem mutar;
3. recalcular risco;
4. resolver nativo ou fallback;
5. interpretar o próximo gate;
6. despachar papel independente aplicável;
7. registrar evidência e só então mutar.

## Matriz stage → operação → ação

| Stage fallback                | Operação  | Ação                                        |
| ----------------------------- | --------- | ------------------------------------------- |
| `stage:spec-approval`         | issue     | review/gate de fonte conforme risco         |
| `stage:needs-issue-fix`       | issue     | corrigir body e revisar quando exigido      |
| `stage:needs-plan`            | plan      | plano formal                                |
| `stage:needs-plan-review`     | plan      | review independente + gate humano           |
| `stage:needs-plan-fix`        | plan      | novo ciclo de plano                         |
| `stage:approved`              | dispatch  | recalcular risco; ordem explícita; worktree |
| `stage:in-progress`           | dispatch  | executar ou resolver blocker                |
| `stage:needs-delivery-review` | review    | review independente                         |
| `stage:needs-changes`         | dispatch  | corrigir achados                            |
| `stage:ready-to-merge`        | integrate | auditoria aplicável + decisão de merge      |
| `stage:blocked`               | context   | apresentar blocker; não adivinhar           |

`needs-human` aparece somente quando o próximo ator é humano: source-set após
review aplicável, plano após plan-review, execução em `stage:approved`, merge
após auditoria aplicável e blocker. Remova-o ao devolver trabalho a um agente.

## Independência

- `issue-reviewer` é obrigatório somente quando hard trigger exige source
  review.
- `plan-writer` nunca revisa o próprio plano.
- `executor` nunca revisa a própria implementação.
- auditoria final obrigatória usa instância distinta da delivery review.
- no caminho moderado, um reviewer pode acumular as duas reviews somente se
  não produziu plano nem código.

## Opt-in nativo

O aceite vale apenas para a execução atual. Em retomada, pergunte de novo. Sem
reconfirmação, encerre a atuação sem mutar a issue; não aplique
`stage:blocked`, não publique nota e não converta para fallback.
