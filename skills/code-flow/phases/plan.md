# Plano e review

S sem hard trigger usa outline após ordem explícita. M/G/X/XL usam
plan-writer, review independente e gate humano. Plano formal usa
`templates/05-plan-template.md`; review usa `templates/06-review-template.md`.

Plan-writer publica snapshot e move a needs-plan-review sem needs-human.
Plan-reviewer aprovador mantém o stage e adiciona needs-human; ajuste/Critical,
Important ou Cannot verify volta a needs-plan-fix. Terceiro ciclo rejeitado
abre checkpoint humano, também pelo gate compartilhado.

## Gate humano de plano

Apresente o template compartilhado com `Aprovar / Ajustar / Bloquear`:
aprovar move a approved+needs-human, mas nunca autoriza execução; ajustar abre
novo ciclo; bloquear preserva Resume. O gate não se aplica ao outline S.
