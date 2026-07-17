## Integração e fechamento

Agent: `delivery-reviewer`
Phase/scope: `auditoria final aplicável e fechamento`
Summary: `<resultado da auditoria final>`
Sources/evidence: `<envelope do executor, URLs de review, PR, range final e saída do DoD>`
Decisions: `<veredito literal da auditoria e decisão opcional de integração>`
Changes/validation: `<checagens da auditoria e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `<oferecer integração explícita | resolver achado | fechar, owner>`

### Resumo rápido

| Campo           | Valor                                                          |
| --------------- | -------------------------------------------------------------- |
| PR              | `<URL>`                                                        |
| Aprovação do PR | `approved \| pending \| not applicable`                        |
| Auditoria final | `APROVO \| APROVO COM RESSALVAS \| PEÇO AJUSTES \| NÃO APROVO` |

### Mapa de entrega

| Entrega        | Commit / PR | Evidência do executor | Review independente | Evidência DoD | Status |
| -------------- | ----------- | --------------------- | ------------------- | ------------- | ------ |
| Escopo autorizado |          |                       |                     |               |        |

### Definição de pronto

```text
<comando> — <resultado>
```

### Decisão opcional de integração

| Decisão    | Valor                                                                                     |
| ---------- | ----------------------------------------------------------------------------------------- |
| Integração | `Aguardar pedido explícito do usuário para merge \| merged em <commit> \| not applicable` |

---

_Processo: code-flow — evidência append-only pronta para PR (envelope de oito
campos). Nunca fazer merge automático após aprovação._
