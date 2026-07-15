# Intake — criar issue

Quando o usuário pedir para **criar uma issue** (ou “abre ticket”, “formaliza”,
“virar Entrega”, “abre filha”), o orquestrador **não** cria no GitHub no primeiro
turno. Filha de guarda-chuva segue o **mesmo** intake (lote mais curto só se o
pedido já trouxe o mínimo).

## Vocabulário

- **draft-approved** = usuário disse **Sim** ao rascunho (ainda não é
  `stage:approved` / plan-approved).
- Não diga “issue aprovada” sem qualificar.

## 1. Esclarecer

Perguntas em lotes de 3–5 até cobrir o mínimo do template Entrega. Skeleton:
[`templates.md`](templates.md) (use se `docs/` / ISSUE_TEMPLATE do repo faltarem).

| # | Perguntar | Por quê |
| --- | --- | --- |
| 1 | Em uma frase: o que fica pronto ao fechar? | Título + resumo |
| 2 | Problema hoje (o que alguém vê/sofre)? | Produto |
| 3 | Se fizermos / se NÃO (benefício, risco, dá para viver sem)? | Impacto |
| 4 | Casos de borda (EARS) críticos | Obrigatório |
| 5 | Como saber que passou (T* / evidência)? | TDD obrigatório |
| 6 | Fora de escopo? | Creep |
| 7 | Bug, entrega, audit ou fatia de guarda-chuva (#mãe)? | Tipo + links |
| 8 | Muda comportamento? SPEC nova/update? | Spec no PR |
| 9 | Esforço S/M/L (se souber)? | Priorização |

Sem decisão só-humana → não invente; deixe lacuna explícita no draft ou pare.

Chat stage: `intake` (ainda sem issue).

## 2. Draft → draft-approved

Mostre o corpo completo (PT-BR) e pergunte:

> Posso criar a issue no GitHub com este texto?  
> **Sim** (draft-approved) / **Ajustar** / **Cancelar**  
> Opt-out de planejamento: diga também **“só cria, não planeja”** se quiser parar em `needs-plan`.

- **Ajustar** → edite; não crie.  
- **Cancelar** → pare.  
- **Sim** → `gh issue create` + tipo + `stage:needs-plan`; anuncie URL/#N.

## 3. Após draft-approved + create → auto plan→review

**Política única:** sem opt-out explícito (“só cria, não planeja”), o orquestrador
**sempre** dispara:

1. Subagente de **plano** (`stage:needs-plan` → plano postado).
2. Em seguida subagente de **review** (`stage:in-review`) — **sem** pedir OK
   humano entre os dois.

Com opt-out → **pare** em `stage:needs-plan` e anuncie que o fluxo B→C fica para
quando pedirem “planeja” / “roda o fluxo”.

Não trate draft-approved como plan-approved nem como licença para implementar.
