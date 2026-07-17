# code-flow

Coordena entregas por issue com classificação de risco efêmera, workflow do
repositório por opt-in, fallback `stage:*`, reviews independentes e merge
explícito.

Comandos e regras canônicas: [SKILL.md](SKILL.md). Classificação:
[references/risk-profiles.md](references/risk-profiles.md). Estado e retomada:
[references/github-flow.md](references/github-flow.md).

## Caminhos de entrega

| Risco calculado | Caminho mínimo |
| --- | --- |
| Interno, localizado e reversível | issue no-spec → autorização de execução → outline + execução → review independente → merge explícito |
| Observável ou transversal moderado | source gate se necessário → plano/review/aprovação → execução → delivery review → auditoria condicional → merge explícito |
| Sensível ou de alto impacto | source review/aprovação → plano/review/aprovação → execução → delivery review → auditoria fresca → merge explícito |

Os nomes internos da classificação nunca são persistidos. A operação os
recalcula antes de interpretar o estado atual.

## Workflow do repositório

- Qualquer `stage:*` existente fixa o fallback.
- Workflow nativo só pode ser usado após discovery, validação e opt-in humano.
- O opt-in não é persistido; toda retomada nativa exige nova confirmação.
- Sem reconfirmação, a skill encerra sua atuação sem mutar ou fechar a issue.
- Nunca misture workflow nativo e fallback na mesma execução.

## code-flow vs super-planning

- **code-flow:** entrega governada por issue, risco adaptativo, gates e PR.
- **super-planning:** decomposição local em tarefas e registry de execução.

Entregas históricas podem citar `code-toolbox`; não reescreva essa evidência.
