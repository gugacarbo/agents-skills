# <Título da entrega>

| Campo      | Valor                                   |
| ---------- | --------------------------------------- |
| **Tipo**   | Issue de entrega / bug                  |
| **Owner**  | <time ou pessoa>                        |
| **Status** | <rascunho \| em andamento \| concluída> |

---

## User story

Como `<usuário ou papel>`, quero `<capacidade>` para `<valor observável>`.

## Resultado e critérios de aceite

| Campo           | Conteúdo                                  |
| --------------- | ----------------------------------------- |
| **Resultado**   | <um resultado independentemente fechável> |
| **Verificação** | <teste, comando, walkthrough ou métrica>  |

**Critérios de aceite**

- <comportamento observável ou condição no estilo EARS>
- <comportamento observável ou condição no estilo EARS>

## Escopo

| Limite                      | Conteúdo                          |
| --------------------------- | --------------------------------- |
| **Dentro**                  | <comportamento incluído>          |
| **Fora**                    | <exclusões explícitas>            |
| **Dependências / decisões** | <issue, ADR/spec, acesso ou none> |

## Relação de entrega

| Campo                  | Valor                                             |
| ---------------------- | ------------------------------------------------- |
| **Epic**               | #<n> ou `none`                                    |
| **Relação no GitHub:** | `subissue of #<n>` ou `standalone delivery issue` |

**Regras desta issue**

Esta é uma issue elegível de entrega/bug. Aplicar `stage:*`, aprovação do
source-set, plano, execução, review e fechamento apenas aqui. Manter a
implementação dentro do plano aprovado desta issue como uma unidade do executor;
criar outra issue filha só para um resultado de entrega independentemente fechável.
