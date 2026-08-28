# AGENTS.md

```yaml
casa-repo-id: agent-skills # usado em referências cross-repo (repo:ADR-0001)
casa-tier: T0 # T0 (leve) | T1 (padrão) — STANDARD §3
casa-version: 1.8 # versão do contrato CASA adotado (promessa do repo, ADR-0010)
casa-standard-ref: 7cdb964 # versão do casa-standard de origem — o casa-init carimba
```

> Padrão: https://github.com/atplus-digital/casa-standard (STANDARD.md)
> ROUTER (CASA §4): carga sempre, teto ~150 linhas. Só alto-ROI transversal.
> Estourou o teto → conteúdo desce para docs/context/, fica o ponteiro.
> ⚠️ NÃO usar @import para colar capítulos: @import expande tudo no launch.
> Regras de um pacote específico → <subdir>/AGENTS.md (lazy nativo, nearest-wins).

## Contexto em 5 linhas

Repositório de skills reutilizáveis para agentes Codex e integrações relacionadas.
As skills publicadas são pastas com `SKILL.md` e runtime; algumas têm tooling privado de desenvolvimento.
O workspace usa Bun para descobrir e executar os packages privados em `skills/*`.
Scripts de build/teste usam Bash, Python e Node conforme a skill.

## Rules

### Não edite os arquivos em /dist; esses arquivos sempre são gerados com script

## Artefatos publicados

- `dist/` e um artefato gerado, versionado para que o instalador remoto tenha
  skills prontas. Não o leia, pesquise, edite ou use como fonte, salvo pedido
  explícito do usuário.
- A fonte de verdade é `skills/*`. Gere `dist/` somente por `bun run build`; o
  hook de pre-push versiona automaticamente o resultado gerado.

## Infra & ambientes

<!-- Onde roda; o que é self-hosted. ⚠️ Liste ferramentas que NUNCA usar
     (ex.: "Supabase self-hosted → nunca usar o supabase CLI").
     Detalhe extenso → docs/context/INFRA.md (ponteiro no mapa abaixo). -->

## Como rodar localmente

```bash
bun install
bun run test
bun run build
```

## Como validar (DoD global do repo)

```bash
bun run test            # exit 0
bun run build           # artefatos publicados válidos
bun run skills-check    # relações e arquivos publicados das skills válidos
```

## Como fazer deploy

<!-- Ferramenta/script oficial, ordem, e o que NÃO fazer. -->

## Git & PRs

<!-- Convenções; quando fazer commit; se há remote; se o agente abre PR sem ser pedido. -->

## Gotchas

<!-- Conhecimento NÃO-INFERÍVEL que já custou tentativas falhas. Todo gotcha
     descoberto pelo agente DEVE ser registrado aqui. -->

-
- `package.json` dentro de `skills/*` é tooling privado: o build remove manifests,
  locks e diretórios de desenvolvimento antes de copiar para `dist/`.
- O hook `scripts/pre-commit` usa `scripts/shared.sh`; não mover o arquivo sem
  atualizar o caminho do source.
- `skills/skill-master` validate (`scripts/quick_validate.py`) usa PyYAML se
  disponível; sem o pacote cai num parser mínimo de frontmatter. Não deixar o
  monorepo build depender de `pip install PyYAML` para passar.
- Não use `test-staged` no hook: o pacote raiz não expõe um runner
  Jest/Vitest detectável. O `scripts/pre-commit` seleciona testes por escopo:
  runtime raiz roda `bun run test`, e mudanças em uma skill rodam somente o teste
  daquela skill.
- O commit automático de `dist/` no pre-push define
  `AGENTS_SKILLS_GENERATED_ARTIFACT_COMMIT=1`; o pre-commit então não repete
  checks que o `bun run verify` já concluiu antes de gerar o artefato.
- `skills/brainstorm/package.json` aponta para `tests/tests.test.ts`
  conforme a convenção das suítes de teste.

## Mapa de contexto

<!-- Índice dos capítulos (docs/context/), cada um com QUANDO carregar.
     Capítulo = estado atual, imperativo, atemporal. Decisão datada = ADR. -->

| Capítulo       | Quando carregar |
| -------------- | --------------- |
| (nenhum ainda) | —               |

## Mapa de docs

- Decisões: `docs/adr/` · Comportamento: `docs/specs/` (READMEs GERADOS — não editar)
- Validar: `scripts/docs-check` · Regenerar índices: `scripts/docs-check --emit-index`
