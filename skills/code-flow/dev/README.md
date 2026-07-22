# Desenvolvimento da `code-flow`

Execute a suíte estrutural e os helpers fake-GitHub com:

```bash
pnpm --filter @gugacarbo/skill-code-flow test
```

A suíte valida topologia publicada, comandos públicos, metadata, tabela de
workflow, matriz de transições/ownership, blockers, `NO_CHANGES`, digest
determinístico do source-set, criação idempotente de labels fallback e remoção
do bootstrap.

`evals/evals.json` é o corpus comportamental. Para declarar a skill verificada,
use o workflow pareado do `skill-master`: snapshot antigo versus candidato,
cinco amostras fresh por cada um dos 20 cenários, grading com evidência e
revisão humana. O protocolo fixa o modelo e effort da rodada; a presença dos
prompts ou o teste estrutural verde não substitui esse benchmark.
