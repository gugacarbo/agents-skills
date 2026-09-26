---
name: issue-dispatcher
description: "Triages requests and drafts issues using a basic, user-story, or Epic format. Use when creating, refining, or choosing a format for a work-tracking issue."
---

# Issue Dispatcher

Transforme o pedido do usuário em um contrato de trabalho claro para uma issue,
preservando a intenção e as decisões que ele já tomou. Investigue o contexto
disponível quando isso ajudar a distinguir fatos de suposições. Defina o
resultado observável, limites e critérios de aceite sem projetar a solução
técnica, a menos que o usuário peça isso.

## Escolha do modelo

Use o formato que o usuário pedir. Se não houver escolha explícita, recomende
um formato com base no escopo e explique a recomendação antes de tratar a
escolha como definitiva:

| Modelo                                      | Use quando                                                                                                                                                         |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [Issue simples](references/simple-issue.md) | Uma entrega delimitada, com contexto e resultado claros, sem precisar narrar uma persona ou coordenar várias entregas. É o padrão para trabalho pequeno ou direto. |
| [User story](references/user-story.md)      | A necessidade é melhor explicada pelo ponto de vista de uma pessoa usuária e pelo valor que ela obtém; critérios de aceite descrevem comportamento observável.     |
| [Epic](references/epic.md)                  | O objetivo precisa de várias entregas coordenadas, pode ser dividido em issues-filhas ou envolve dependências e marcos. A Epic acompanha o resultado agregado.     |

Se o usuário deixar a escolha em aberto e os sinais não apontarem claramente
para um modelo, pergunte qual prefere antes de finalizar a issue. Se ele
delegar explicitamente a escolha, escolha o formato mais simples que represente
com precisão o escopo e informe brevemente o motivo. Não transforme uma
recomendação em decisão aprovada.

## Fluxo

1. Extraia do pedido o problema ou oportunidade, o resultado desejado,
   restrições explícitas e qualquer formato já escolhido.
2. Consulte o contexto disponível (por exemplo, arquivos e convenções do
   projeto) para confirmar fatos úteis. Não trate inferências como decisões do
   usuário.
3. Escolha ou recomende o modelo conforme a tabela. Carregue somente a
   referência do modelo escolhido.
4. Redija a issue no idioma do usuário. Preserve termos, decisões, limites e
   relato original relevantes. Se uma informação necessária estiver ausente,
   faça uma pergunta objetiva ou marque-a como pendente; não invente resposta,
   escopo, prioridade, estimativa, responsável ou aceite.
5. Apresente o rascunho para revisão. Crie, publique ou altere uma issue remota
   somente quando o usuário tiver pedido essa ação; antes de publicar, mantenha
   as escolhas de conteúdo e modelo feitas pelo usuário. Se a escolha ainda
   depender de uma resposta, não publique.

## Limites de decisão

- Não substitua um formato, comportamento, critério de aceite ou limite
  explicitamente escolhido pelo usuário. Aponte conflitos e peça uma decisão
  quando não for possível preservar as escolhas simultaneamente.
- Não acrescente desenho técnico, plano de implementação, decomposição em
  sub-issues ou relações Epic sem necessidade para expressar o pedido ou sem
  autorização do usuário.
- Em trabalho de implementação, descreva o contrato e resultados verificáveis;
  não dite a solução técnica.
- Preserve o relato original quando houver valor em manter a formulação exata;
  organize os demais campos sem alterar seu sentido.
- Esta skill prepara e encaminha issues. Ela não inicia a implementação nem
  ativa o workflow `$code-flow` por conta própria.
