# Gate humano: merge / integração (Fase 6)

**Em jogo:** PR aprovado, auditoria final e DoD ok; issue em
`stage:ready-to-merge` (+ `needs-human` após aprovação do PR).

**Você decide:** se e quando integrar/mergear. Merge nunca é automático.

Responda com uma opção literal:

- **Yes** — merge/integração confirmados; fechar issue e limpar `stage:*` +
  `needs-human` (`transition-issue.sh --clear-stage --clear-needs-human`).
- **No** — não mergear agora; manter `ready-to-merge` (+ `needs-human`).
- **Refine** — pedir ajuste (volta a `needs-changes` / executor se for código).

Sem Yes explícito, não mergear.
