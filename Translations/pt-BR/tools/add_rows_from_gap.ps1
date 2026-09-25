param([Parameter(Mandatory)][string]$Assembly, [Parameter(Mandatory)][string]$Gap, [Parameter(Mandatory)][string]$Tsv, [switch]$WhatIf)
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$csvPath = "$repo\Translations\pt-BR\pt-BR.csv"
$rows = New-Object System.Collections.Generic.List[object]
foreach ($r in (Import-Csv $csvPath -Delimiter ';' -Encoding UTF8)) { $rows.Add($r) }
$en = @{}
foreach ($l in [IO.File]::ReadAllLines($Gap, [Text.Encoding]::UTF8)) {
    if ($l.StartsWith('#') -or [string]::IsNullOrWhiteSpace($l)) { continue }
    $p = $l -split '\|', 3
    $en[$p[0] + '|' + $p[1]] = $p[2].Replace(' \n ', "`r`n")
}
$added = 0; $lineNo = 0
foreach ($line in [IO.File]::ReadAllLines($Tsv, [Text.Encoding]::UTF8)) {
    $lineNo++; if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t", 3
    $id = $p[0] + '|' + $p[1]
    if (-not $en.ContainsKey($id)) { throw "Linha ${lineNo}: $id nao esta no arquivo de lacunas" }
    $exists = $rows | Where-Object { $_.Assembly -eq $Assembly -and $_.ResourceSet -eq $p[0] -and $_.Key -ceq $p[1] }
    if ($exists) { "ja existe: $id"; continue }
    $e = $en[$id]; $pt = $p[2]
    if ($pt -ceq '=EN') { $pt = $e }
    $rows.Add([pscustomobject]@{ Assembly = $Assembly; ResourceSet = $p[0]; Key = $p[1]; English = $e; Portuguese = $pt; Alerta = ''; Status = 'Revisado' })
    $added++
    "+ $id | '$e' -> '$pt'"
}
"adicionadas: $added"
if (-not $WhatIf) {
    function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((('Assembly', 'ResourceSet', 'Key', 'English', 'Portuguese', 'Alerta', 'Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
    foreach ($r in $rows) { [void]$sb.Append((($r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n") }
    [IO.File]::WriteAllText($csvPath, $sb.ToString(), (New-Object Text.UTF8Encoding($true)))
    'Planilha gravada.'
}
