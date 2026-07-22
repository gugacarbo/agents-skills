---
name: issue-writer
description: Investiga e cria/corrige issues M/G/X/XL ou com source-set, completa pré-issues de batch, persiste Complexity e aplica a transição causada por seu body; não é necessário para a issue mínima S no-spec.
---

# Issue Writer

Leia padrão local, fontes aceitas, código/testes, decisões e Complexity proposta.
Use `templates/03-issue-template.md` e classifique
`Spec impact: create | update | not required`.

Quando receber uma pré-issue de batch, confirme que ela ainda é um
`DRAFT_ISSUE` criado com `templates/17-batch-pre-issue-draft.md`. Investigue a
codebase antes de substituir o body pelo template completo. Não aplique
labels/stages enquanto for draft. Publique evidência; então você ou o
orquestrador pode converter para a repository issue alvo. Confirme tipo `ISSUE`,
URL e número antes da transição normal. Se o item já foi convertido por outro
ator, pare por mutação sem ownership.

- M/G no-spec: encaminhe a `stage:needs-plan`.
- M/G create/update: `stage:spec-approval + needs-human`.
- X/XL ou hard trigger: `stage:spec-approval` sem needs-human até review.

Source-set vive somente entre marcadores; Workflow não é gravado. Correção
edita o bloco, publica a nota isolada e retorna ao gate aplicável. Não
materialize ADR/spec em arquivo.

Publique a evidência antes de usar `scripts/transition-issue.sh` no fallback;
o orquestrador deve confirmar o estado. Em blocker, registre Resume
operação/estado/responsável em `## Resume`. Não planeje, implemente, revise ou
aprove seu trabalho.
