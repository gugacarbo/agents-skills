# Runtime, papéis e modelos

Papéis são contratos independentes; modelos são escolha efêmera do host. Não
crie `.codex/agents`, altere `config.toml` ou instale configuração no repo alvo.

| Papel        | Capacidade preferida                         |
| ------------ | -------------------------------------------- |
| issue-writer | Exploração e síntese rápidas.                |
| architect    | Maior capacidade de raciocínio disponível.   |
| executor     | Edição, testes e ferramentas.                |
| reviewer     | Revisão/raciocínio em instância sem autoria. |
| integrator   | Git, validação, rebase e recuperação segura. |

Configuração explícita do usuário vence preferências. Sem roteamento, use o
modelo herdado e preserve papéis por instâncias independentes. Sem paralelismo,
execute em sequência. Sem instância independente para review, pare e peça
revisão humana externa; nunca simule independência.

Nunca persista modelo, effort ou disponibilidade em body, labels ou arquivos do
repositório. O futuro runtime de VPS poderá adicionar leases; a skill atual
oferece somente sinalização cooperativa por `stage:in-progress`.
