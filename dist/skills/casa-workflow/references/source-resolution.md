# Resolução da fonte CASA

Usar esta referência durante descoberta, adoção, upgrade ou divergência de versão.

## Autoridade canônica

O upstream oficial deste contrato é `https://github.com/atplus-digital/casa-standard`. Uma origem diferente só pode substituí-lo quando o próprio repo adotante a declarar explicitamente.

Não pesquisar nem usar App Defense Alliance, OWASP, ASA-WG ou qualquer outro padrão homônimo chamado CASA. Coincidência de sigla não é evidência de proveniência.

## Precedência

1. Localizar o `AGENTS.md` aplicável e eventuais instruções aninhadas.
2. Ler `casa-repo-id`, `casa-tier`, `casa-version` e `casa-standard-ref`.
3. Aplicar primeiro as instruções locais compatíveis com o contrato declarado.
4. Resolver o `STANDARD.md` oficial no `casa-standard-ref` pinado e carregar somente as seções pertinentes.
5. Tratar a toolchain local (`docs-check`, `docs-reserve`, `casa-init`) como implementação daquele snapshot e verificar divergências.
6. Consultar `main` e `CHANGELOG.md` somente para adoção ou aviso deliberado de upgrade.

Registrar no relatório os paths, refs e comandos realmente consultados. Não confundir o Standard vigente com o contrato prometido pelo repo.

## Regra de upgrade

A versão reportada pela toolchain local comprova no máximo uma divergência. Ela não comprova qual contrato oficial deve ser adotado nem fornece o `casa-standard-ref` correspondente.

Antes de propor a versão/ref alvo ou alterações em metadados e `docs-check`:

1. resolver o `STANDARD.md` oficial vigente e o `CHANGELOG.md` no upstream canônico;
2. identificar a versão alvo e o ref oficial correspondente;
3. separar o contrato declarado, a toolchain local e o alvo oficial confirmado no relatório.

Se as fontes oficiais não estiverem disponíveis, declarar versão/ref alvo como
não resolvidas. Não escolher a versão da toolchain como alvo por inferência nem
prometer quais arquivos serão alinhados. Se o envelope mutar documentos CASA,
manter o gate documental; sem escrita documental, não inventar gate.

Nomear literalmente `atplus-digital/casa-standard` no relatório. A branch
`main` serve para descobrir o estado vigente, mas não substitui um commit ou tag
como `casa-standard-ref` pinado. Sem ref exato confirmado, manter o alvo
parcialmente não resolvido.

## Estados observáveis

- **Adotante válido:** metadados presentes e ref resolvível. Aplicar o contrato pinado.
- **Metadados/toolchain divergentes:** reportar a divergência e seu sentido; não alterar `casa-version` automaticamente nem inferir dela o alvo do upgrade.
- **Ref indisponível:** declarar a incerteza e usar metadados e toolchain locais como evidência limitada; gate somente se houver mutação documental CASA.
- **Não adotante:** não inferir regras CASA para trabalho comum. Em adoção, pedir gate antes de `casa-init` quando ele criar ou atualizar documentos CASA; auditoria read-only não aciona gate.
- **Contrato local incompleto:** tratar como achado, não preencher lacunas com a versão mais recente.

## Limites

- Não embutir nem reconstruir o Standard.
- Não reproduzir manualmente arquivos instalados por `casa-init`.
- Não usar `dist/` ou outro artefato gerado como fonte quando o repo o proibir.
- Não fazer rede no gate automatizado do repo; consulta remota durante análise é evidência separada.
