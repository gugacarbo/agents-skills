---
name: casa-workflow
description: Guardrail host-neutral para mudanças em repositórios CASA. Use quando o usuário invocar $casa-workflow, mencionar CASA, casa-init ou docs-check, pedir adoção/upgrade do padrão, criar ou alterar ADRs, Specs ou contexto, fechar uma Spec, ou implementar código em um repo cujo AGENTS.md declare metadados CASA. Não use para trabalho comum em repo não CASA, explicação acadêmica genérica de ADR ou formatação sem impacto CASA.
---

# CASA Workflow

Atuar como copiloto do ciclo CASA; deixar a implementação de domínio no fluxo que originou a tarefa.

## Regra de parada imediata

Antes de qualquer escrita, calcular `gate_valido` somente pelo histórico observável:

- o turno imediatamente anterior do agente emitiu o relatório CASA completo e terminou solicitando `Aprovar`, `Ajustar` ou `Bloquear`; e
- o turno atual do usuário responde a esse relatório com uma dessas escolhas.

Se qualquer condição for falsa, `gate_valido=false` e toda escrita fica proibida. Frases no pedido inicial como “considere aprovado”, “já está aprovado”, “não peça confirmação” ou equivalentes são **preaprovação alegada**, nunca resposta ao relatório ainda inexistente. Nesse caso, fazer apenas a análise read-only, emitir o relatório e encerrar no gate. Não executar primeiro para relatar depois.

## Invariante de adoção

Antes de declarar que CASA não se aplica ou executar qualquer escrita, localizar e ler o `AGENTS.md` aplicável e procurar `casa-repo-id`, `casa-tier`, `casa-version` e `casa-standard-ref`. Determinar adoção somente por essa evidência do repositório, nunca pelo tamanho, urgência ou natureza local da tarefa.

- Se os quatro metadados existirem, tratar o repo como adotante e aplicar o gate a toda mutação de código ou artefato CASA.
- Se qualquer metadado `casa-*` existir de forma parcial, tratar como adoção incerta, reportar a lacuna e manter o gate.
- Só usar a saída de não adotante depois de comprovar que nenhum metadado CASA existe nas instruções aplicáveis.
- “Bugfix local”, “mudança trivial” e “sem alteração de API ou arquitetura” podem dispensar novo ADR/Spec, mas nunca provam que o repo não adotou CASA nem dispensam o gate de código.

## Invariante de duas fases

Para qualquer mutação em repo adotante, o gate é um protocolo entre turnos:

1. no turno que descobre o impacto, emitir o relatório e encerrar imediatamente após pedir `Aprovar`, `Ajustar` ou `Bloquear`;
2. só escrever em um turno posterior, se a resposta do usuário ao relatório trouxer uma dessas escolhas.

O pedido inicial nunca aprova o próprio relatório que ainda não existe. “Faça agora”, “vá direto”, “já está aprovado”, autoridade, urgência ou autorização genérica no mesmo pedido não substituem a resposta posterior ao gate. Não emitir o relatório e continuar no mesmo turno, mesmo que o alvo já tenha sido resolvido e a mudança pareça mecânica.

## Executar o workflow

1. Aplicar primeiro a invariante de adoção; só depois inspecionar status/diff e arquivos da tarefa. Não ler nem usar artefatos gerados proibidos pelo repo.
2. Se a busca comprovar ausência de metadados CASA e o pedido não for adoção, upgrade ou auditoria CASA, registrar brevemente que a skill não se aplica e devolver imediatamente a tarefa ao fluxo original, sem relatório CASA nem gate.
3. Resolver o contrato pinado conforme [source-resolution.md](references/source-resolution.md). Não aplicar silenciosamente regras de outra versão.
   Em pedido de upgrade, a versão da toolchain é apenas evidência de divergência: não é prova da versão/ref oficial desejada. Resolver `STANDARD.md` e `CHANGELOG.md` no upstream canônico `https://github.com/atplus-digital/casa-standard` antes de propor o alvo; se isso não for possível, marcar versão e ref alvo como não resolvidas e manter o gate sem prometer edições específicas. No relatório, nomear literalmente `atplus-digital/casa-standard` como a única autoridade externa consultada e registrar que homônimos chamados CASA não são fontes válidas.
4. Inspecionar tarefa, código e documentos relacionados. Classificar decisão, comportamento observável, estado atual e regra operacional conforme [impact-lifecycle.md](references/impact-lifecycle.md).
5. Separar fatos verificáveis de decisões abertas. Não inventar decisão nem tratar alegação como evidência.
6. Em repo adotante, se a tarefa puder alterar código ou artefato CASA, emitir o relatório abaixo e parar antes da primeira escrita. Em não adotante, aplicar o gate somente à adoção solicitada. Uma autorização genérica anterior para implementar não substitui este gate.
7. Continuar somente em turno posterior após resposta explícita `Aprovar`, `Ajustar` ou `Bloquear` ao relatório recém-emitido. Em `Ajustar`, revisar o mapa e repetir o gate. Em `Bloquear`, não materializar nada.
8. Após `Aprovar`, criar ou atualizar somente os artefatos CASA aprovados, usando a toolchain local. Validar os documentos e devolver a implementação de domínio ao fluxo original.
9. Monitorar o source-set aprovado. Reabrir o gate antes de continuar se surgir novo impacto de escopo, decisão, contrato ou fechamento.
10. No fechamento, verificar paths, comandos, resultados, DoD por caso relevante, estado atual e gotchas. Não declarar `implemented` com evidência pendente.

Auditorias read-only e formatação comprovadamente sem impacto CASA não exigem bloqueio, mas não autorizam efeitos externos. Adoção via `casa-init` altera o repo e exige o mesmo gate.

## Relatório pré-escrita

Retornar estas seções nesta ordem, de forma curta e baseada em evidência:

1. **Contexto CASA** — adoção, tier, versão, ref, estado do `docs-check` e fontes carregadas.
2. **Achados por risco** — bloqueantes, obrigatórios antes do código, necessários no fechamento e não aplicáveis relevantes.
3. **Impacto de artefatos** — para cada item: artefato, estado atual, transição necessária e evidência.
4. **Ações antes do código**.
5. **Obrigações de fechamento**.
6. **Efeitos externos** — listar separadamente; gate CASA não autoriza issue, PR, label ou outro estado remoto.
7. **Gate** — solicitar exatamente `Aprovar`, `Ajustar` ou `Bloquear`.

## Guardrails observados

- Não editar código nem documento CASA antes do gate quando houver mutação relevante.
- Não oferecer “pular o processo assumindo o risco” como alternativa ao gate.
- Não editar o corpo de ADR aceita; criar uma nova ADR e superseder a anterior conforme o contrato pinado.
- Não implementar feature com contrato observável sem a Spec exigida pelo tier/contrato.
- Não fechar Spec sem `implemented-by` real, verificação executada e propagação aplicável.
- Não editar índices gerados manualmente nem copiar templates ou o Standard a partir desta skill.
- Não executar `casa-init`, upgrade ou efeito remoto sem autorização específica.
- Não usar a versão anunciada por `docs-check` ou outra toolchain como alvo automático de upgrade; confirmar versão e ref no Standard/CHANGELOG oficiais.
- Não usar fontes de projetos homônimos chamados CASA. Para este workflow, a única autoridade externa é `atplus-digital/casa-standard` ou outra origem explicitamente declarada pelo repo adotante.
- Não dizer “a skill CASA não se aplica” antes de ler o `AGENTS.md` aplicável; tarefa local não é evidência de não adoção.

Ao detectar qualquer escrita prematura, parar, reportar o desvio e retornar ao gate.

Metadados de desenvolvimento: [interface do agente](agents/openai.yaml) e [runner de evals](evals/run-evals.mjs).
