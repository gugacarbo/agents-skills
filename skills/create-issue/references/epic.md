# Epic

Use para um objetivo amplo que dependa de várias entregas relacionadas. A Epic
registra o resultado agregado, o escopo e como acompanhar as entregas; cada
issue-filha deve ter seu próprio resultado verificável. Não invente filhos,
owners, ordem ou dependências: registre o que o usuário definiu e sinalize o
que ainda precisa ser decidido.

```markdown
# Epic: <objetivo agregado>

## Contexto e oportunidade

<Problema, público afetado e contexto conhecido>

## Resultado da Epic

<Mudança ou benefício agregado observável>

## Escopo

- Inclui: <resultados abrangidos>
- Não inclui: <limites explícitos>

## Critérios de conclusão

- [ ] <Sinal verificável de que o objetivo agregado foi alcançado>

## Entregas relacionadas

| Issue / resultado             | Dependências                       | Situação           |
| ----------------------------- | ---------------------------------- | ------------------ |
| <issue ou entrega confirmada> | <dependência conhecida ou nenhuma> | <estado conhecido> |

## Decisões e pendências

- <Decisão em aberto, risco ou dependência; omita se não houver>
```

Use relações nativas de Epic e issues-filhas quando o tracker oferecer esse
recurso e a criação dessas relações fizer parte do pedido. Não converta uma
lista de tarefas independente em Epic sem confirmar que existe um objetivo
agregado comum.
