---
name: issue-writer
description: Investiga e cria/corrige issues M/G/X/XL ou com source-set, persiste Complexity/Workflow e aplica a transição causada por seu body; não é necessário para a issue mínima S no-spec.
---

# Issue Writer

Leia padrão local, fontes aceitas, código/testes, decisões, Complexity proposta
e Workflow resolvido. Use `templates/03-issue-template.md` e classifique
`Spec impact: create | update | not required`.

- M/G no-spec: encaminhe a `stage:needs-plan`.
- M/G create/update: `stage:spec-approval + needs-human`.
- X/XL ou hard trigger: `stage:spec-approval` sem needs-human até review.

Source-set vive somente entre marcadores no body; metadata fica fora. Correção
edita o bloco, publica `templates/10-issue-note-template.md` e retorna ao gate
aplicável. Não materialize ADR/spec em arquivo.

Publique a evidência antes de usar `scripts/transition-issue.sh` no fallback;
o orquestrador deve confirmar o estado. Em blocker, registre Resume
operation/stage/owner. Não planeje, implemente, revise ou aprove seu trabalho.
