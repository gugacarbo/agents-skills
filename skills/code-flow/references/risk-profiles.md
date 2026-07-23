# Complexidade e rigor adaptativo

Issue-writer propõe e persiste Complexity; risco decide gates e permanece
efêmero. Recalcule em criação, retomada, gates e mudança de base/escopo.

| Valor | Critério                                                         |
| ----- | ---------------------------------------------------------------- |
| XS    | Interna, localizada, reversível, caminho conhecido, uma área.    |
| S     | Um componente, poucas alterações acopladas, validação rotineira. |
| M     | Vários componentes ou coordenação relevante em um repo.          |
| L     | Mudança ampla/transversal ou incerteza significativa.            |
| XL    | Múltiplos resultados/dependências; recomende decomposição/Epic.  |

Mapeamento: `XS → light`, `S/M → standard`, `L/XL → secured`. O nome interno
nunca é persistido. Comportamento observável em um componente começa em S até
discovery provar todos os critérios de XS.

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
- XS sem hard trigger não exige arquitetura.
- S sem hard trigger usa architect, mas `not required` segue direto à execução.
- M+, hard trigger ou spec create/update exige gate humano de execução.
- Toda entrega exige uma única delivery review independente; não há auditoria.
- Diff aprovado exige gate humano de merge; NO_CHANGES não exige close gate.

Trocar nome/modelo ou sessão não apaga autoria. Reviewer não pode ter produzido
issue, arquitetura, código ou evidência revisada.

## Drift de base

Drift não material atualiza Base SHA e repete checks. Conflito ou mudança na
área, contrato ou dependência autorizada é material e exige nova delivery
review; risco/hard trigger novo retorna ao architect. Nunca confie apenas em
label ou aprovação anterior.
