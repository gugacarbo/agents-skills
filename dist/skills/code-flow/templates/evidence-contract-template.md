---
Agent: <agent>
Phase/scope: <operação, ciclo ou range>
Summary: <resultado>
Sources/evidence: <links imutáveis, comandos e saída>
Decisions: <aplicadas, pendentes ou none>
Changes/validation: <mudanças e validação ou none>
Blockers: <blocker ou none>
Next action: <ação e owner>
---

# Contrato de evidência

Todo resultado de papel usa o envelope acima antes de mutação de estado,
inclusive no-op, erro, bloqueio e rejeição. Mencionar stage em comentário não
muda a issue.

O source-set do issue-writer é a exceção: fica no body segundo
`templates/03-issue-template.md`. Os demais resultados são comentários
append-only. O nome da classificação interna nunca integra evidência.
O comentário de aprovação do source-set registra somente a URL da decisão e o
SHA-256 do body aprovado; não duplica o source-set. Digest divergente invalida
o gate.

Opt-in de workflow nativo também não é evidência persistida: ele vale somente
para a execução atual e deve ser pedido novamente em toda retomada. Sem
reconfirmação, não publique evidência nem mutue a issue.

Implementação cita plano ou outline, base SHA, commits, validação e status.
Review cita o range e veredito literal. Auditoria final só existe quando o
contrato aplicável a exige.
