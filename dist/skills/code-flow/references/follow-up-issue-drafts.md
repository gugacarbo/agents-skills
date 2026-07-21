# Drafts de issue para achados não bloqueantes

Use este contrato quando um papel registrar um `Minor` não bloqueante. O link
somente abre o formulário de nova issue; nunca cria issue, label, comentário ou
transição de workflow.

## Draft individual

Para cada linha `Minor` não bloqueante, derive `<owner>/<repo>` da URL canônica
da issue de entrega e publique uma coluna `Issue draft` com um link para:

```text
https://github.com/<owner>/<repo>/issues/new?title=<title-percent-encoded>&body=<body-percent-encoded>
```

Monte e codifique cada valor em UTF-8 uma única vez:

```markdown
title: [Minor] <resumo curto do problema>

body:

## Resumo

<resumo curto do problema>

Origem: <URL da issue> · etapa: <issue review | plan review | executor | delivery review> · evidência: <URL, file:line ou comando>
```

Use `n/a — repositório GitHub não verificável` quando a URL canônica não puder
ser resolvida; nunca invente `owner/repo`. O achado permanece não bloqueante e
o papel continua a transição normal.

## Consolidação final

No fim da delivery review, use
[`templates/11-follow-up-issues-report.md`](../templates/11-follow-up-issues-report.md).
Colete os Minors não bloqueantes de issue review, plan review, executor e do
próprio delivery review.

- Duplicata semântica: mesmo problema, efeito e escopo; mantenha um item e
  todas as origens.
- Grupo compatível: problemas distintos com objetivo, escopo e caminho de
  implementação compatíveis; produza um único draft consolidado.
- Não agrupe itens que cruzem hard trigger, risco material, dependência externa
  ou priorização independente.

Um draft de grupo usa o mesmo endpoint, título `[Minor] <resumo do grupo>` e
corpo:

```markdown
## Resumo

<resultado fechado do grupo>

Origens:

- <etapa>: <URL da evidência> — <resumo original>
```

Os links individuais permanecem no histórico. O comentário consolidado é
obrigatório mesmo sem itens e não altera veredito, labels, gates, merge ou
fechamento. Ausência de um artefato exigido para a coleta é `Cannot verify` e
segue o fluxo bloqueante da delivery review.
