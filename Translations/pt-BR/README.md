# Tradução pt-BR do Epi Info

Até aqui a tradução para português existia **somente como DLLs compiladas** (`Epi.Core/pt-BR/*.resources.dll`), sem nenhum arquivo-fonte, e por isso ninguém conseguia corrigir uma frase. Esta pasta passa a ser a **fonte editável**: uma planilha com todos os textos, um glossário, e scripts que geram as DLLs a partir da planilha.

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| `pt-BR.csv` | **Fonte da tradução.** Uma linha por texto (4.621). Abra no Excel e edite a coluna `Portuguese`. |
| `glossario.csv` | Termos oficiais (94) com a forma preferida e as variantes a evitar. Usado pelo validador. |
| `GUIA-DE-ESTILO.md` | Regras de redação e as 6 decisões de vocabulário já confirmadas. |
| `Build-PtBrResources.ps1` | Gera as DLLs `Epi.Core/pt-BR/*.resources.dll` a partir de `pt-BR.csv`. |
| `Test-PtBrTranslation.ps1` | Valida a planilha e preenche a coluna `Alerta`. |
| `Export-PtBrCsv.ps1` | Faz o caminho inverso (DLLs → planilha). Serve para sincronizar com textos novos do código. |

## Colunas de `pt-BR.csv`

`Assembly ; ResourceSet ; Key ; English ; Portuguese ; Alerta ; Status`

- **Assembly / ResourceSet / Key**: identificam o texto no programa. **Não altere.**
- **English**: original (referência, não é usado pelo programa).
- **Portuguese**: **a única coluna que você edita.**
- **Alerta**: preenchida pelo validador (ver abaixo). Não edite à mão.
- **Status**: vazio = não revisado; `Revisado`; `Aprovado`. Linhas `Aprovado` deixam de ser questionadas pelo validador.

## Como editar no Excel

1. Abra o `pt-BR.csv` (Dados > De Texto/CSV, codificação **UTF-8**, delimitador **ponto e vírgula**), ou clique duas vezes se os acentos aparecerem certos.
2. Filtre a coluna `Alerta` para trabalhar por tipo de problema (ex.: `ESPANHOL`).
3. Edite só `Portuguese` (quebra de linha dentro da célula: Alt+Enter).
4. Salve como **CSV UTF-8 (delimitado por vírgulas)**. No Excel em português o separador gravado é `;`, que é o esperado.

Regras que o programa depende de você respeitar (detalhes no guia de estilo):

- Mantenha as variáveis exatamente como no original: `{0}`, `{1}`, `{0:n0}`, `<variable>`.
- Mantenha um `&` antes de uma letra do texto de menus e botões (`&Salvar`): é a tecla de atalho Alt+letra.
- Não traduza comandos e sintaxe da linguagem do Epi Info (`FORMAT( <variable>, "Currency" )`).

## Validar

```powershell
cd Translations\pt-BR
.\Test-PtBrTranslation.ps1                       # resumo por tipo de alerta
.\Test-PtBrTranslation.ps1 -Show ESPANHOL -Limit 20   # exemplos de um alerta
.\Test-PtBrTranslation.ps1 -WriteAlerts           # grava a coluna Alerta na planilha
```

Alertas: `VAZIO`, `NAO_TRADUZIDO`, `ESPANHOL`, `PT_PT` (português de Portugal), `LIXO_COLADO` (restos de tradutor web), `PLACEHOLDER` (`{n}` diferente), `ANGULAR` (`<x>` perdido), `ATALHO_PERDIDO`, `ESPACOS`, `PONTUACAO`, `LONGO` (risco de cortar na tela), `CODIGO_ALTERADO` (texto que o programa usa como código/identificador e que deve ficar idêntico ao original), `FILTRO_LOG_IMPORT` (mensagem de importação que deixou de aparecer na lista do log) e `GLOSS:<termo>` (usa variante marcada como "Evitar" no glossário). São **avisos** para triagem, não sentenças: um alerta pode ser falso positivo, e a ausência de alerta não garante que o texto está certo.

## Gerar as DLLs e testar

```powershell
cd Translations\pt-BR
.\Build-PtBrResources.ps1      # grava Epi.Core\pt-BR\*.resources.dll
```

Depois é só compilar a solução normalmente (o `Epi.Core.csproj` já copia `Epi.Core/pt-BR/` para `build\Release\pt-BR`). O script **recusa gerar** se a planilha tiver chave duplicada ou coluna-chave vazia, e só grava as DLLs se todas forem geradas com sucesso.

Para ver no programa: em *Opções* escolha o idioma português, ou edite `<Language>pt-BR</Language>` em `Configuration\EpiInfo.Config.xml`. **Teste sempre numa cópia isolada do build**, não dentro de `build\Release` (o programa grava configuração local ali, e esse arquivo nunca pode entrar no pacote distribuído; foi o que quebrou a v5).

Requisitos: Windows PowerShell 5.1 e o `al.exe` do .NET Framework SDK (já presente no Visual Studio Build Tools instalado para compilar o projeto).

## Verificação feita na criação (2026-09-23)

- Exportação das 4.621 strings das DLLs originais e regeneração das DLLs a partir da planilha: **0 diferenças** (comparação exata de todas as entradas, inclusive quebras de linha), mesma identidade de assembly (nome, versão 7.2.6.2, cultura pt-BR).
- Teste ponta a ponta: alterando um texto na planilha, regenerando e abrindo o programa em pt-BR, a alteração aparece na tela.
- As DLLs em `Epi.Core/pt-BR/` só são substituídas quando a tradução de fato muda. Até agora: **`Menu.resources.dll`** (lote 1) e **`Epi.Core.resources.dll`** (lote 2, `Epi.SharedStrings`), ambos em 2026-09-23. As demais ainda são as originais.

## Estado inicial da tradução (medido em 2026-09-23, por heurística)

Dos 4.621 textos, **1.797 têm algum alerta** (não significa que os outros 2.824 estejam corretos; erros de sentido e de ortografia, como "Opcões", não são detectados):

| Alerta | Textos | Comentário |
|---|---|---|
| `ATALHO_PERDIDO` | 580 | Menus e botões sem tecla de atalho Alt+letra. |
| `GLOSS:*` | 489 | Variantes fora do glossário (ex.: "visão" para *view*, "variable", "Apagar" vs "Excluir"). |
| `NAO_TRADUZIDO` | 365 | Idêntico ao inglês (inclui alguns termos que podem ficar em inglês). |
| `ESPANHOL` | 344 | Cerca de 7% da tradução está em espanhol. Concentrado em `DashboardSharedStrings` (152, o Painel Visual quase todo) e `Epi.SharedStrings` (33), além de diálogos de importação/publicação web. |
| `PONTUACAO` | 120 | `:`, reticências ou ponto final diferentes do original. |
| `LONGO` | 99 | Português bem maior que o original (risco de cortar na tela). |
| `ANGULAR` | 64 | `<variable>` apagado em textos de sintaxe. |
| `ESPACOS` | 46 | Espaço no início/fim diferente do original. |
| `PT_PT` | 33 | Português de Portugal (ex.: "Guardar"). |
| `PLACEHOLDER` | 13 | `{0}` perdido ou quebrado. |
| `LIXO_COLADO` | 1 | Texto do tradutor web colado dentro da tradução. |

**Regressão do rodapé (nossa, da v4):** na versão em inglês o rodapé do menu passou a dizer "GITHUB" / "VERSÃO MANTIDA POR MVML", mas o pt-BR nunca foi atualizado e continua "PÁGINA WEB DO EPI INFO™" / "SOBRE O EPI INFO™". Em português o texto do link não corresponde ao destino (GitHub do fork). As chaves são `MENU_FOOTER_EPIINFOWEBSITE` e `MENU_FOOTER_ABOUTEPIINFO` em `MenuSharedStrings`.

Também há textos com **sentido errado** que nenhuma regra automática detecta (ex.: a mensagem de erro de chave de criptografia traduzida como outra frase; "Close" traduzido como "Cancelar"). Esses só aparecem na revisão humana.
