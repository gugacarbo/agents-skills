# Dev: Testes e Scripts Auxiliares do super-planning

Esta pasta agrupa ferramentas auxiliares desenvolvidas para validar a skill super-planning sem misturar-se com o conteúdo publicado da skill.

- `tests.sh` — Suite de testes de integração para os scripts da skill (super-plan.sh, render-progress-ledger.sh, log-task.sh, summarize-all-tasks.sh). Antes localizada em `.scripts/tests/super-planning.sh`.

Para executar os testes:

```bash
bash super-planning/dev/tests.sh
```

Para executar a partir da raiz do workspace:

```bash
cd /home/gustavo/.agents/skills
bash super-planning/dev/tests.sh
```
