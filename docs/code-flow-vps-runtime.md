# Runner VPS da code-flow

> Status: o contrato portátil do worker está publicado com a skill; o launcher
> VPS continua fora deste repositório.

A `code-flow` publica `manifest.json`, schemas de entrada/resultado/evento e
um runtime worker. Um launcher externo pode observar labels e comentários,
criar um `run_id`, montar o bundle + checkout/worktree e iniciar uma sessão de
um único papel. O agente aplica as mutações de protocolo via eventos.

O bundle ainda não oferece claim atômico, heartbeat, lease ou recuperação
automática. Labels continuam sendo sinalização cooperativa.

O runner VPS poderá adicionar:

1. descoberta por webhook/poll;
2. claim atômico em serviço externo ou Project V2;
3. worker/run identity e heartbeat;
4. retry e expiração;
5. worktree isolada por issue/run;
6. deduplicação distribuída e despacho portátil dos papéis.

Até isso existir, overlay inconsistente exige `/code-flow gate reset`; nenhum
script da skill deve alegar exclusão concorrente. A primeira execução de issue
legada exige `/code-flow gate migrate`, com restauração explícita do estado.
