# Complexidade e rigor adaptativo

Issue-writer propõe e persiste Complexity; risco decide gates e permanece
efêmero. Recalcule em criação, retomada, gates e mudança de base/escopo.

| Valor | Critério |
| --- | --- |
| S | Interna, localizada, reversível, caminho conhecido, uma área. |
| M | Um componente, poucas alterações acopladas, validação rotineira. |
| G | Vários componentes ou coordenação relevante em um repo. |
| X | Mudança ampla/transversal ou incerteza significativa. |
| XL | Múltiplos resultados/dependências; recomende decomposição/Epic. |

Mapeamento: `S → light`, `M/G → standard`, `X/XL → assured`. O nome interno
nunca é persistido. Comportamento observável em um componente começa em M até
discovery provar todos os critérios de S.

## Hard triggers

- autenticação, autorização, permissões, segredos ou fronteiras de confiança;
- migração de dados/esquema ou contrato público;
- conflito entre ADR/spec aceita, código e pedido;
- mudança cross-repo, irreversível ou de alto blast radius;
- operação destrutiva, acesso privilegiado ou rollback não demonstrado.

Urgência, diff pequeno, complexidade S ou aceite genérico de risco não removem
hard trigger.

## Papéis e gates

- Toda triagem exige gate humano.
- S sem hard trigger não exige arquitetura.
- M sem hard trigger usa architect, mas `not required` segue direto à execução.
- G+, hard trigger ou spec create/update exige gate humano de execução.
- Toda entrega exige uma única delivery review independente; não há auditoria.
- Diff aprovado exige gate humano de merge; NO_CHANGES não exige close gate.

Trocar nome/modelo ou sessão não apaga autoria. Reviewer não pode ter produzido
issue, arquitetura, código ou evidência revisada.

## Drift de base

Drift não material atualiza Base SHA e repete checks. Conflito ou mudança na
área, contrato ou dependência autorizada é material e exige nova delivery
review; risco/hard trigger novo retorna ao architect. Nunca confie apenas em
label ou aprovação anterior.
