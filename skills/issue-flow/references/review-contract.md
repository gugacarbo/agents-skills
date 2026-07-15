# Contrato do review de plano

O revisor **não** escreveu o plano. Ser adversário justo; não carimbar.
Receber a **URL ou texto literal** do comentário do plano (não resumo do orquestrador).

Comentar na issue em PT-BR:

```markdown
## Revisão do plano (visão produto)

**Veredito:** APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO

### Em uma frase
…

### O que o plano acertou
- …

### Ressalvas ou bloqueadores — o que significam na prática
Para cada item:
- **O que é:** …
- **O que causa se ignorarmos:** … (cliente / suporte / admin)
- **Risco:** baixo / médio / alto
- **Precisa corrigir antes de começar?** sim / não
- Se a correção exige **escolha de produto/acesso** → o veredito deve ser **NÃO APROVO** (não PEÇO AJUSTES)

Se não houver bloqueadores: “Nenhum bloqueador — pode seguir.”

### Tabelas EARS / TDD
- [ ] Casos de borda presentes e decididos
- [ ] Cenários T* cobrem os casos de borda
- Se faltar → **PEÇO AJUSTES** (não é nit)

### Impacto se aprovarmos e executarmos agora
…
### Impacto se deixarmos parado
…
### Recomendação para o owner
fazer agora / enfileirar / só depois de X

---
*Review independente — não autor do plano*
```

## Mapeamento veredito → stage

| Veredito | Stage |
| --- | --- |
| APROVO | `stage:approved` (plan-approved) |
| APROVO COM RESSALVAS | `stage:approved` (nits listados) |
| PEÇO AJUSTES | `stage:needs-plan` (+ ciclo k/3) |
| NÃO APROVO / decisão humana | `stage:blocked` + `needs-human` |

Orquestrador: só aplica o **veredito literal** do comentário. Sem veredito →
`blocked` + `needs-human`, nunca APROVO inventado.
