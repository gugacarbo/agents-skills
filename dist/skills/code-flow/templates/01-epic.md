<!-- Artefato só de tracking. Não adicionar labels stage:* ou needs-human a este Epic. -->

# Epic: <título da iniciativa>

| Campo | Valor |
| --- | --- |
| **Tipo** | Epic (tracking) |
| **Owner** | <time ou pessoa> |
| **Status** | <rascunho \| em andamento \| concluído> |

> **Restrição de labels:** Não adicionar labels `stage:*` ou `needs-human` a este Epic.
> Aplicar o fluxo code-flow apenas nas issues filhas de entrega.

---

## Por que agora

| Aspecto | Descrição |
| --- | --- |
| **Problema / oportunidade** | <o que motiva a iniciativa> |
| **Impacto** | <usuário, negócio ou operação afetados> |
| **Urgência** | <por que agora e não depois> |

## Resultado e medidas de sucesso

| Campo | Conteúdo |
| --- | --- |
| **Resultado** | <resultado observável quando a iniciativa terminar> |
| **Medidas de sucesso** | <métrica, alvo e método de medição> |

## Escopo

| Limite | Conteúdo |
| --- | --- |
| **Dentro** | <capacidades ou resultados de entrega incluídos> |
| **Fora** | <exclusões explícitas> |
| **Restrições** | <tempo, compatibilidade, acesso, segurança ou produto> |

## Issues de entrega filhas

| Filha | Resultado da entrega | Owner | Depende de | Status |
| --- | --- | --- | --- | --- |
| #<n> | <um resultado de user-story independentemente fechável> | <time/pessoa> | <#n ou none> | <link/status> |

**Regras das filhas**

- Cada filha deve ser uma issue de entrega/bug, usando `templates/02-user-story.md`.
- O GitHub pode ligá-la como subissue deste Epic.
- Aplicar labels `stage:*` e o fluxo code-flow de fonte, plano, execução e review **apenas nas filhas**.
- Manter a implementação dentro do plano aprovado de cada filha — sem decompor em task IDs nem criar subissues de chore.

## Decisões e riscos transversais

| Item | Decisão ou risco | Owner | Resolução / ponto de review |
| --- | --- | --- | --- |
| <id> | <decisão, dependência ou risco> | <time/pessoa> | <link, data ou condição> |

## Conclusão

O Epic está completo quando:

- [ ] Toda filha in-scope estiver fechada ou removida por decisão de produto registrada
- [ ] As medidas de sucesso forem avaliadas
- [ ] Qualquer decisão transversal tiver registro durável
