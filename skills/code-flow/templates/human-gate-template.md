> agent: gate
> run_id: n/a
> event: gate-decision
> state_before: <estado + needs-human>
> state_after: <estado>
> sources_evidence: <artefatos, digest/Base e resposta humana>
> project_guidance: <paths e comandos>

## Resume

<decisão literal, consequência e próximo responsável>

<!-- Valide evidência, estado, ausência de overlay e opção antes de publicar. -->

## Decisão

| Gate      | Opções               |
| --------- | -------------------- |
| triage    | `approve             | adjust | block` |
| execution | `authorize           | adjust | block` |
| merge     | `integrate           | adjust | wait`  |
| resume    | `<estado do Resume>` |
| activity  | `reset`              |

## Ação humana

- Decisão: `<valor>`
- Artefato: `<link>`
- Digest/Base/Head: `<prova>`
- Próximo estado: `<stage:*>`
- Próximo responsável: `<papel | humano>`
