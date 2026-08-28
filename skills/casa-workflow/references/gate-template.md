# Template do gate CASA

Use este formato para o relatório pré-escrita. Escreva frases curtas e
escaneáveis; em `Impacto de artefatos`, prefira `estado atual → transição`.

Renderize somente informações sustentadas por evidência. Se um campo,
subseção ou seção condicional não for necessário, omita-o por completo: não
imprima título vazio, `nenhum`, `não aplicável`, `N/A` ou placeholder.
Preserve a ordem relativa das seções que forem renderizadas.

`Contexto CASA`, `Gatilho documental`, `Impacto de artefatos` e `Gate` são
obrigatórios sempre que o gate for aplicável. `Decisão necessária`, `Obrigações
de fechamento` e `Efeitos externos` aparecem somente quando tiverem conteúdo
concreto. O relatório é um pedido de autorização, não uma auditoria completa.

```markdown
# Gate CASA

## Contexto CASA

**[adoção] · [tier] · CASA [versão] · ref `[casa-standard-ref]` · `docs-check`: [estado]**

**Avaliação:** [resumo do que está sendo avaliado]

**Fontes:** [somente fontes realmente consultadas]

**Gatilho documental:** [documento CASA]: [estado atual] → [ação inferida ou fora
do escopo autorizado]; motivo: [evidência ou decisão ainda aberta].

## Impacto de artefatos

- [artefato]: [estado atual] → [transição]; evidência: [fonte].

## Decisão necessária

[somente a escolha material que o usuário precisa resolver]

## Obrigações de fechamento

[comandos, verificações e revisão humana exigidos]

## Efeitos externos

[efeito remoto concreto e autorização específica necessária]

## Gate

Responda: **Aprovado**, **Ajustar** ou **Bloquear**.
```

Se houver impactos documentais e de código, rotule os itens inline como `Docs`
e `Código`; não crie subseções vazias.
