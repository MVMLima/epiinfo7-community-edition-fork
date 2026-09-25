param([string]$Assembly)
$csv = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv'
$rows = Import-Csv $csv -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Assembly -eq $Assembly }
$n = 0
foreach ($g in ($rows | Group-Object ResourceSet)) {
    $by = @{}
    foreach ($r in $g.Group) {
        $pt = ([string]$r.Portuguese) -replace '&&', ''
        $m = [regex]::Match($pt, '&([A-Za-z0-9\xC0-\xFF])')
        if (-not $m.Success) { continue }
        $k = $m.Groups[1].Value.ToLowerInvariant()
        if (-not $by.ContainsKey($k)) { $by[$k] = New-Object System.Collections.Generic.List[string] }
        $by[$k].Add($r.Key + ' [' + ($pt -replace "\r?\n", ' ') + ']')
    }
    foreach ($k in $by.Keys) { if ($by[$k].Count -gt 1) { $n++; ("{0} '{1}': {2}" -f ($g.Name -replace '^.*\.', ''), $k, ($by[$k] -join ' | ')) } }
}
"conflitos: $n"
