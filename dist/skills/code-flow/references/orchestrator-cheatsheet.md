# Cheatsheet do orquestrador

1. Faça discovery e recalcule Complexity/risco.
2. Conte `stage:*`: um é fallback; zero exige mapeamento nativo; múltiplos são
   drift bloqueante.
3. Se native passar, use-o automaticamente nesta entrada; se falhar em issue
   nova, inicie fallback equivalente; se falhar em header legado native, pause
   para decisão humana.
4. Valide source-set, base e autoria antes de despachar.
5. Evidência precede mutação; agente muta o próprio resultado e orquestrador
   muta decisão humana.

## Check rápido

- Header legado foi tratado como compatibilidade, não como estado autoritativo?
- Source-set digest foi calculado somente entre marcadores?
- Hard trigger, escopo ou base mudaram desde o último gate?
- Próximo ator é humano? Só então `needs-human` pode existir.
- `NO_CHANGES` usa close gate, nunca merge gate.
- Em batch, cada ID permanece independente e `--from` não pula gates.
