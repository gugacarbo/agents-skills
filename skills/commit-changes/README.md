# commit-changes

Cria commits Git pequenos e revisáveis a partir das alterações locais, usando
mensagens no padrão Conventional Commits.

## Comportamento

A skill:

1. resolve o escopo pedido;
2. inspeciona alterações staged e unstaged;
3. separa assuntos independentes quando os limites entre arquivos são seguros;
4. verifica se a mudança exige sincronizar o `AGENTS.md` mais próximo;
5. apresenta o plano;
6. executa e verifica cada commit sequencialmente.

Um pedido explícito de commit já autoriza a execução. A skill só pausa diante
de risco ou ambiguidade reais.

## Escopo

| Pedido | Escopo |
| --- | --- |
| caminhos nomeados | somente esses caminhos |
| `all`, `--all`, `tudo` ou equivalente | worktree inteira |
| `commit isso` após uma implementação | arquivos do trabalho recente |
| nenhum contexto utilizável | worktree inteira |

Alterações alheias ao escopo permanecem intactas.

## Limites de segurança

A execução para quando encontra:

- conflito, merge, rebase ou cherry-pick em andamento;
- nenhum arquivo alterado no escopo;
- staging existente incompatível com o grupo planejado;
- assuntos misturados no mesmo arquivo que exigiriam decisão semântica de
  hunks;
- identidade Git ausente;
- falha de hook que exige decisão de produto ou refatoração não óbvia.

A skill não descarta mudanças do usuário, não inventa identidade Git e não
ignora hooks por conveniência.

## Mensagens

Formato:

```text
<type>(<scope>): <assunto imperativo>
```

Exemplos:

```text
feat(auth): add token refresh flow
fix(api): handle missing user avatar
docs: update local setup steps
```

## Validação comportamental

Os evals comparam a versão anterior e a candidata em repositórios temporários:

```bash
bun evals/run-evals.mjs \
  --configuration candidate \
  --skill . \
  --output /tmp/commit-changes-evals \
  --model gpt-5.4-mini \
  --reasoning medium
```

Os cenários ficam em `evals/evals.json`; resultados, transcrições e estado Git
são gravados fora do repositório no caminho informado por `--output`.
