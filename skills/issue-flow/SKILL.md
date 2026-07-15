---
name: issue-flow
description: >-
  Orquestra criar issue (perguntas → draft-approved → create) e o fluxo
  plano→review→plan-approved→implementação com labels stage:* e needs-human.
  Use quando pedirem criar/abrir issue, esclarecer spec, planejar/revisar,
  "fecha a #N", plan review loop, worktree vs direto, ou pressão para pular
  gates. Após draft-approved + create: dispara subagente de plano e em seguida
  subagente de review sem OK humano entre os dois (opt-out: "só cria, não planeja").
---

# Issue → Plan → Review → Implement

Discipline skill: evita issue rasa, self-review e implementar sem gate.
Vocabulário (não misturar):

| Termo | Significa |
| --- | --- |
| **draft-approved** | Usuário disse **Sim** ao rascunho da issue (pré-create) |
| **plan-approved** | Label `stage:approved` — plano passou no review independente |
| Nunca diga só “issue aprovada” | Ambíguo; use draft-approved ou plan-approved |

## Hard rules (não negociar)

1. **Criar issue:** perguntas de esclarecimento + **draft-approved** (Sim no draft) antes de `gh issue create`. Ver [`references/issue-intake.md`](references/issue-intake.md). Filha de guarda-chuva = mesmo intake.
2. **Após draft-approved + create:** dispare **subagente de plano**; com plano postado, dispare **subagente de review** em seguida — **sem** OK humano entre B e C.  
   **Opt-out explícito:** usuário disse “só cria, não planeja” (ou equivalente) → pare em `stage:needs-plan`. Sem opt-out → sempre auto B→C.
3. **Plano e review** = subagentes **diferentes** (sem resume cruzado). Orquestrador **não** self-review e **não** reescreve o plano antes de passar ao revisor (passe URL do comentário do plano).
4. Se o **review falhar** (erro, vazio, sem veredito literal) → `stage:blocked` + `needs-human`. **Nunca** auto-`APROVO`.
5. **PEÇO AJUSTES** → `stage:needs-plan` + novo B→C. Um **ciclo** = um plano postado + um review postado. Comente `plan-review-cycle: k/3`. Máx. 3; no 3º PEÇO AJUSTES → `stage:blocked` + `needs-human`. Finding que exige escolha de produto/acesso → veredito bloqueante (`NÃO APROVO` / blocked), **não** `PEÇO AJUSTES`.
6. Se o **plano** precisar de decisão humana → sempre `stage:blocked` + `needs-human`; pare e pergunte. Não invente a decisão. (Não use `needs-plan`+`needs-human` para esse caso.)
7. **Não implementar** até `stage:approved` (**plan-approved**) **e** o usuário pedir implementar **e** escolher modo 1|2.
8. **Não** implementar em **guarda-chuva** — abrir filha Entrega (com intake).
9. **Não** pular **Casos de borda** + **Cenários TDD** (issue e plano). Se templates do repo faltarem, use skeletons em [`references/templates.md`](references/templates.md) ou `needs-human` — não afrouxar gates.
10. Exatamente uma `stage:*` na Entrega. Estado observável = **labels**, não comentários.

### Rationalizations → counter

| Rationalization | Counter |
| --- | --- |
| “Já sei, crio agora” | Sem perguntas + draft-approved → não cria. |
| “Cria genérica e ajeita depois” | Intake barato; issue rasa derruba B→C. |
| “Espera o user pedir o plano” | Sem opt-out, auto B→C após create. |
| “Só cria = não planeja implícito” | Opt-out tem que ser explícito. |
| “Eu reviso o plano do subagente” | Outro subagente; orquestrador só mapeia veredito literal. |
| “Review falhou, eu aprovo” | `blocked` + `needs-human`; nunca auto-APROVO. |
| “Sim no draft = pode implementar” | draft-approved ≠ plan-approved (`stage:approved`). |
| “Planner chuta produto” | `blocked` + `needs-human`. |
| “Implementa = modo implícito” | Um prompt: 1 worktree / 2 direto / depois. |
| “Mete na #1” | Filha + intake. |
| “Histórico/PR = approved” | Só `stage:approved` conta. |
| “Docs do repo sumiram, pulo EARS” | Use `references/templates.md` ou needs-human. |

### Red flags — pare e volte

- `gh issue create` sem intake + draft-approved
- Plano e review no mesmo subagente / orquestrador inventando APROVO
- Pedir OK humano entre plano postado e review (exceto opt-out “só cria”)
- Diff antes de plan-approved + pedido implementar + modo 1\|2
- Usar a frase “issue aprovada” sem draft-/plan-
- Tratar draft-approved como licença de código

## Quando carregar

1. [`references/issue-intake.md`](references/issue-intake.md)
2. [`references/templates.md`](references/templates.md) (skeleton se docs do repo faltarem)
3. `docs/context/ISSUES.md` + `docs/templates/implementation-plan.md` **se existirem**
4. [`references/stages.md`](references/stages.md)
5. [`references/review-contract.md`](references/review-contract.md)
6. [`references/implementation-modes.md`](references/implementation-modes.md)

## Máquina de estados

```text
intake → draft → draft-approved → create + stage:needs-plan
  ├─ opt-out "só cria, não planeja" → PARE em needs-plan
  └─ default → [subagente plano] → …
       ├─ precisa humano → blocked + needs-human (PARE)
       └─ plano postado → stage:in-review → [subagente review imediato]
            → APROVO / APROVO COM RESSALVAS → stage:approved (plan-approved)
            → PEÇO AJUSTES → needs-plan (ciclo k/3; no 3º → blocked + needs-human)
            → NÃO APROVO / review falhou → blocked + needs-human
approved → prompt único (1 worktree / 2 direto / depois)
  → 1|2 → in-progress → PR → fechar (limpar stage:* / needs-human)
```

## Procedimento

### A. Criar issue

[`references/issue-intake.md`](references/issue-intake.md). Após create + `needs-plan` → **B** (salvo opt-out).

### B. Plano (subagente)

Brief: URL/#N, corpo, template (`templates.md` ou repo), “poste comentário na issue; se faltar decisão humana, devolva a pergunta — não invente”.

- Bloqueio humano → orquestrador: `stage:blocked` + `needs-human`, comenta pergunta, **para**.
- Sucesso → `stage:in-review` + URL do comentário do plano → **C imediatamente** (passe a URL, não paráfrase).

### C. Review (subagente) — sem OK humano prévio

Brief: URL da issue + **URL/texto literal do comentário do plano** + `review-contract.md`.

| Veredito / resultado | Ação |
| --- | --- |
| APROVO / APROVO COM RESSALVAS | `stage:approved`; prompt único de implementação (ver D) |
| PEÇO AJUSTES | `stage:needs-plan`; `plan-review-cycle: k/3`; B→C |
| NÃO APROVO / bloqueante produto | `stage:blocked` + `needs-human` |
| Review vazio/erro/sem veredito | `stage:blocked` + `needs-human` (não aprove) |

### D. Implementação

Prompt único após plan-approved (também se o user disser “implementa” depois):

> Implementar a **#N** agora?  
> **1** — worktree isolada + subagente (padrão)  
> **2** — direto neste workspace  
> **depois** — manter `stage:approved`

Detalhe: [`references/implementation-modes.md`](references/implementation-modes.md).

### Issue já existente

Validar corpo/labels; incompleta → intake curto ou `needs-human`. Pedido “roda o fluxo” / sem opt-out em `needs-plan` → B→C. Guarda-chuva: não implementar; propor filha com intake.

## Output contract (cada turno)

1. **Issue** `#N` + URL (ou `intake`)  
2. **Stage** (`intake` \| `stage:…` \| + `needs-human`)  
3. **Ação** + se em loop: `plan-review-cycle: k/3`  
4. **Próximo passo**  
5. Se `needs-human` / intake / pós-approved: **pergunta com opções**

## Fora de escopo

- SPEC CASA completa (super-planning)
- Bugbot/security-review de PR
- Labels fora de `stage:*`, `needs-human`, tipos (`bug`/`enhancement`/…)
- Aplicar `stage:*` de entrega em Audit puro ou guarda-chuva (só Entrega/Bug com entrega)
