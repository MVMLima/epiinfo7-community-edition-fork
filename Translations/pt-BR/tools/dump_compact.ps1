param([string]$Assembly = 'Epi.Core', [int]$Parts = 4, [string]$Prefix = 'part')
$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$rows = @(Import-Csv 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv' -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Assembly -eq $Assembly })
$per = [Math]::Ceiling($rows.Count / $Parts)
for ($p = 0; $p -lt $Parts; $p++) {
    $slice = $rows | Select-Object -Skip ($p * $per) -First $per
    $i = $p * $per
    $lines = foreach ($r in $slice) {
        $i++
        $en = ($r.English -replace "`r?`n", ' \n ')
        $pt = ($r.Portuguese -replace "`r?`n", ' \n ')
        $al = if ($r.Alerta) { " [$($r.Alerta)]" } else { '' }
        "{0}. {1}`n   EN: {2}`n   PT: {3}{4}" -f $i, $r.Key, $en, $pt, $al
    }
    [IO.File]::WriteAllLines("$sp\${Prefix}$($p + 1).txt", $lines, (New-Object Text.UTF8Encoding($false)))
    "parte $($p + 1): linhas $($p * $per + 1)-$($p * $per + @($slice).Count)"
}
