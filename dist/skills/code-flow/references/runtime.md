# Runtime, papéis, protocolo e checklist da code-flow

## Complexidade e rigor adaptativo

Issue-writer propõe e persiste Complexity; risco decide gates e permanece
efêmero. Recalcule em criação, retomada, gates e mudança de base/escopo.

| Valor | Critério                                                         |
| ----- | ---------------------------------------------------------------- |
| XS    | Interna, localizada, reversível, caminho conhecido, uma área.    |
| S     | Um componente, poucas alterações acopladas, validação rotineira. |
| M     | Vários componentes ou coordenação relevante em um repo.          |
| L     | Mudança ampla/transversal ou incerteza significativa.            |
| XL    | Múltiplos resultados/dependências; recomende decomposição/Epic.  |

Mapeamento: `XS → light`, `S/M → standard`, `L/XL → secured`. O nome interno
nunca é persistido. Comportamento observável em um componente começa em S até
discovery provar todos os critérios de XS.

### Hard triggers

- autenticação, autorização, permissões, segredos ou fronteiras de confiança;
- migração de dados/esquema ou contrato público;
- conflito entre ADR/spec aceita, código e pedido;
- mudança cross-repo, irreversível ou de alto blast radius;
- operação destrutiva, acesso privilegiado ou rollback não demonstrado.

Urgência, diff pequeno, complexidade S ou aceite genérico de risco não removem
hard trigger.

### Papéis e gates

- Toda triagem exige gate humano, exceto XS sem hard trigger, que pode ser
  auto-aprovado pelo issue-writer com evidência clara e publicada.
- XS sem hard trigger não exige arquitetura.
- S sem hard trigger usa architect, mas `not required` segue direto à execução.
- M+, hard trigger ou spec create/update exige gate humano de execução.
- Toda entrega exige uma única delivery review independente; não há auditoria.
- Diff aprovado exige gate humano de merge; `NO_CHANGES` não exige close gate.

Trocar nome/modelo ou sessão não apaga autoria. O autor GitHub do início do
reviewer não pode ter produzido artefato anterior de issue-writer, architect ou
executor; sem autor independente comprovável, pare para revisão humana externa.

### Drift de base

Drift não material atualiza Base SHA e repete checks. Conflito ou mudança na
área, contrato ou dependência autorizada é material e exige nova delivery
review; risco/hard trigger novo retorna ao architect. Nunca confie apenas em
label ou aprovação anterior.

## Papéis e modelos

Papéis são contratos independentes; modelos são escolha efêmera do host. Não
crie `.codex/agents`, altere `config.toml` ou instale configuração no repo alvo.

| Papel        | Capacidade preferida                         |
| ------------ | -------------------------------------------- |
| issue-writer | Exploração e síntese rápidas.                |
| architect    | Maior capacidade de raciocínio disponível.   |
| executor     | Edição, testes e ferramentas.                |
| reviewer     | Revisão/raciocínio em instância sem autoria. |
| integrator   | Git, validação, rebase e recuperação segura. |

Configuração explícita do usuário vence preferências. Sem roteamento, use o
modelo herdado e preserve papéis por instâncias independentes. Sem paralelismo,
execute em sequência. Sem instância e autor GitHub independentes para review,
pare e peça revisão humana externa; nunca simule independência.

Nunca persista modelo, effort ou disponibilidade em body, labels ou arquivos do
repositório. A skill oferece somente sinalização cooperativa por
`stage:in-progress`; para execução distribuída em VPS com lease atômico, consulte
[`vps-runtime.md`](vps-runtime.md).

## Protocolo GitHub

`code-flow:active` ativa o protocolo. Enquanto presente, exatamente um estado
principal de `workflow-states.json` identifica o próximo responsável. O overlay
`stage:in-progress` pode coexistir com esse estado durante uma execução.

`workflow-states.json` é a única fonte de labels canônicas, ator, tipo e
transições permitidas. Papéis e fases descrevem trabalho e evidências; não
definem roteamento próprio.

| Label                               | Próximo responsável   | Exige `needs-human` |
| ----------------------------------- | --------------------- | ------------------- |
| `stage:needs-triage`                | issue-writer          | não                 |
| `stage:awaiting-triage-approval`    | humano                | sim                 |
| `stage:needs-architect`             | architect             | não                 |
| `stage:awaiting-execution-approval` | humano                | sim                 |
| `stage:ready-for-execution`         | executor              | não                 |
| `stage:needs-changes`               | executor              | não                 |
| `stage:needs-delivery-review`       | reviewer              | não                 |
| `stage:ready-to-merge`              | humano                | sim                 |
| `stage:integration-authorized`      | integrator            | não                 |
| `stage:blocked`                     | responsável do Resume | sim                 |

`responsável do Resume` é o humano operando o gate `resume`, não um agente
canônico. O self-loop `stage:ready-to-merge` → `stage:ready-to-merge` em
`workflow-states.json` representa o gate `wait`: é idempotente e não muta labels
(o `transition-issue.sh --gate-to stage:ready-to-merge --require-from
stage:ready-to-merge` valida e não aplica nenhuma mutação).

### Invariantes

- Issue ativa: `code-flow:active` + um estado principal.
- Atividade: estado principal + `stage:in-progress`, nunca `needs-human`.
- Gate: estado humano + `needs-human`, nunca `stage:in-progress`.
- Overlay observado bloqueia cooperativamente novo início; não é lock atômico.
- Evidência precede toda mutação e a confirmação remota a sucede.
- Um agente aplica a transição causada por seu próprio artefato; `gate` aplica
  apenas uma decisão humana já fornecida.

Use `scripts/transition-issue.sh` com `--require-from`. `--start-work` adiciona
somente o overlay. `--finish-to` substitui o estado principal e remove overlay.
`--activate` inicia uma issue; `--complete` limpa labels somente após a issue
estar fechada. A saída segura usa `stop`, não `--complete`.

### Migração segura

Issue sem `code-flow:active` nunca é adotada automaticamente. Se houver labels
legadas, publique primeiro a proposta:

| Legado                        | Destino após confirmação                           |
| ----------------------------- | -------------------------------------------------- |
| `stage:needs-architect`       | mesmo estado                                       |
| `stage:approved`              | `stage:awaiting-execution-approval + needs-human`  |
| `stage:needs-delivery-review` | mesmo estado                                       |
| `stage:needs-changes`         | mesmo estado                                       |
| `stage:ready-to-merge`        | mesmo estado + `needs-human`                       |
| `stage:ready-to-close`        | `stage:integration-authorized`                     |
| `stage:blocked`               | mesmo estado + `needs-human`                       |
| `stage:in-progress` sozinho   | ambíguo; reconstruir por evidência e pedir escolha |

Não escreva `Workflow` no body. A skill continua lendo branch protection,
forms, comandos e método de merge do repositório; somente seu estado de entrega
usa labels canônicas.

### Falha parcial

As APIs de label não formam uma transação. O helper relê e confirma cada
resultado, retorna erro em drift e aceita reparo somente com `--allow-repair`.
Não alegue exclusão concorrente ou sucesso quando a confirmação final falhar.

## Checklist do workflow

1. Confirme `code-flow:active` e exatamente um estado principal.
2. Antes de iniciar, recuse `needs-human` ou overlay já existente.
3. Publique início; depois adicione `stage:in-progress` preservando o principal.
4. Leia guidance e recalcule risco em toda retomada.
5. Publique resultado; depois conclua a transição e confirme labels.
6. Human gate sempre tem `needs-human`; atividade nunca tem.
7. Reviewer é independente e único; não existe auditoria.
8. Integrator distingue PR de NO_CHANGES e verifica rebase antes de fechar.
9. Falha parcial não é sucesso; registre reparo/Resume.
10. Stop limpa labels somente após handoff e preserva artefatos.

### Saindo de `stage:blocked`

Somente o gate `resume <stage>` sai de `stage:blocked`. O destino é o estado
comprovado no comentário `Resume`, não uma escolha livre — `transition-issue.sh`
valida contra o `next[]` do registry. Nunca infira estado de evidência
ambígua; sem `Resume` legível, reconstrua por evidência e peça confirmação
humana antes de mutar.
