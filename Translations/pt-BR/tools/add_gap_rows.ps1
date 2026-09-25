param([string]$Assembly = 'MakeView', [string]$Tsv, [string]$Prefix = 'Epi.Windows.MakeView', [switch]$WhatIf)
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$csvPath = "$repo\Translations\pt-BR\pt-BR.csv"
$rows = New-Object System.Collections.Generic.List[object]
foreach ($r in (Import-Csv $csvPath -Delimiter ';' -Encoding UTF8)) { $rows.Add($r) }
# conjuntos de recursos reais (nomes do manifesto do binario compilado) -> resx
$resx = @{}
foreach ($f in Get-ChildItem "$repo\$Prefix" -Recurse -Filter *.resx) { if ($f.Name -notmatch '\.[a-z]{2}(-[A-Za-z]+)?\.resx$') { $resx[$f.BaseName] = $f.FullName } }
$full = @{}
foreach ($f in Get-ChildItem "$repo\$Prefix" -Recurse -Filter *.resx) {
    $rel = $f.FullName.Substring("$repo\$Prefix\".Length) -replace '\.resx$', ''
    $full[$f.BaseName] = $Prefix + '.' + ($rel.Replace([string][char]92, '.'))
}
$added = 0; $skipped = 0; $lineNo = 0
foreach ($line in [IO.File]::ReadAllLines($Tsv, [Text.Encoding]::UTF8)) {
    $lineNo++; if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t", 3
    $short = $p[0]; $key = $p[1]; $pt = $p[2]
    if (-not $resx.ContainsKey($short)) { throw "Linha ${lineNo}: resx nao encontrado para $short" }
    [xml]$x = Get-Content -LiteralPath $resx[$short] -Raw -Encoding UTF8
    $d = $x.root.data | Where-Object { $_.name -ceq $key } | Select-Object -First 1
    if (-not $d) { throw "Linha ${lineNo}: chave $key nao existe em $short.resx" }
    $en = [string]$d.value
    $setName = $full[$short]
    $exists = $rows | Where-Object { $_.Assembly -eq $Assembly -and $_.ResourceSet -eq $setName -and $_.Key -ceq $key }
    if ($exists) { $skipped++; continue }
    if ($pt -ceq '=EN') { $pt = $en }
    else {
        $lead = [regex]::Match($en, '^\s+').Value; $trail = [regex]::Match($en, '\s+$').Value
        if ($lead -and -not $pt.StartsWith($lead)) { $pt = $lead + $pt.TrimStart() }
        if ($trail -and -not $pt.EndsWith($trail)) { $pt = $pt.TrimEnd() + $trail }
    }
    $o = [pscustomobject]@{ Assembly = $Assembly; ResourceSet = $setName; Key = $key; English = $en; Portuguese = $pt; Alerta = ''; Status = 'Revisado' }
    $rows.Add($o); $added++
    "+ $setName | $key | '$en' -> '$pt'"
}
"adicionadas: $added | ja existiam: $skipped"
if (-not $WhatIf) {
    function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((('Assembly', 'ResourceSet', 'Key', 'English', 'Portuguese', 'Alerta', 'Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
    foreach ($r in $rows) { [void]$sb.Append((($r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n") }
    [IO.File]::WriteAllText($csvPath, $sb.ToString(), (New-Object Text.UTF8Encoding($true)))
    'Planilha gravada.'
}
