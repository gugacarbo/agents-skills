# Gate humano

> agent: <agente que solicita a decisão humana>
> sources_evidence: <artefatos, reviews e estado observável que fundamentam o gate>

## Resume

<decisão solicitada e motivo do gate>

## Estado atual

<stage ou estado nativo, presença de needs-human e artefato aprovado>

## Decisão solicitada

<o que a pessoa precisa decidir agora>

## Opções e consequências

| Resposta literal da fase | Transição ou permanência | Consequência e próximo ator |
| ------------------------ | ------------------------ | --------------------------- |
| `<opção>`                | `<estado resultante>`    | `<efeito>`                  |

Use somente as opções literais da fase, por exemplo:

- source/plan: `Aprovar / Ajustar / Bloquear`;
- integração: `Integrar / Ajustar / Aguardar`;
- NO_CHANGES: `Fechar / Ajustar / Aguardar`;
- Epic: `Fechar Epic / Replanejar / Aguardar`.

_O orquestrador aplica e confirma a transição causada pela decisão humana._
