---
name: casa-workflow
description: Classifica tier, artefatos, gates e contexto durável em repositórios CASA. Use quando o usuário invocar $casa-workflow, mencionar CASA, casa-init ou docs-check, pedir adoção/upgrade, alterar ADR, Spec ou contexto, fechar Spec ou implementar em repo com metadados CASA. Não use em repo não CASA ou explicação genérica.
---

# CASA Workflow

## Ativação

Antes de escrever, leia o `AGENTS.md` e procure:

```yaml
casa-repo-id: <id-do-repositório>
casa-tier: <T0|T1>
casa-version: <versão>
casa-standard-ref: <ref>
```

- Nenhum metadado CASA e sem pedido de adoção, upgrade ou auditoria: devolva a
  tarefa ao fluxo original, sem gate.
- Metadados completos ou parciais, ou pedido de adoção, upgrade ou auditoria:
  leia [workflow.md](references/workflow.md) por completo.

## Cinco classificações

Classifique nesta ordem:

1. `artifact_action`: criar, atualizar, depreciar, dispensar ou sugerir;
2. `context_suggestion`: intenção durável inferida ou nenhuma;
3. `authorization_basis`: ação documental pedida diretamente, inferida ou fora
   do escopo autorizado;
4. `gate_required`: derivado das classificações anteriores;
5. `gate_bypass`: explícito, persistente ou nenhum.

Em T0, não exija ADR, Spec nem `docs/context/`: use somente `AGENTS.md`, DoD e
sugestões para o router raiz ou aninhado. Em T1, classifique artefatos conforme
[impact-lifecycle.md](references/impact-lifecycle.md).

Leia [context-persistence.md](references/context-persistence.md) para regra
durável, comando canônico, estado operacional ou gotcha recorrente.

## Threshold do gate

`gate_required=true` somente para mutação documental CASA inferida, não pedida,
fora do escopo autorizado ou dependente de decisão ainda aberta. Upgrade ou
adoção com alvo móvel/não resolvido (“mais recente”) fica aberto até definir
versão, ref e source-set exatos.
`gate_required=false` quando o usuário pedir diretamente criar, atualizar,
depreciar ou fechar o artefato com escopo semântico identificável, e quando não
houver escrita documental: código, teste, schema, migração, auditoria read-only e sugestão.

Autorizações comuns de segurança, dados, operação destrutiva ou efeito remoto
continuam válidas, mas não se tornam gate CASA sem mutação documental. Um gate cobre todo o envelope documental aprovado.
Classifique documentos primeiro; tamanho, risco, schema e migration não definem
ADR nem gate. Autorização direta não permite editar corpo de ADR aceita, fechar
Spec sem evidência ou executar efeito remoto não autorizado.

## Gate e bypass

`gate_bypass=explicit` quando o usuário pedir auto-approve, bypass
ou aprovação antecipada dos gates CASA. `gate_bypass=persistent` quando um
`AGENTS.md` aplicável contiver exatamente `<!-- casa-gates: bypass -->`.
“Ativar no projeto” grava o marker no router raiz.

Com bypass, não emita relatório nem peça confirmação: resolva o source-set e
execute a mutação CASA requerida pela tarefa. O bypass não muda classificação,
escopo, imutabilidade de ADR aceita, evidência de fechamento nem autorizações
externas. Em T1, crie ADR/Spec obrigatória antes do código mesmo sob bypass.
Sem bypass, aprovação válida ainda exige relatório no turno anterior
e resposta `Aprovar`; `Ajustar` refaz o relatório e `Bloquear` não escreve.
