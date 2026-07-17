# Integração e fechamento

Em `stage:ready-to-merge`, execute a auditoria aplicável, verifique DoD,
evidência, commits e aprovação do PR. Publique
`templates/09-integration-report-template.md` quando houver auditoria final; na
ausência dela, a review aprovada fornece a evidência de fechamento.

Achado corrigível volta a `stage:needs-changes`; decisão externa vai a
`stage:blocked + needs-human`.

Merge nunca é automático. Apresente `templates/14-human-gate-merge.md` e só
integre após `Yes` explícito. Depois do merge, verifique o alvo, feche a issue e
limpe `stage:*`/`needs-human` com `transition-issue.sh` no fallback ou com a
transição equivalente do workflow nativo confirmado.
