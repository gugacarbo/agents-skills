# Complexidade e rigor adaptativo

O orquestrador propõe a complexidade no discovery, explica o racional e o
autor da issue a persiste. O usuário pode elevá-la. Complexidade mede
esforço/coordenação; risco decide gates e continua efêmero.

## Complexidade observável

| Valor | Critérios                                                                                                                           |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `S`   | Mudança interna e behavior-preserving, localizada, com caminho já conhecido, uma área, sem alterações acopladas e validação focada. |
| `M`   | Um componente, poucas alterações acopladas e validação rotineira.                                                                   |
| `G`   | Vários componentes ou coordenação relevante, ainda uma entrega em um repositório.                                                   |
| `X`   | Mudança ampla/transversal ou com incerteza significativa, ainda fechável como uma entrega.                                          |
| `XL`  | Múltiplos resultados/dependências ou coordenação excepcional; recomende decomposição/Epic.                                          |

Mapeamento inicial: `S → light`, `M/G → standard`, `X/XL → assured`. Esse
mapeamento nunca rebaixa os critérios abaixo.

Não presuma caminho conhecido só porque o pedido parece pequeno. Comportamento
observável em um componente, sem evidência de uma alteração única já
localizada, começa em `M`; discovery pode demonstrar que todos os critérios de
`S` estão presentes.

## Regra de risco

Recalcule em criação, retomada, antes de todo gate humano e quando base/escopo
mudar. O nível mais restritivo vence. O usuário pode pedir mais rigor; nunca
pode rebaixar hard trigger.

| Perfil interno | Critérios observáveis cumulativos                                                                                     |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| `light`        | S, interna, localizada, reversível, um repo, sem contrato observável, migração, permissão, segurança ou impacto spec. |
| `standard`     | M/G sem hard trigger; mudança observável ou transversal moderada, reversível e concentrada em um repo.                |
| `assured`      | X/XL ou qualquer hard trigger abaixo.                                                                                 |

O nome interno nunca aparece em body, label, comentário, template ou arquivo
de controle.

## Hard triggers

- autenticação, autorização, permissões, segredos ou fronteiras de confiança;
- migração de dados/esquema ou criação, alteração ou compatibilidade de
  contrato público;
- conflito entre ADR/spec aceita, código e pedido atual;
- mudança cross-repo, irreversível ou com alto blast radius;
- operação destrutiva, acesso privilegiado ou rollback não demonstrado.

Urgência, diff pequeno, complexidade S, reversibilidade alegada ou aceite
genérico de risco não removem hard trigger.

## Matriz de papéis e gates

| Capacidade  | S sem hard trigger           | M/G sem hard trigger                                                                                     | X/XL ou hard trigger                                            |
| ----------- | ---------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Issue       | orquestrador na issue mínima | `issue-writer`; issue escolada sem spec                                                                  | `issue-writer`; issue escolada sem spec                         |
| Arquitetura | não se aplica                | `architect` + relatório de arquitetura; gate humano só em `create/update` de spec ou Complexidade `>= G` | `architect` + relatório + gate humano obrigatório               |
| Execução    | ordem explícita + worktree   | ordem explícita + worktree                                                                               | ordem explícita + worktree                                      |
| Review      | `reviewer` fresco            | review independente; auditoria condicional                                                               | delivery review + auditoria final por instância fresca distinta |
| Merge/close | explícito                    | explícito                                                                                                | explícito                                                       |

Em M/G, o mesmo reviewer pode revisar a entrega se não escreveu
relatório de arquitetura/código. Em X/XL/hard trigger, reviewer e auditor final
são instâncias separadas. Migração exige rollback executável e evidência de
teste, simulação ou demonstração equivalente. O relatório de arquitetura
publicado vai direto à autorização humana de execução quando o gate se aplica,
sem reviewer exclusivo de arquitetura.

Sempre que reuso de reviewer for proposto, declare também essa fronteira:
reuso controlado vale somente para M/G e nunca permite corrigir o artefato que
será revisado; X/XL e hard trigger exigem separação por fase entre entrega e
auditoria. Trocar o nome do papel ou abrir outra sessão não apaga autoria e
nunca torna self-review independente.

Papéis e modelos são dimensões diferentes. Aplique
[`runtime-capabilities.md`](runtime-capabilities.md): use modelos distintos
quando o host permitir, mas nunca troque independência de instância por mera
troca de nome/modelo e nunca escreva configuração no repositório-alvo.

## Promoção e drift de base

Ao surgir risco novo ou mudança material no branch alvo:

1. pare antes de nova mutação;
2. registre o fato e o primeiro gate agora obrigatório;
3. descarte somente aprovações que não cobrem o novo escopo;
4. retome no relatório de arquitetura para `create/update` de spec ou hard trigger; caso contrário,
   na publicação do relatório e autorização de execução;
5. nunca continue porque stage/base anterior dizia `approved`.

Drift de base não material atualiza o base SHA e repete a validação planejada.
Conflito ou mudança na área autorizada é material.
