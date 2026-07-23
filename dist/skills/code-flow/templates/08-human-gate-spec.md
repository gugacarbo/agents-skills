# Gate humano

> agent: gate
> run_id: n/a
> event: gate-decision
> state_before: <estado principal + needs-human>
> state_after: <estado resultante>
> sources_evidence: <artefatos/digest/base e resposta humana>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<decisão literal, consequência e próximo responsável>

## Decisão

| Gate | Opções aceitas |
| --- | --- |
| triage | `approve | adjust | block` |
| execution | `authorize | adjust | block` |
| merge | `integrate | adjust | wait` |
| resume | `<stage registrado no Resume>` |
| activity | `reset` |

Valide estado, `needs-human`, ausência de overlay, evidência e opção. Publique
esta decisão antes de mutar e confirme labels depois. `activity reset` é a única
exceção: exige overlay e preserva o estado principal.
