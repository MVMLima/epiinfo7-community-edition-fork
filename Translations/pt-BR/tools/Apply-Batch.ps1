param(
    [Parameter(Mandatory)][string]$Assembly,
    [Parameter(Mandatory)][string]$Tsv,          # colunas: ResourceSet(nome curto) TAB Key TAB NovoPortugues
    [string]$Status = 'Revisado',
    [string]$Report = '',
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$csvPath = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv'
$rows = @(Import-Csv -Path $csvPath -Delimiter ';' -Encoding UTF8)
$index = @{}
foreach ($r in $rows) {
    if ($r.Assembly -ne $Assembly) { continue }
    $short = $r.ResourceSet -replace '^.*\.', ''
    $id = $short + "`t" + $r.Key
    if ($index.ContainsKey($id)) { throw "Chave ambigua no indice: $id" }
    $index[$id] = $r
}
$changes = New-Object System.Collections.Generic.List[string]
$errors = New-Object System.Collections.Generic.List[string]
$seen = @{}
$lineNo = 0
foreach ($line in [IO.File]::ReadAllLines($Tsv, [Text.Encoding]::UTF8)) {
    $lineNo++
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t", 3
    if ($p.Count -ne 3) { $errors.Add("Linha ${lineNo}: esperado 3 colunas."); continue }
    $id = $p[0] + "`t" + $p[1]
    if ($seen.ContainsKey($id)) { $errors.Add("Linha ${lineNo}: repetida ($($p[0]) / $($p[1]))."); continue }
    $seen[$id] = $true
    if (-not $index.ContainsKey($id)) { $errors.Add("Linha ${lineNo}: chave inexistente ($($p[0]) / $($p[1]))."); continue }
    $r = $index[$id]
    $old = [string]$r.Portuguese
    $new = $p[2]
    if ($new -ceq '=EN') { $new = [string]$r.English }
    else {
        $new = $new.Replace(([string][char]92 + 'n'), "`r`n")
        # o arquivo de leitura mostra ' \n ' (com espacos); no original nao ha espaco ao redor da quebra de linha
        $crlf = ([string][char]13) + ([string][char]10)
        while ($new.Contains(' ' + $crlf) -or $new.Contains($crlf + ' ')) { $new = $new.Replace(' ' + $crlf, $crlf).Replace($crlf + ' ', $crlf) }
    }
    # preserva espaco inicial/final do original (a ferramenta de escrita corta espacos no fim das linhas)
    $lead = [regex]::Match([string]$r.English, '^\s+').Value
    $trail = [regex]::Match([string]$r.English, '\s+$').Value
    if ($new.Trim().Length -gt 0) {
        if ($lead -and -not $new.StartsWith($lead)) { $new = $lead + $new.TrimStart() }
        if ($trail -and -not $new.EndsWith($trail)) { $new = $new.TrimEnd() + $trail }
    }
    if ($old -ceq $new) { continue }
    $changes.Add(("{0}|{1}`n  EN : {2}`n  ANT: {3}`n  NOVO: {4}" -f $p[0], $p[1], ($r.English -replace "`r?`n", ' '), ($old -replace "`r?`n", ' '), $new))
    if (-not $WhatIf) { $r.Portuguese = $new; $r.Status = $Status }
}
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }; throw "Mapeamento invalido: nada foi gravado." }
"Linhas no mapeamento: $($seen.Count) | alteradas: $($changes.Count)"
if ($Report) { [IO.File]::WriteAllLines($Report, $changes, (New-Object Text.UTF8Encoding($false))) }
if (-not $WhatIf) {
    function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((('Assembly', 'ResourceSet', 'Key', 'English', 'Portuguese', 'Alerta', 'Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
    foreach ($r in $rows) { [void]$sb.Append((($r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n") }
    [IO.File]::WriteAllText($csvPath, $sb.ToString(), (New-Object Text.UTF8Encoding($true)))
    'Planilha gravada.'
}
