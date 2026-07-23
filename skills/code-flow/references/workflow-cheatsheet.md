# Checklist do workflow

1. Confirme `code-flow:active` e exatamente um estado principal.
2. Antes de iniciar, recuse `needs-human` ou overlay já existente.
3. Publique início; depois adicione `stage:in-progress` preservando o principal.
4. Leia guidance e recalcule risco em toda retomada.
5. Publique resultado; depois conclua a transição e confirme labels.
6. Human gate sempre tem `needs-human`; atividade nunca tem.
7. Reviewer é independente e único; não existe auditoria.
8. Integrator distingue PR de NO_CHANGES e verifica rebase antes de fechar.
9. Falha parcial não é sucesso; registre reparo/Resume.
10. Stop limpa labels somente após handoff e preserva artefatos.
