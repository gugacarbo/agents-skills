# Companheiro visual

Companheiro de brainstorm visual no browser para mockups, diagramas e opções
durante o brainstorm aceito.

## Quando usar

Decida por pergunta, não por sessão. O teste: **o usuário entenderia melhor
vendo do que lendo?**

**Use o browser** quando o conteúdo for visual: mockups de UI, diagramas de
arquitetura, comparações lado a lado, polish de design, relações espaciais
renderizadas como diagrama.

**Use o terminal** quando for texto/tabela: requisitos e escopo, escolhas
conceituais A/B/C, listas de trade-off, decisões técnicas, perguntas cuja
resposta é palavras.

Uma pergunta sobre UI não é automaticamente visual. "Que tipo de wizard você
quer?" é conceitual — terminal. "Qual destes layouts de wizard parece certo?"
é visual — browser.

## Oferecer o companheiro

Não ofereça de antemão. Ofereça só quando a próxima pergunta for genuinamente
mais fácil de entender visualmente, em mensagem própria:

> "Esta próxima parte pode ficar mais fácil se eu mostrar — posso montar
> mockups, diagramas e comparações numa aba do browser. Sobe um servidor local
> temporário e pode ser intensivo em tokens. Quer que eu abra?"

Aguarde a resposta. Se recusar, continue só em texto e não ofereça de novo a
menos que o usuário peça. Antes de iniciar, avise que a sessão é temporária
fora do repositório e será removida no cleanup.

## Iniciar uma sessão

Só após aprovação:

```bash
scripts/visual-companion/start-server.sh --open
```

Requer Node.js. Se `node` não estiver disponível, siga só em texto.

O comando retorna JSON com `url` (incluindo `?key=...`), `session_dir`,
`screen_dir` e `state_dir`. Salve esses paths e compartilhe a URL completa.
Se o JSON não for capturado, leia `$STATE_DIR/server-info`.

## Loop

1. Confirme que o servidor está vivo antes de citar a URL ou empurrar uma tela.
2. Escreva um novo arquivo HTML em `screen_dir` (fragmentos por padrão; o frame template envolve automaticamente).
3. Diga o que está na tela e peça resposta no terminal.
4. No turno seguinte, leia `state_dir/events` se existir (JSONL) e una com o feedback do terminal.
5. Itere com arquivo novo a cada vez; nunca reutilize nomes.
6. Ao voltar a texto, empurre uma tela de espera para limpar visuais obsoletos.

Blocos disponíveis no frame: `.options` / `.option`, `.cards` / `.card`,
`.mockup`, `.split`, `.pros-cons`.

## Cleanup

Ao terminar o brainstorm, rode `stop-server.sh <session_dir>` para parar o
servidor e remover a sessão temporária.
