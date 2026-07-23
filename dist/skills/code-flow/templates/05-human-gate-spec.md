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

| Gate      | Opções aceitas                 |
| --------- | ------------------------------ |
| triage    | `approve                       | adjust | block` |
| execution | `authorize                     | adjust | block` |
| merge     | `integrate                     | adjust | wait`  |
| resume    | `<stage registrado no Resume>` |
| activity  | `reset`                        |

Valide estado, `needs-human`, ausência de overlay, evidência e opção. Publique
esta decisão antes de mutar e confirme labels depois. `activity reset` é a única
exceção: exige overlay e preserva o estado principal.

## Ação do usuário

Comentário a ser publicado para o solicitante/observadores registando a decisão
humana ou a aprovação automática:

```markdown
> Aguardando confirmação humana para `approve`/`authorize`/`integrate` ou
> ajuste/bloqueio conforme indicado.
>
> Evidência revisada:
> - artefato: <link>
> - digest: <sha>
> - Base/Head: <sha/sha ou n/a>
>
> Próximo estado: `<stage resultante>`
> Próximo responsável: <humano | papel>
```

Para aprovação automática (ex.: XS sem hard trigger e evidência clara), publique
o mesmo formato substituindo a primeira linha por `Decisão automática aplicada
por regra de projeto.` e documente a regra seguida.
