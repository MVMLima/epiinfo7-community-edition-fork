# Ferramentas usadas nos lotes de tradução

Scripts auxiliares (Windows PowerShell 5.1, ASCII puro). Os caminhos no topo de cada um apontam para a pasta
temporária da sessão em que foram usados: **ajuste `$repo` e `$sp` antes de rodar**.

| Script | Para quê |
|---|---|
| `dump_compact.ps1` | Divide os textos de um assembly em partes legíveis (`chave / EN / PT / alerta`) para revisão. Atenção: mostra quebras de linha como ` \n ` (com espaços; no original não há). |
| `Apply-Batch.ps1` | Aplica um TSV (`ConjuntoCurto<TAB>Chave<TAB>NovoTexto`) na planilha. Valida todas as chaves antes de gravar; aceita `=EN` (copia o original) e `\n` (quebra de linha); preserva o espaço inicial/final do original; marca `Status = Revisado`. `-WhatIf` só valida. |
| `make_about.ps1` | Gera a tradução dos créditos do "Sobre" a partir do original trocando só os títulos (pares em `about_repl.tsv`). |
| `promote.ps1` | Regenera as DLLs numa pasta temporária, compara com `Epi.Core/pt-BR`, substitui **só as DLLs que mudaram** e confere a planilha contra as DLLs oficiais (deve dar 0 divergências). |
| `module_test.ps1` | Abre um módulo do Epi Info em pt-BR numa **cópia isolada** de `build\Release` (UI Automation + captura de tela) e lista os textos visíveis. |

Processo de cada lote: ler tudo, verificar no código-fonte quais textos viram código/identificador, traduzir em TSV,
`Apply-Batch -WhatIf`, aplicar, validar, **2 revisores independentes** (verificar cada crítica no código), testar no app,
e só então (com aprovação) `promote.ps1` + commit.

Scripts do lote 4:

| Script | Para quê |
|---|---|
| `add_gap_rows.ps1` | Acrescenta à planilha textos que existem no `.resx` inglês mas **nunca tiveram tradução** (a planilha vem das DLLs pt-BR antigas e não os enxerga). Pega o inglês exato do `.resx` e o nome real do conjunto de recursos. Entrada: TSV `ConjuntoCurto<TAB>Chave<TAB>Portugues`. `-WhatIf` só mostra. |
| `resx_gap.ps1` | Compara todos os `.resx` do repositório com a planilha e lista o que falta. Atenção: há `.resx` obsoletos (ex.: `NewColunmNameDialog`, `RenameFormFromTemplateDialog`) que nao existem mais no binario; confira o nome contra `GetManifestResourceNames()` do `.exe`/`.dll` compilado antes de tratar como lacuna. |
| `menu_test.ps1` | Abre o MakeView na copia isolada `e2e_b4`, expande cada menu e salva capturas de tela. |
