# code-flow

Coordena entregas por issue com discovery pré-issue limitado, complexidade
persistida, risco efêmero, workflow retomável, reviews independentes e
integração ou fechamento explícitos.

Comandos e regras canônicas: [SKILL.md](SKILL.md). Classificação:
[references/risk-profiles.md](references/risk-profiles.md). Estado e retomada:
[references/github-flow.md](references/github-flow.md).

## Caminhos de entrega

| Complexidade/risco   | Caminho mínimo                                                                                                                |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| S sem hard trigger   | issue mínima no-spec → autorização → outline + execução → review independente → integração/fechamento explícito               |
| M/G sem hard trigger | source gate se aplicável → plano/review/aprovação → execução → delivery review → auditoria condicional → integração explícita |
| X/XL ou hard trigger | source review/aprovação → plano/review/aprovação → execução → delivery review → auditoria fresca → integração explícita       |

`Complexity` representa esforço/coordenação; o rigor é recalculado e hard
trigger sempre prevalece. Os nomes internos da classificação não são
persistidos.

## Workflow do repositório

- `Workflow: native|fallback` vive no header da issue e precisa concordar com o
  estado observado.
- A primeira seleção nativa exige mapeamento completo e opt-in humano; depois é
  reutilizada enquanto escopo e mapeamento continuarem válidos.
- Contradição é drift; native inválido exige migração explícita para fallback.
- Issues legadas com `stage:*` migram preguiçosamente para fallback.

## code-flow vs super-planning

- **code-flow:** entrega governada por issue, risco adaptativo, gates e PR.
- **super-planning:** decomposição local em tarefas e registry de execução.

Entregas históricas podem citar `code-toolbox`; não reescreva essa evidência.
