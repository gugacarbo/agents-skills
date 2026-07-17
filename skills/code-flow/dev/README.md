# Desenvolvimento da `code-flow`

Execute a suíte estrutural e os helpers fake-GitHub com:

```bash
pnpm --filter @gugacarbo/skill-code-flow test
```

A suíte valida topologia publicada, operações semânticas, matriz adaptativa,
ausência de perfil nos templates, opt-in nativo, criação idempotente de labels
fallback e remoção do bootstrap.

`evals/evals.json` é o corpus comportamental. Para declarar a skill verificada,
use o workflow pareado do `skill-master`: snapshot antigo versus candidato,
cinco amostras fresh por cenário, grading com evidência e revisão humana. A
presença dos prompts ou o teste estrutural verde não substitui esse benchmark.
