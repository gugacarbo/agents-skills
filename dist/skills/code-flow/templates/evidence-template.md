<!--
Contrato base para todo comentário operacional. Preencha valores concretos,
publique antes da mutação correspondente e confirme labels depois. Em blocker,
o Resume deve registrar estado exato de retorno, responsável e impedimento.
-->
<!-- code-flow:event:v1 {"event_id":"<uuid>","run_id":"<uuid>","role":"<role>","event":"<event>"} -->

> agent: <dispatcher | architect | executor | code-reviewer | integrator | gate>
> run_id: <uuid ou n/a para gate>
> event: <evento>
> state_before: <estado e overlay quando aplicável>
> state_after: <estado resultante>
> sources_evidence: <links, SHAs, comandos e artefatos>
> project_guidance: <paths nearest-wins e comandos>

## Resume

<resultado, como retomar e próximo responsável>
