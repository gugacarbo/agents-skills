# Contexto, discovery e retomada

Discovery pode começar sem issue e é sempre read-only.

1. Leia guidance, issue forms, ADR/spec, código/testes, labels, comentários,
   PRs e entregas recentes antes de perguntar fatos descobríveis.
2. Resuma decisões confirmadas, lacunas materiais e próxima entrada
   recomendada. Sem issue, não produza plano formal, código ou review.
3. Antes de operar uma issue, confirme entrega/bug; Epic/tracker é inelegível.
4. Leia/proponha `Complexity`, recalcule risco e só então interprete gates.
5. Valide header/estado pela tabela de verdade de `references/github-flow.md`.
6. Em blocker resolvido, leia `Resume operation/stage/owner`, recalcule risco e
   deixe o orquestrador aplicar o destino ainda válido.

## Legacy e drift

- Header ausente + exatamente um `stage:*`: preserve o gate, registre
  `Workflow: fallback` e proponha Complexity; metadata fica fora dos
  marcadores e não altera/invalida o digest do source-set protegido.
- Header/estado contraditório: publique diagnóstico e pare sem escolher uma
  fonte silenciosamente.
- Native inválido: ofereça migração explícita e compensável para o fallback no
  gate equivalente.

## Batch

Mantenha visão, risco, workflow, worktree e falhas por issue. `--from` é o piso
da operação, não um stage exato: issue antes desse piso é reportada como
inelegível e nunca pula gates; issue já adiante continua do próprio gate e
nunca retrocede. Continue trilhas elegíveis apesar das inelegíveis e consolide
gates com evidência e opções literais por ID (por exemplo `#30`, `#32`) ou uma
autorização explícita para “todas as listadas”. Não escreva registry ou arquivo
de progresso.
