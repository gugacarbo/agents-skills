# code-flow

Coordena entregas por issue com discovery pré-issue limitado, complexidade
persistida, risco efêmero, workflow derivado do estado, reviews independentes e
integração ou fechamento explícitos.

Na criação em batch para investigação posterior, cada pré-issue nasce como
Draft Issue de Project V2. O issue-writer revisa a codebase e completa o body
antes de o próprio issue-writer ou o orquestrador convertê-la em repository
issue.

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

- Um `stage:*` define fallback; sem stage, native é usado automaticamente só
  quando o mapeamento completo passa.
- `Workflow` não é persistido. Header legado é compatibilidade, não estado.
- Native legado inválido pausa e exige decisão humana para migrar ao fallback.

## Histórico do plano

O plano formal ocupa um único comentário canônico. Quando precisa mudar, o
plan-writer edita esse comentário e adiciona apenas um comentário append-only
com o resumo breve da revisão; não republica o plano completo.

## Ressalvas não bloqueantes

Todo `Minor` não bloqueante recebe um link de issue draft, sem criação
automática. Ao final, o delivery reviewer consolida sugestões de todas as
etapas, remove duplicatas, agrupa apenas itens compatíveis e publica o relatório
append-only antes do gate final.

## code-flow vs super-planning

- **code-flow:** entrega governada por issue, risco adaptativo, gates e PR.
- **super-planning:** decomposição local em tarefas e registry de execução.

Entregas históricas podem citar `code-toolbox`; não reescreva essa evidência.
