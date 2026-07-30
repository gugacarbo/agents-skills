---
status: accepted
date: 2026-07-01
builds-on: []
superseded-by: null
---

# SQLite como armazenamento principal

## Contexto e problema

A aplicação precisa de armazenamento local transacional.

## Decisão

Usar SQLite como armazenamento principal.

## Confirmação

`npm test` deve passar usando SQLite.
