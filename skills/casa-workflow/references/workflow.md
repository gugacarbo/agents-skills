# Workflow CASA

Leia esta referência por completo quando o router ativar o CASA.

## Classificar a unidade de trabalho

1. Resolva o contrato pinado conforme
   [source-resolution.md](source-resolution.md); não aplique silenciosamente
   outra versão.
2. Inspecione status, diff, tarefa, código e documentos relacionados sem usar
   artefatos gerados proibidos pelo repo.
3. Leia o tier antes de classificar documentos:
   - T0: não exigir ADR, Spec nem `docs/context/`; manter `AGENTS.md` e DoD.
   - T1: classificar decisão e comportamento conforme
     [impact-lifecycle.md](impact-lifecycle.md).
4. Calcule `artifact_action`, `context_suggestion` e `authorization_basis`;
   derive `gate_required` somente depois dessas classificações e então calcule
   `gate_bypass`.
5. Leia [context-persistence.md](context-persistence.md) se houver intenção ou
   descoberta durável.
6. Use `gate_required=true` se a mutação de documento CASA for inferida, não
   pedida, ultrapassar o escopo autorizado ou depender de decisão ainda aberta.
   São documentos CASA os routers `AGENTS.md`, a ponte `CLAUDE.md`, ADRs, Specs,
   capítulos de contexto, backlog, templates e índices CASA.
7. Use `gate_required=false` quando o usuário pedir diretamente criar,
   atualizar, depreciar ou fechar o artefato com ação e escopo semântico
   identificáveis. Continue sem gate quando não houver escrita documental e em
   toda auditoria read-only, mesmo que ela conclua que documentos futuros serão
   necessários.

## Resolver bypass

Use `gate_bypass=explicit` quando o pedido atual disser inequivocamente para
usar auto-approve, bypass, considerar aprovado ou não pedir gates **CASA**. Use
`gate_bypass=persistent` quando qualquer `AGENTS.md` aplicável ao arquivo alvo
contiver exatamente:

```markdown
<!-- casa-gates: bypass -->
```

O marker no router raiz cobre o repositório; em router aninhado cobre somente a
subtree. Não infira bypass de comentário aproximado ou de frases genéricas como
“faça direto”. Preserve o marker durante upgrades, salvo pedido para removê-lo.

Distinga duração pelo pedido:

- “use/aplique bypass nesta tarefa” → `explicit`; não edite `AGENTS.md`;
- “ative/habilite bypass no projeto/repo”, “persistentemente” ou “a partir de
  agora” → localize o `AGENTS.md` raiz aplicável e insira o marker exato uma vez;
- subtree nomeada explicitamente → use o router aninhado correspondente.

Ativação persistente é uma edição diretamente pedida: não abre gate, não altera
outros arquivos e é idempotente se o marker já existir.

Quando `gate_required=true` e houver bypass, não renderize o relatório nem peça
`Aprovar`, `Ajustar` ou `Bloquear`: resolva fatos, decisões in-scope e source-set,
trate o envelope como aprovado e escreva os documentos. O bypass explícito vale
para todos os gates CASA da tarefa; o persistente, para todos os gates no escopo
do router. Ele não transforma mera `context_suggestion` em escrita nem amplia a
tarefa.

Quando a classificação T1 exigir ADR ou Spec inferida, materialize o documento
antes do código sob o bypass. Código implementado enquanto a Spec obrigatória
continua ausente é sinal de que o bypass foi confundido com dispensa documental;
pare e complete o artefato.

“Adote/atualize para as regras mais novas” não identifica o escopo semântico:
versão, ref e source-set ainda são decisões abertas. Resolva o alvo oficial,
inclua o envelope exato no relatório e peça o gate antes da mutação. Um pedido
direto com versão/ref exatos e artefatos identificáveis pode seguir sem a
confirmação redundante.

Sem bypass, “faça agora” ou autorização genérica não aprova envelope ainda não
relatado. Com bypass CASA explícito ou persistente, a confirmação conversacional
é dispensada mesmo para envelope recém-resolvido.

Risco técnico não substitui o predicado documental. Segurança, dados, operação
destrutiva, efeito remoto e expansão de escopo podem exigir autorização própria
pelas regras gerais do agente, mas não o relatório CASA sem escrita documental.
Não use essa regra para pular o mapa de impacto T1: classifique primeiro ADR,
Spec e contexto obrigatórios; somente então derive o gate da mutação resultante.

Se `gate_required=false` ou houver bypass, continue sem relatório CASA. Sem
bypass, uma obrigação T1 que exija mutação documental não autorizada diretamente
emite o relatório e para antes da escrita. Ao executar, use `docs-reserve` quando
existir; sem ele, derive o próximo `NNNN` de quatro dígitos dos arquivos locais e preserve o formato
`docs/specs/NNNN-titulo-kebab.md`. Não crie documento por cerimônia.

## Preparar o relatório

Somente quando `gate_required=true`:

Se houver bypass, pule esta seção inteira e execute o envelope resolvido.

1. Separe fatos verificáveis de decisões abertas. Alegação não é evidência.
2. Declare qual mutação documental inferida, fora do escopo ou decisão aberta
   acionou o gate.
3. Emita o relatório usando
   [gate-template.md](gate-template.md) e encerre o turno no gate.

Em upgrade, a toolchain local é somente evidência de divergência. Resolva
`STANDARD.md` e `CHANGELOG.md` no upstream canônico
`atplus-digital/casa-standard` antes de propor versão/ref alvo. Se isso falhar,
marque o alvo como não resolvido. Homônimos chamados CASA não são fontes
válidas. Nomeie literalmente o upstream no relatório e só proponha um ref exato
confirmado; `main` é fonte de descoberta, não ref pinado.

## Após o gate

- `Aprovar`: altere somente os artefatos aprovados e use a toolchain local.
- `Ajustar`: revise o mapa, emita novo relatório e pare novamente.
- `Bloquear`: não materialize nada.
- A aprovação cobre o source-set, o contrato e as obrigações da unidade de
  trabalho descrita; novas edições e arquivos dentro desse envelope não exigem
  outro gate.
- Reabra antes da próxima escrita somente se surgir mutação de documento CASA
  fora do envelope aprovado.

No fechamento, verifique paths, comandos, DoD, estado atual e gotchas. Não
declare Spec `implemented` sem `implemented-by` real, verificação executada,
casos relevantes cobertos, propagação aplicável e índices regenerados pela
ferramenta.

Se uma intenção durável foi inferida e não era edição documental explícita,
termine a tarefa e só então apresente a sugestão compacta definida em
`context-persistence.md`. A sugestão não reabre gate e não autoriza escrita.

## Guardrails

- Adoção CASA ativa a classificação; somente mutação documental não autorizada
  diretamente, fora do escopo ou dependente de decisão aberta aciona o gate.
- Quantidade de linhas e risco técnico não definem o threshold.
- Pedido direto para criar, atualizar, depreciar ou fechar documento de escopo
  identificável não recebe confirmação CASA redundante.
- Adoção ou upgrade com alvo móvel/não resolvido abre gate; “mais novo” não é
  versão/ref nem source-set identificável, mas bypass dispensa sua confirmação.
- Feature T1 que exige Spec não pedida abre gate antes da escrita documental.
- Correção que restaura contrato existente não altera a Spec.
- Auditoria read-only nunca abre gate, inclusive quando recomenda ADR ou Spec.
- T0 não herda as camadas documentais de T1.
- Não edite o corpo de ADR aceita; crie nova ADR e marque a anterior como
  `superseded`.
- Não implemente contrato observável sem a Spec exigida pelo contrato pinado.
- Bypass elimina apenas a confirmação CASA: não permite omitir Spec obrigatória,
  editar corpo de ADR aceita ou fechar Spec sem evidência.
- Não execute `casa-init`, upgrade, issue, PR, label ou outro efeito remoto sem
  autorização específica; gate CASA existe apenas se também houver mutação
  documental e não concede autorização remota.
- Não copie o Standard, edite índice gerado manualmente ou use `dist/` quando o
  repo o proibir.
- Ao detectar escrita prematura, pare, reporte o desvio e retorne ao gate.

Metadados de desenvolvimento: [interface do agente](../agents/openai.yaml),
[runner de evals](../evals/run-evals.mjs) e
[catálogo de ativação](../evals/trigger-evals.json).
