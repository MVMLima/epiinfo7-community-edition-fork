<#
.SYNOPSIS
  Validador da traducao pt-BR (pt-BR.csv): aponta problemas tipicos e violacoes do glossario.

.DESCRIPTION
  Apenas le a planilha (nao altera as DLLs). Com -WriteAlerts grava os alertas na coluna "Alerta" da propria
  planilha, o que permite filtrar no Excel. Linhas com Status = "Aprovado" sao puladas (revisao humana vence).

  Alertas:
    VAZIO            Portugues vazio onde o ingles tem texto
    NAO_TRADUZIDO    Portugues identico ao ingles
    ESPANHOL         palavras/acentuacao do espanhol
    PT_PT            portugues de Portugal (ficheiro, utilizador, guardar...)
    LIXO_COLADO      restos de tradutor web colados no texto
    PLACEHOLDER      variaveis {0}, {1}... diferentes do original
    ANGULAR          marcador <nome> do original perdido (sintaxe de comandos)
    ATALHO_PERDIDO   o original tem tecla de atalho (&Letra) e o portugues nao
    ESPACOS          espaco no inicio/fim diferente do original
    PONTUACAO        ':' / '...' / ponto final divergente do original
    LONGO            portugues muito maior que o original (risco de cortar na tela)
    CODIGO_ALTERADO  texto que vira codigo/identificador difere do original (quebra o programa)
    FILTRO_LOG_IMPORT mensagem de importacao que sumiria da lista do log (filtro em ingles no codigo)
    GLOSS:<termo>    usa variante marcada como "Evitar" no glossario.csv

  IMPORTANTE: este script e ASCII puro de proposito (Windows PowerShell 5.1 le .ps1 sem BOM como ANSI).
#>
[CmdletBinding()]
param(
    [string]$Csv      = (Join-Path $PSScriptRoot 'pt-BR.csv'),
    [string]$Glossary = (Join-Path $PSScriptRoot 'glossario.csv'),
    [switch]$WriteAlerts,
    [string]$Show,
    [int]$Limit = 10
)
$ErrorActionPreference = 'Stop'

function Read-Table([string]$path) {
    $first = Get-Content -Path $path -TotalCount 1 -Encoding UTF8
    $d = if ($first -match ';') { ';' } else { ',' }
    return @(Import-Csv -Path $path -Delimiter $d -Encoding UTF8)
}
function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }

$rows = Read-Table $Csv
$gloss = @()
if (Test-Path $Glossary) { $gloss = @(Read-Table $Glossary | Where-Object { $_.Evitar }) }

$reEs  = '(?i)\b(los|las|del|una|unos|unas|el|muestra|archivos?|seleccione|seleccionar|ayuda|tablas?|paquetes?|proyectos?|formularios?|datos|haga|aseg[u\xFA]rese|est[a\xE1]n|puede|pueden|se (puede|han|ha|debe)|para (el|la|los|las)|con (el|la|los)|de (la|los|las)|que se|l[i\xED]nea|cerrar|lenguaje|versi[o\xF3]n|configuraci[o\xF3]n)\b|[\xF1\xBF\xA1]|\w+ci\xF3n\b|\w+si\xF3n\b'
$rePt  = '(?i)\b(ficheiros?|utilizador(es)?|ecr[a\xE3]s?|guardar|guarde|guardado|introduz\w*|palavra-passe|registos?|separadores?|defini\xE7\xF5es|liga\xE7\xE3o|liga\xE7\xF5es|telem\xF3vel|actualiz\w+|equipa)\b'
$reJunk = '(?i)Detectar idioma|Traduzir texto|Traduzir do|espanholingl|Google Tradutor'
$allowSame = '^(Epi Info.*|StatCalc|OpenEpi.*|ActivEpi.*|PHIN.*|OK|CSV|SQL|ANOVA|XML|HTML|GUID|URL|ID|Menu|menuStrip[0-9]*|ActivEpi.com|OpenEpi.com|Microsoft (Excel|Word)|Mantel-Haenszel|Total|Classes:?|Shapefile:?)$'

function Get-Indexes([string]$s) { (([regex]::Matches($s, '\{(\d+)(?::[^}]*)?\}') | ForEach-Object { $_.Groups[1].Value } | Sort-Object) -join ',') }
function Get-Angles([string]$s)  { @([regex]::Matches($s, '<[A-Za-z_][A-Za-z_ ]*>') | ForEach-Object { $_.Value }) }

$flagCount = @{}
$examples  = @{}
$flagged = 0
foreach ($r in $rows) {
    $flags = New-Object System.Collections.Generic.List[string]
    if ($r.Status -ne 'Aprovado' -and $r.English) {
        $en = [string]$r.English; $pt = [string]$r.Portuguese
        $letters = ($en -match '[A-Za-z]{3}')
        if ($letters -and [string]::IsNullOrWhiteSpace($pt)) { $flags.Add('VAZIO') }
        if ($pt) {
            # chaves cujo texto vira codigo/identificador (coluna do banco, sintaxe inserida no programa do usuario):
            # devem ser IDENTICAS ao original; alterar quebra o programa (ex.: UNIQUE_ROW_ID era 'IdUniqueLigne')
            # WORD_ALL vira o argumento ALL do comando RELATE; PROJECTS/PAGES/FORMS/FIELDS sao comparados com o
            # nome das pastas de modelos no disco (EndsWith); os demais sao nomes de coluna/sintaxe.
            $isCodeKey = ($r.Key -match '^(UNIQUE_ROW_ID|UNIQUE_RECORD_ID|GLOBAL_RECORD_ID|METADATA_PREFIX|OUTPUT_TABLE_NAME_COMMAND|MYSQL_DATABASE_INFO|MONGODB_DATABASE_INFO|WORD_ALL|PROJECTS|PAGES|FORMS|FIELDS|CNTXT_FXN_DATFX_TMPLT[0-9]*|CNTXT_FXN_TMPLT_.*)$')
            if ($isCodeKey -and ($pt -cne $en)) { $flags.Add('CODIGO_ALTERADO') }
            # o dialogo de mensagens da importacao so lista linhas que contem ':  Import' / ':  Project' (ingles fixo no
            # codigo) ou os prefixos traduzidos; mensagem que comecava com 'Import' e deixa de comecar com 'Import' some da lista
            if ($r.Key -like 'IMPORT_*' -and $en -cmatch '^Import' -and $pt -cnotmatch '^Import') { $flags.Add('FILTRO_LOG_IMPORT') }
            if (-not $isCodeKey -and $letters -and $en.Length -ge 4 -and ($en -ceq $pt) -and $en -cmatch '[a-z]' -and $en -notmatch $allowSame -and $en -notmatch '^\s*[A-Z_]+\s*\(' ) { $flags.Add('NAO_TRADUZIDO') }
            if ($pt -cne $en -and $pt -match $reEs) { $flags.Add('ESPANHOL') }
            if ($pt -match $rePt) { $flags.Add('PT_PT') }
            if ($pt -match $reJunk) { $flags.Add('LIXO_COLADO') }
            if ((Get-Indexes $en) -ne (Get-Indexes $pt)) { $flags.Add('PLACEHOLDER') }
            foreach ($a in (Get-Angles $en)) { if (-not $pt.Contains($a)) { $flags.Add('ANGULAR'); break } }
            # '&&' e um '&' literal (nao e tecla de atalho): remove antes de procurar '&Letra'
            $enAcc = $en -replace '&&', ''; $ptAcc = $pt -replace '&&', ''
            if ($enAcc -match '&[A-Za-z0-9]' -and $ptAcc -notmatch '&[A-Za-z0-9]') { $flags.Add('ATALHO_PERDIDO') }
            $enLead = [bool]($en -match '^\s'); $ptLead = [bool]($pt -match '^\s')
            $enTrail = [bool]($en -match '\s$'); $ptTrail = [bool]($pt -match '\s$')
            if (($enLead -ne $ptLead) -or ($enTrail -ne $ptTrail)) { $flags.Add('ESPACOS') }
            $enT = $en.TrimEnd(); $ptT = $pt.TrimEnd()
            $enColon = $enT.EndsWith(':'); $ptColon = $ptT.EndsWith(':')
            $enDots  = $enT.EndsWith('...') -or $enT.EndsWith([string][char]0x2026)
            $ptDots  = $ptT.EndsWith('...') -or $ptT.EndsWith([string][char]0x2026)
            $enDot   = $enT.EndsWith('.') -and -not $enDots
            $ptDot   = $ptT.EndsWith('.') -and -not $ptDots
            if ($enColon -ne $ptColon -or $enDots -ne $ptDots -or ($enT.Length -gt 25 -and $enDot -ne $ptDot)) { $flags.Add('PONTUACAO') }
            if ($en.Length -ge 3 -and $en.Length -le 40 -and $pt.Length -gt 1.8 * $en.Length -and $pt.Length -gt 12) { $flags.Add('LONGO') }
            foreach ($g in ($gloss | Where-Object { -not $isCodeKey })) {
                if ((-not $g.PadraoEN -or $en -match ('(?i)' + $g.PadraoEN)) -and $pt -match ('(?i)' + $g.Evitar)) { $flags.Add('GLOSS:' + $g.TermoEN) }
            }
        }
    }
    $r.Alerta = ($flags | Select-Object -Unique) -join ';'
    if ($flags.Count -gt 0) {
        $flagged++
        foreach ($f in ($flags | Select-Object -Unique)) {
            $key = if ($f -like 'GLOSS:*') { 'GLOSS' } else { $f }
            if ($flagCount.ContainsKey($key)) { $flagCount[$key]++ } else { $flagCount[$key] = 1 }
            if (-not $examples.ContainsKey($key)) { $examples[$key] = New-Object System.Collections.Generic.List[object] }
            $examples[$key].Add($r)
        }
    }
}

Write-Host ("Linhas: {0} | com algum alerta: {1}" -f $rows.Count, $flagged)
$flagCount.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("  {0,-16} {1,5}" -f $_.Key, $_.Value) }

if ($Show) {
    $key = $Show
    if ($examples.ContainsKey($key)) {
        Write-Host "`nExemplos de $key (max $Limit):"
        $examples[$key] | Select-Object -First $Limit | ForEach-Object {
            Write-Host ("  [{0}] {1}" -f ($_.ResourceSet -replace '.*\.', ''), $_.Key)
            Write-Host ("     EN: " + ($_.English -replace '\s+', ' '))
            Write-Host ("     PT: " + ($_.Portuguese -replace '\s+', ' '))
            if ($_.Alerta -like '*GLOSS:*') { Write-Host ("     ALERTA: " + $_.Alerta) }
        }
    } else { Write-Host "`nNenhum exemplo para '$Show'." }
}

if ($WriteAlerts) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((('Assembly', 'ResourceSet', 'Key', 'English', 'Portuguese', 'Alerta', 'Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
    foreach ($r in $rows) {
        [void]$sb.Append((($r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n")
    }
    [IO.File]::WriteAllText($Csv, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
    Write-Host "Coluna Alerta gravada em $Csv"
}
