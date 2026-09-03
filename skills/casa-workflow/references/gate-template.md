# Template do gate CASA

Use este formato para o relatório pré-escrita. Ele é um pedido de autorização,
não uma auditoria: mostre primeiro, e com destaque, **quais documentos serão
criados, alterados ou removidos**.

Renderize somente informações sustentadas por evidência. Omita por completo
qualquer seção, grupo ou campo sem conteúdo; não use título vazio, `nenhum`,
`não aplicável`, `N/A` ou placeholder. Mantenha as seções na ordem abaixo.

`Aprovação necessária`, `Documentos no envelope` e `Gate` são obrigatórios. Os
grupos `Criar`, `Alterar` e `Remover` são condicionais: renderize só os que
tiverem documentos. `Escopo incluído`, `Decisão necessária`, `Fechamento` e
`Efeitos externos` são opcionais.

```markdown
# Gate CASA

**Aprovação necessária:** [mutação documental inferida, fora do escopo autorizado
ou decisão aberta que exige o gate].

**CASA:** [adoção, se relevante] · [tier] · versão [casa-version] · ref
`[casa-standard-ref]` · `docs-check`: [estado, se consultado]

## Documentos no envelope

### Criar

- `caminho/do/documento.md` — [finalidade]. **Status inicial:** `[status]`.

### Alterar

- `caminho/do/documento.md` — [alteração objetiva]. **Status:** `[atual]` →
  `[novo]`. <!-- Inclua Status somente quando ele mudar. -->

### Remover

- `caminho/do/documento.md` — [motivo e destino, se houver].

## Escopo incluído

- **Código:** [mudanças locais cobertas pelo envelope].
- **Verificação:** [comandos ou evidência esperada].

## Decisão necessária

[a única escolha material ainda aberta]

## Fechamento

[obrigação concreta para concluir a unidade]

## Efeitos externos

[efeito remoto concreto e autorização específica necessária]

## Gate

Responda: **Aprovar**, **Ajustar** ou **Bloquear**.
```

Liste cada documento uma única vez, no grupo que descreve sua ação principal.
Quando uma alteração também mudar seu status, mantenha-o em `Alterar` e use a
linha **Status:**; não duplique o documento. Use caminhos completos entre
crases e descreva somente a mudança aprovada, não o histórico nem alternativas
já descartadas.
