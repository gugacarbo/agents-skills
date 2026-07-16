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
O workspace usa pnpm para descobrir e executar os packages privados em `skills/*`.
Scripts de build/teste usam Bash, Python e Node conforme a skill.

## Infra & ambientes

<!-- Onde roda; o que é self-hosted. ⚠️ Liste ferramentas que NUNCA usar
     (ex.: "Supabase self-hosted → nunca usar o supabase CLI").
     Detalhe extenso → docs/context/INFRA.md (ponteiro no mapa abaixo). -->

## Como rodar localmente

```bash
pnpm install
pnpm test
pnpm build
```

## Como validar (DoD global do repo)

```bash
pnpm test                # exit 0
pnpm build               # artefatos publicados válidos
```

## Como deployar

<!-- Ferramenta/script oficial, ordem, e o que NÃO fazer. -->

## Git & PRs

<!-- Convenções; quando commitar; se há remote; se o agente abre PR sem ser pedido. -->

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

## Mapa de contexto

<!-- Índice dos capítulos (docs/context/), cada um com QUANDO carregar.
     Capítulo = estado atual, imperativo, atemporal. Decisão datada = ADR. -->

| Capítulo       | Quando carregar |
| -------------- | --------------- |
| (nenhum ainda) | —               |

## Mapa de docs

- Decisões: `docs/adr/` · Comportamento: `docs/specs/` (READMEs GERADOS — não editar)
- Validar: `scripts/docs-check` · Regenerar índices: `scripts/docs-check --emit-index`
