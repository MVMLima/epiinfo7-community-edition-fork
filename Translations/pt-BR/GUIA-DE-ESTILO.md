# Guia de estilo da tradução pt-BR

Vale para todo texto novo ou revisado em `pt-BR.csv`. Os termos ficam no `glossario.csv`; este guia trata do resto.

## Regras

1. **Português do Brasil**, ortografia atual (Acordo de 1990). Nada de português de Portugal (*ficheiro, utilizador, guardar, ecrã, palavra-passe*) e nada de espanhol.
2. **Tratamento**: "você". Instruções no imperativo (*Selecione…, Digite…*); menus e botões no infinitivo (*Salvar, Abrir, Criar mapa*).
3. **Maiúsculas**: só a primeira palavra e nomes próprios (*Salvar como…*). Exceção: nomes dos módulos principais (*Criar Formulários, Inserir Dados, Analisar Dados, Criar Mapas, Painel Visual*). Listas que já estão em Title Case (nomes de comandos do Analysis, itens de menu de contexto) mantêm o padrão da própria lista, para não misturar estilos no mesmo menu.
4. **Teclas de atalho (`&`)**: em menus, botões e rótulos que têm `&` no original, mantenha **um** `&` antes de uma letra da palavra em português (`&Salvar`, `Arqui&vo`), sem repetir a mesma letra no mesmo menu/janela. `&&` significa um `&` literal.
5. **Variáveis e marcadores**: copie exatamente `{0}`, `{1:n0}`, `<variable>`, `\n`. Pode mudar a posição na frase, nunca omitir nem alterar.
6. **Nunca traduzir**:
   - nomes de produto: Epi Info, StatCalc, ActivEpi, OpenEpi, PHIN;
   - comandos, funções e palavras-chave da linguagem do Epi Info (READ, FREQ, ASSIGN, IF…), inclusive os argumentos entre aspas (`FORMAT( <variable>, "Currency" )`); o texto de dica que mostra a sintaxe fica idêntico ao original, com `<variable>`;
   - **textos que o programa usa como código, identificador ou chave de comparação**: são inseridos no programa do usuário, viram nome de coluna no banco ou são comparados com nomes de pasta/comando. **Devem ser idênticos ao original.** Exemplos já encontrados: os modelos de função `CNTXT_FXN_TMPLT_*` (`( <variable> )`), `UNIQUE_ROW_ID`, `GLOBAL_RECORD_ID`, `METADATA_PREFIX`, `WORD_ALL` (vira o argumento `ALL` do comando RELATE) e `PROJECTS/PAGES/FORMS/FIELDS` (comparados com as pastas de modelos). O validador acusa `CODIGO_ALTERADO`. Na dúvida, procure a chave em `SharedStrings.` no código-fonte antes de traduzir;
   - **mensagens do log de importação**: a janela de mensagens só lista linhas que contêm `:  Import` ou `:  Project` (inglês fixo no código) ou os prefixos traduzidos (Erro, Aviso, Observação). Uma mensagem que começava com "Import…" deve continuar começando com "Importação…". O validador acusa `FILTRO_LOG_IMPORT`;
   - nomes de arquivo e extensões (`.prj`, `.cvs7`), campos do sistema (`UniqueKey`, `GlobalRecordId`, `FKEY`) e siglas (ANOVA, CSV, SQL).
7. **Reticências**: um único caractere `…` em itens que abrem uma janela (*Salvar como…*).
8. **Pontuação e espaços**: mantenha os do original (dois-pontos de rótulo, ponto final de frase completa, espaço no fim do texto quando houver).
9. **Mensagens de erro**: diga o que aconteceu e, se souber, o que fazer. Prefira "Não foi possível abrir o arquivo." a "Erro abrindo arquivo".
10. **Tamanho**: os botões e telas têm largura fixa e o português costuma ser 20–30% mais longo. Rótulo curto deve ficar perto do tamanho do original (o alerta `LONGO` ajuda). Sempre confira no programa.
11. **Tradutor automático**: pode ajudar no rascunho, mas nunca cole texto direto da tela do tradutor (já houve "Detectar idioma / Traduzir texto" colado dentro de uma mensagem) e sempre releia o resultado.
12. **Termo novo**: se aparecer um termo técnico que não está no glossário, decida uma tradução, acrescente uma linha ao `glossario.csv` e use sempre a mesma.
13. **Status**: `Revisado` = alguém leu e corrigiu; `Aprovado` = revisão final (por profissional de saúde/epidemiologia).

## Decisões confirmadas (2026-09-23)

O glossário traz 94 termos. Estes 6 envolviam uma escolha real e foram **confirmados pelo responsável do projeto** aceitando a recomendação; todos estão como `Definido` no `glossario.csv`. Para mudar algum, edite a linha do glossário e retraduza os textos afetados.

| # | Termo | Hoje (antes da revisão) | Decisão | Alternativas / motivo |
|---|---|---|---|---|
| 1 | **Enter Data** (módulo) | Gravar Dados | **Inserir Dados** | *Digitar Dados*, *Entrada de Dados*. "Gravar" = salvar (sentido errado). Afeta o título do botão da tela inicial. |
| 2 | **Visual Dashboard** (módulo) | Painel de Análise (e "PANEL DE ANÁLISE" na tela inicial) | **Painel Visual** | Manter *Painel de Análise*. "Painel Visual" é a tradução fiel do nome do produto. |
| 3 | **view** (formulário de um projeto) | Visão | **formulário** | Manter *visão*. No Epi Info *view* e *form* são o mesmo objeto; "visão" soa estranho ("Este projeto não contém uma visão"). O menu *View* vira **Exibir**. |
| 4 | **gadget** (Painel Visual) | dispositivo | **gadget** | *componente*. "Dispositivo" sugere hardware. |
| 5 | **canvas** | canvas (11×) / tela (3×) | **canvas** | *tela*. Combina com o arquivo `.cvs7` e evita confusão com "tela" do computador. |
| 6 | **Browse** | Navegar | **Procurar…** | *Navegar*, *Examinar*. "Procurar…" é o padrão de botões de arquivo no Windows em português. |

Os demais termos foram definidos pelo uso brasileiro corrente ou pela maioria do que já existe (ex.: *salvar*, *excluir*, *banco de dados*, *coorte*, *qui-quadrado*, *razão de chances*, *risco relativo*, *pareado*). Se algum não combinar com o vocabulário da sua equipe, edite a linha no `glossario.csv`: o validador passa a usar a nova regra.
