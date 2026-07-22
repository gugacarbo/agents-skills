# Brainstorm pré-issue

Use apenas para decisão material de intenção, trade-off, sucesso ou escopo que
não seja descobrível no repositório. Não produz plano formal nem código.

Recapitule decisões e lacunas; ofereça aprofundar ou seguir. Ao fechar decisões
materiais, apresente o gate compartilhado com `Aprovar / Ajustar / Bloquear`:
aprovar mantém resultado efêmero para entrar no source-set futuro; ajustar
retoma apenas decisões indicadas; bloquear para sem criar issue, plano ou
código. Visual temporário nunca é fonte de verdade.

# Entrevista de intenção autocontida

Use quando uma decisão material não pode ser descoberta e pelo menos um item
abaixo está ausente ou contraditório:

- resultado desejado;
- usuário/beneficiário;
- motivo e urgência;
- sucesso observável;
- restrição vinculante;
- fora de escopo;
- trade-off ainda aberto.

## Loop

1. Mostre uma frase com sua leitura atual e liste somente as lacunas.
2. Faça uma pergunta material por vez. Quando houver opções reais, apresente
   2–3 alternativas com trade-offs e uma recomendação.
3. Atualize o resumo depois de cada resposta; não repita perguntas resolvidas.
4. Não pergunte fatos descobríveis no repo e não use percentual subjetivo de
   confiança.
5. Pare quando o checklist estiver completo ou quando a próxima pergunta não
   mudaria source-set, rigor, sucesso ou escopo.

## Saída

Apresente para confirmação:

```text
Resultado:
Usuário:
Por que agora:
Sucesso:
Restrição:
Fora de escopo:
Decisões e trade-offs:
Questões abertas: none | ...
```

O gate oferece `Aprovar`, `Ajustar` e `Bloquear`. Sem aprovação, não transforme
o resumo em source-set. Não encaminhe para skills externas nem crie documento
paralelo; a issue futura incorpora a decisão aprovada.
