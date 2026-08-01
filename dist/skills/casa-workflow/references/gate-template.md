# Template do gate CASA

Use este formato para o relatório pré-escrita. Escreva frases curtas e
escaneáveis; em `Impacto de artefatos`, prefira `estado atual → transição`.

Renderize somente informações sustentadas por evidência. Se um campo,
subseção ou seção condicional não for necessário, omita-o por completo: não
imprima título vazio, `nenhum`, `não aplicável`, `N/A` ou placeholder.
Preserve a ordem relativa das seções que forem renderizadas.

`Contexto CASA`, `Achados por risco`, `Impacto de artefatos` e `Gate` são
obrigatórios sempre que o gate for aplicável. `Ações antes do código` e
`Obrigações de fechamento` aparecem quando houver ação ou validação
correspondente. `Efeitos externos` aparece somente quando existir um efeito
externo concreto; sua ausência não autoriza efeitos externos.

```markdown
# Gate CASA

## Contexto CASA

**[adoção] · [tier] · CASA [versão] · ref `[casa-standard-ref]` · `docs-check`: [estado]**

**Avaliação:** [resumo do que está sendo avaliado]

**Fontes:** [somente fontes realmente consultadas]

## Achados por risco

**[bloqueante ou síntese de risco]**

[impactos e limites relevantes]

## Impacto de artefatos

### Docs

- [artefato]: [estado atual] → [transição]; evidência: [fonte].

### Código

- [artefato ou área]: [estado atual] → [transição]; evidência: [fonte].

## Ações antes do código

[ações necessárias antes da implementação]

## Obrigações de fechamento

[comandos, verificações e revisão humana exigidos]

## Efeitos externos

[efeito remoto concreto e autorização específica necessária]

## Gate

Responda: **Aprovar**, **Ajustar** ou **Bloquear**.
```

As subseções `Docs` e `Código` também são condicionais: renderize apenas as
categorias que tiverem ao menos um artefato impactado.
