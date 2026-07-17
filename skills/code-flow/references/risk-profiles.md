# Classificação adaptativa de risco

Classifique no início e em toda retomada. A classificação é efêmera: use-a
para escolher agentes e gates, mas nunca grave seu nome em labels, body,
comentários, templates ou arquivos de controle.

## Regra de decisão

O nível mais restritivo vence. O usuário pode pedir mais rigor; nunca pode
rebaixar um hard trigger. Mudança material de escopo invalida a classificação
anterior e exige nova avaliação antes de interpretar o stage.

Hard trigger nunca pode ser rebaixado.

| Perfil interno | Critérios observáveis cumulativos                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `light`        | Mudança interna, localizada, reversível, em um repositório, sem contrato observável, migração, permissão, segurança ou impacto de spec. |
| `standard`     | Default quando a mudança é observável ou transversal moderada, reversível e concentrada em um repositório, sem hard trigger.            |
| `assured`      | Qualquer hard trigger abaixo.                                                                                                           |

## Hard triggers

- autenticação, autorização, permissões, segredos ou fronteiras de confiança;
- migração de dados/esquema ou criação, alteração ou compatibilidade de
  contrato público;
- conflito entre ADR/spec aceita, código e pedido atual;
- mudança cross-repo, irreversível ou com alto blast radius;
- operação destrutiva, acesso privilegiado ou rollback não demonstrado.

Urgência, tamanho pequeno do diff, reversibilidade alegada ou aceite genérico
de risco não removem hard trigger.

## Matriz de papéis e gates

| Capacidade   | `light`                                                    | `standard`                                       | `assured`                                                        |
| ------------ | ---------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------- |
| Issue/source | `issue-writer`, racional no-spec, sem gate de fonte        | gate humano somente em `create`/`update`         | `issue-writer` + `issue-reviewer` + gate humano                  |
| Plano        | outline compacto pelo `executor`, sem review/gate de plano | `plan-writer` + `plan-reviewer` + gate humano    | mesmos papéis, sempre separados                                  |
| Execução     | ordem humana explícita; worktree automática                | ordem explícita + worktree                       | ordem explícita + worktree                                       |
| Review       | `delivery-reviewer` fresco                                 | review independente; auditoria final condicional | review independente + auditoria final por outra instância fresca |
| Merge        | explícito                                                  | explícito                                        | explícito                                                        |

Migração exige plano de rollback executável e evidência de teste, simulação ou
demonstração equivalente do rollback. Uma descrição sem prova não satisfaz a
auditoria do nível máximo.

No nível intermediário, o mesmo reviewer pode revisar plano e entrega somente
se não escreveu plano nem código. Ninguém revisa, aprova ou audita trabalho
próprio.

## Promoção

Ao surgir risco novo:

1. pare antes de nova mutação;
2. registre o fato e o primeiro gate agora obrigatório;
3. descarte apenas aprovações que não cobrem o escopo novo;
4. retome no source gate para `create`/`update` ou hard trigger; caso contrário,
   no gate de plano;
5. nunca continue porque o stage anterior dizia `approved`.
