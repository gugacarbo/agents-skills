# Persistência de contexto

Use esta referência para conhecimento durável inferido durante uma tarefa. Uma
sugestão sem escrita não aciona gate; mutação direta do destino CASA aciona.

## Reconhecer durabilidade

Trate como candidato quando houver linguagem como “padronize”, “sempre”,
“nunca”, “a partir de agora”, “comando oficial/canônico”, ou quando uma
descoberta confirmada definir estado operacional ou gotcha com chance real de
recorrência.

Não persista preferência pontual, workaround temporário, hipótese, decisão
pendente, detalhe evidente no código ou fato que duplicaria ADR/Spec.

## Escolher uma única fonte

Leia primeiro o mapa de contexto e prefira um capítulo existente.

| Informação                                   | Destino T1                    |
| -------------------------------------------- | ----------------------------- |
| Convenção de código, nomes, UX ou estrutura  | `docs/context/CONVENTIONS.md` |
| Comandos e estratégia de testes              | `docs/context/TESTS.md`       |
| Infra, ambientes, serviços e deploy          | `docs/context/INFRA.md`       |
| Segredos, acesso e segurança operacional     | `docs/context/SECURITY.md`    |
| Regra curta transversal ou gotcha recorrente | `AGENTS.md` raiz              |
| Regra restrita a um package/subtree          | `<subdir>/AGENTS.md`          |

Em T0, use somente `AGENTS.md` raiz ou aninhado; não sugira `docs/context/`.
Se o destino T1 não existir, sugira criar o capítulo e seu ponteiro no mapa.
Não duplique o mesmo fato em mais de um arquivo.

## Contrato de interação

Se o usuário pediu explicitamente para criar, editar ou depreciar o documento,
classifique a mutação no source-set e emita o gate CASA antes da primeira
escrita. Se a intenção foi apenas inferida:

1. conclua implementação e validação sem gate adicional;
2. não altere o documento;
3. no fechamento, apresente no máximo três itens agrupados por destino:
   `Sugestão de contexto: <path> — <fato>; motivo: <por que é durável>.`

A sugestão é opcional para o usuário e não bloqueia nem reabre a tarefa.
