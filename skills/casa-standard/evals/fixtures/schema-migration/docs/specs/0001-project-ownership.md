---
status: accepted
date: 2026-08-20
builds-on: []
implemented-by: [schema/projects.sql]
---

# Exigir proprietário em todo projeto

## Contrato

Todo projeto criado ou persistido deve possuir `owner_id` válido. Persistir um
projeto sem proprietário é inválido.

## Definition of Done

```bash
npm test
```

## Verificação

Contrato aceito; o schema ainda precisa ser corrigido para aplicá-lo.
