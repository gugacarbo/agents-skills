# Implementação: worktree vs direta

Só após **plan-approved** (`stage:approved`). Prompt único (não pergunte duas vezes):

> Implementar a **#N** agora?  
> **1** — worktree isolada + subagente (padrão)  
> **2** — direto neste workspace  
> **depois** — manter `stage:approved` sem código

Sem **1** ou **2**, não comece código. Enquanto aguarda: `stage:approved` +
`needs-human`. Ao escolher 1|2: remover `needs-human` → `stage:in-progress`.

## Opção 1 — Worktree + subagente (padrão)

1. `git worktree add` + branch `issue-N-…` a partir da base combinada.
2. Dispatch subagente **novo** (`generalPurpose` / equivalente) com
   `working_directory` = path absoluto da worktree, mais: URL da issue, plano
   aprovado (URL do comentário), DoD/EARS/T*, “um PR ≈ issue”.
3. Orquestrador **não** edita código no workspace principal (só labels/comentários GH).
4. PR aponta para a issue; orquestrador confere DoD/labels.

**Não** use `best-of-n-runner` como default de implementação (é para experimentos
N-way). Só se o usuário pedir BoN explicitamente.

## Opção 2 — Direto neste workspace

1. Confirmar risco de misturar com mudanças locais.
2. Preferir subagente novo mesmo assim (sem worktree).
3. PR ≈ issue; mesmo DoD.

## Proibições

- Não defaultar para direto em silêncio.
- Não começar diff antes de **1** ou **2**.
- draft-approved ≠ permissão para este passo.
