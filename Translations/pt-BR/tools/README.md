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

Lote 5: **`gap_binary.ps1`** substitui `resx_gap.ps1` como metodo confiavel de achar lacunas: le os conjuntos de recursos
do binario compilado (`-Exe`), compara com a planilha e mostra o que falta (`-Alias` liga o nome do conjunto ao nome
do `.resx` quando diferem). `add_rows_from_gap.ps1` acrescenta as linhas usando esse arquivo (ingles exato + nome real
do conjunto): TSV `NomeCompletoDoConjunto<TAB>Chave<TAB>Portugues`.

Lote 6: `gen_rules.ps1` gera as linhas repetitivas (OK, Ajuda, Somente salvar, Limpar, Procurar..., Funcoes, Variaveis disponiveis) a
partir de `rules_standard_buttons.txt` (EN<TAB>PT) e das regras de codigo do Analysis (And/Or, ToolTipText do AssignDialog),
pulando as chaves que ja estao nos TSV manuais. `check_mnemonics.ps1 -Assembly X` lista teclas de atalho (&) repetidas na mesma
janela (menus e barras diferentes da mesma tela aparecem como falsos positivos). `dlg_test.ps1` abre o Analysis na copia isolada
e da duplo clique em nos da arvore (coordenadas de tela) para fotografar dialogos; varios dialogos exigem uma fonte de dados aberta.

Lote 7: `sim_filter.ps1` simula o filtro de `ImportMessagesDialog` (ingles x portugues) sobre as mensagens do `Epi.ImportExport` e lista as que
passam a sumir ou a aparecer na lista de mensagens da importacao.

Lote de codigo: `add_code_strings.ps1` cria chaves novas para textos que estavam fixos em ingles no codigo (grava o `<data>` no `.resx`
ingles, o acessor no `.Designer.cs` e a linha na planilha; alvos Core/Menu/StatCalc/Dashboard; TSV `Alvo<TAB>CHAVE<TAB>Ingles<TAB>Portugues`).
`code_replace.ps1` troca o literal no `.cs` pela chave (`Arquivo<TAB>Antigo<TAB>Novo<TAB>N`, `\q` = aspas; confere N ocorrencias; preserva BOM/CRLF).
Depois: compilar (`MSBuild "Epi Info 7.sln" /p:Configuration=Release`, no PowerShell) e conferir as chaves por reflexao em PowerShell de 32 bits
(o Epi.Core e x86; `C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe`).
