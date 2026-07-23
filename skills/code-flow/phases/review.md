# Delivery review independente

O `reviewer` consome `stage:needs-delivery-review`. Publique início com `run_id`
e adicione `stage:in-progress`, preservando o estado principal. Recuse quando
seu `run_id` ou autoria mostrar que produziu issue, arquitetura, código ou
evidência revisada.

Revise a PR publicada — nunca apenas branch local — ou a prova NO_CHANGES,
guidance, relatório/outline, spec materializada, evidência, testes, DoD e casos
de borda. Publique `templates/05-delivery-review-template.md` com achados e
consolidação de Minors. Ausência de fonte exigida é Cannot verify.

Existe exatamente uma delivery review para qualquer complexidade; não há
auditoria adicional. NO_CHANGES mantém esse nome e nunca vira DONE.

Depois da evidência, remova `stage:needs-delivery-review + stage:in-progress`:

- diff aprovado → `stage:ready-to-merge + needs-human`;
- NO_CHANGES aprovado → `stage:integration-authorized` sem gate de fechamento;
- AJUSTAR, Critical, Important ou Cannot verify → `stage:needs-changes`;
- dependência externa → `stage:blocked + needs-human` com `Resume`.

Ressalva aprovadora é somente Minor não bloqueante. Reviewer não corrige, faz
merge ou fecha issue.
