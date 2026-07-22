# Epic: `<nome da epic>`

**status:** `<rascunho | em andamento | em revisão | blocked | concluída>`

<!-- (opcional, somente se houver blockers) -->
## Blockers

## Contexto

<resumo da epic em texto humano, descrição|problema e resultado final esperado e motivo para coordená-la, considerando os resultados de entrega incluídos>

## Objetivo

<objetivo da epic em texto humano, descrição|problema e resultado final esperado e motivo para coordená-la, considerando os resultados de entrega incluídos>

## Decisões e Evidências

- **Problema:** `<descrição do problema ou risco transversal>`
  - **Responsável:** `<owner> : <data e hora>`
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

## User Stories e Issues

- [ ] `<status>` `<link ou nome previsto da issue | user story>`
  - [ ] `<status>` `<link ou nome previsto da issue | sub-issue>`

<!-- ! Cada filha usa `templates/03-issue-template.md` e percorre o fluxo completo. -->
<!-- ! Este Epic não recebe `Complexity`, `Workflow`, `stage:*` nem `needs-human`. -->

## Checklist de Conclusão

- [ ] Filhas in-scope fechadas ou removidas por decisão registrada.
- [ ] Medidas de sucesso avaliadas.
- [ ] Decisões transversais abertas resolvidas ou aceitas.
- [ ] Checks e CI/CD de entrega concluídos.
- [ ] Aprovação humana do gate de fechamento da Epic.

<!-- ! Apresente o gate humano compartilhado com `Fechar Epic / Replanejar / Aguardar`. -->
<!-- ! As regras de fechamento vivem nas instruções de Epic; nunca feche automaticamente. -->
