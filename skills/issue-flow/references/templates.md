# Skeletons — Entrega e plano

Usar quando `docs/context/ISSUES.md`, `docs/templates/implementation-plan.md`
ou `.github/ISSUE_TEMPLATE/entrega.yml` **não** existirem no branch. Preferir os
docs do repo quando existirem. **Não** afrouxar EARS/TDD porque o arquivo falta.

## Issue Entrega (corpo mínimo)

```markdown
## Em uma frase
…

## Problema hoje
…

## Se implementarmos
- Para o cliente/operador: …
- Para o negócio/ops: …
- Esforço: S / M / L
- Benefício principal: …

## Se NÃO implementarmos
- O que continua: …
- Risco: baixo / médio / alto — …
- Dá para viver sem? sim / não — …

## Casos de borda (obrigatório)
| # | QUANDO ⟨gatilho⟩ | o sistema DEVE ⟨resposta⟩ |
| --- | --- | --- |
| 1 | | |

## Cenários TDD (obrigatório)
| ID | Comportamento observável | Nível | Evidência |
| --- | --- | --- | --- |
| T1 | | unit / integração / e2e | RED → GREEN |

## Pronto quando
- [ ] Casos de borda 1–N exercitados
- [ ] Cenários T1–Tk verdes
- [ ] …

## Fora de escopo
- …

## Links
- SPEC / issue mãe / …
```

## Plano de implementação (comentário)

```markdown
## Plano de implementação
**Issue:** #N · **Esforço:** S/M/L

### Em uma frase
…
### Problema hoje
…
### Se implementarmos / Se NÃO
…
### Como vamos fazer
1. …
### Casos de borda (obrigatório)
| # | QUANDO | DEVE |
| --- | --- | --- |
| 1 | | |
### Cenários TDD (obrigatório)
| ID | Comportamento | Nível | Evidência |
| --- | --- | --- | --- |
| T1 | | | RED → GREEN |
### Pronto quando
- [ ] …
### Fora de escopo
- …
### Cuidados / riscos
- O que é / o que causa se ignorarmos / risco / tratamento
```
