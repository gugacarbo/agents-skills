# #NNNN - <Issue Name / User Story / Bug / Feature / Docs>

**status:** `<rascunho | em andamento | em revisão | blocked | concluída>`
**complexity**: <S | M | G | X | XL>
**Epic:** `<#<n> | link para epic>`
**Parent:** `<sub issue of #<n> | link para parent>`
<!-- não inserir as relações se não houver -->

<!-- (opcional, somente se houver blockers) -->
## Blockers (opcional)

<!-- code-flow:source-set:start -->

## User Story / Objetivo / Contexto

Como `<usuário ou papel>`, quero `<capacidade>` para `<valor observável>`.
Para mudança técnica, descreva o contexto e o valor sem forçar user story.
resultado observável e critérios de sucesso claros para serem avaliados por gate humano

## Decisões e Evidências

- **Problema:** `<descrição do problema ou risco transversal>`
  - **Decisão:** `<decisão tomada>`
  - **Desbloqueio ou ponto de review:** `<condição ou link>`
  - **Opções avaliadas:**
    - `<alternativas consideradas>`

- **Evidências:**
  - `<links, issues, documentos, decisões, etc.>`

## Definição de pronto (DoD)

| Resultado observável | Medida, alvo e método |
| -------------------- | --------------------- |
| `<resultado>`        | `<métrica>`           |

### Fora de escopo

<exclusões explícitas, restrições de tempo, compatibilidade, acesso, segurança ou decisão produto>

## Especificações e Documentos

- **Ação:** `<create | update | not required>`
- **Fonte aceita:** `<URL/path ou not applicable>`

<!-- Caso não houver necessidade de alterações nas especificações documentadas do projeto apenas listar as referências, caso existirem, ou informar `sem alterações necessárias em especificações documentadas`. -->

<resumo da necessidade de mudança, e o impacto esperado na entrega>

<!-- Utilizar caso precise **criar** uma  nova especificação -->
### Proposta de nova <especificação|spec|adr|doc> <nome-da-nova-especificação>

<proposta completa ou not applicable; usar template padrão do repositório, se existir>

<!-- Utilizar caso precise **atualizar** uma especificação existente -->
### Alteração da <especificação|spec|adr|doc> <nome-da-especificação>

**Alteração 1**

<Descrever a alteração, o motivo e o impacto esperado na entrega>

```diff
- <antes>
+ <depois>
```
```diff
- <antes>
+ <depois>
```
<!-- code-flow:source-set:end -->

## Sub Issues (opcional)

- [ ] `<status>` `<link ou nome previsto da issue | user story>` `<time/pessoa (owner)>`
  - [ ] `<status> `<link ou nome previsto da sub-issue>` `<time/pessoa (owner)>`

<!-- Usar itens abaixo conforme necessidade, não são obrigatórios -->
## Checklist de Conclusão

- [ ] Aprovação humana da alteração em specs (opcional, somente se houver alteração de specs)
- [ ] Filhas in-scope fechadas ou removidas por decisão registrada.
- [ ] Medidas de sucesso avaliadas.
- [ ] Decisões transversais abertas resolvidas ou aceitas.
- [ ] Checks e CI/CD de entrega concluídos.
- [ ] Aprovação humana do gate de fechamento da Epic.

<!-- opcional, somente se houver ressalvas para correção futura -->
## Ressalvas

| Severidade                            | Fonte/seção    | Impacto     | Ação     | Issue draft                                 |
| ------------------------------------- | -------------- | ----------- | -------- | ------------------------------------------- |
| `Important \| Minor \| Cannot verify` | `<referência>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

<!--
 _Ressalvas aprovadoras são somente Minor não bloqueantes. O veredito não
substitui o gate humano. Para cada Minor, use
[`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md)._
-->

