# Runtime, agentes e modelos

Use este contrato antes de qualquer dispatch. Ele roteia capacidades sem criar
`.codex/agents`, alterar `config.toml` ou instalar configuração no repositório.

## Descoberta read-only

1. Verifique se o host oferece subagentes e quantas instâncias independentes
   podem executar.
2. Verifique se o spawn aceita modelo/effort explícito ou custom agents já
   configurados pelo usuário.
3. Registre na resposta operacional: papéis, independência disponível, modelo
   escolhido quando observável e fallback aplicado.
4. Não pergunte por modelo quando só houver uma opção utilizável.

## Roteamento por capacidade

| Papel            | Capacidade preferida                                            |
| ---------------- | --------------------------------------------------------------- |
| issue-writer     | Modelo rápido/generalista com boa exploração e síntese.         |
| architect        | Modelo de maior capacidade de raciocínio disponível.            |
| executor         | Modelo forte em edição, testes e uso de ferramentas.            |
| reviewer/auditor | Modelo forte em raciocínio e revisão, em instância sem autoria. |

Use nomes de modelo apenas quando o host os expuser. Configuração explícita do
usuário vence preferências. Não invente disponibilidade, custo ou suporte.

## Fallback obrigatório

- Sem roteamento por modelo: use o modelo herdado e preserve papéis por
  instâncias independentes.
- Sem paralelismo: execute papéis independentes em sequência.
- Sem qualquer instância independente: não simule independência. Pare no gate de
  review/auditoria e peça uma instância ou revisão humana externa.
- X/XL ou hard trigger exige instância fresca para auditoria; modelo diferente é
  preferível, mas indisponibilidade de outro modelo não autoriza self-review.

Modelos, effort e disponibilidade são estado efêmero do runtime. Nunca os
persista no body da issue, labels ou arquivos do repositório-alvo.
