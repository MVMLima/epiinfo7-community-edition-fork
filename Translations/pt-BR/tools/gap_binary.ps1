param([string]$Exe, [string]$Assembly, [string[]]$ResxDirs, [string]$Out, [hashtable]$Alias = @{})
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$csv = Import-Csv "$repo\Translations\pt-BR\pt-BR.csv" -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Assembly -eq $Assembly }
$have = @{}
foreach ($r in $csv) { $have[$r.ResourceSet + '|' + $r.Key] = $true }
$a = [Reflection.Assembly]::LoadFrom($Exe)
$names = @($a.GetManifestResourceNames() | Where-Object { $_ -like '*.resources' } | ForEach-Object { $_ -replace '\.resources$', '' })
$resx = @{}
foreach ($d in $ResxDirs) { foreach ($f in Get-ChildItem "$repo\$d" -Recurse -Filter *.resx) { if ($f.Name -notmatch '\.[a-z]{2}(-[A-Za-z]+)?\.resx$') { if (-not $resx.ContainsKey($f.BaseName)) { $resx[$f.BaseName] = New-Object System.Collections.Generic.List[string] }; $resx[$f.BaseName].Add($f.FullName) } } }
$lines = New-Object System.Collections.Generic.List[string]
foreach ($n in $names) {
    $short = $n -replace '^.*\.', ''
    if ($Alias.ContainsKey($short)) { $short = $Alias[$short] }
    if (-not $resx.ContainsKey($short)) { $lines.Add("#SEM_RESX|$n"); continue }
    $path = $resx[$short] | Select-Object -First 1
    if ($resx[$short].Count -gt 1) { $lines.Add("#AMBIGUO|$n|" + ($resx[$short] -join ';')) }
    [xml]$x = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($d in $x.root.data) {
        if ($d.type -or $d.mimetype) { continue }
        if ($d.name -like '>>*') { continue }
        $v = [string]$d.value
        if ($v -notmatch '[A-Za-z]{2}') { continue }
        if ($d.name -notmatch '\.(Text|ToolTipText)$' -and $d.name -notmatch '^[A-Za-z_0-9]+$') { continue }
        if ($d.name -match '\.(Name|AccessibleName|Font|Location|Size|ImageKey|Tag|Mask|Items)|^\$this\.(Name|StartPosition|AutoScaleDimensions)') { continue }
        if (-not $have.ContainsKey($n + '|' + $d.name)) { $lines.Add($n + '|' + $d.name + '|' + ($v -replace "\r?\n", ' \n ')) }
    }
}
$lines | Out-File -Encoding utf8 $Out
"conjuntos no binario: $($names.Count) | linhas faltando: $(@($lines | Where-Object { $_ -notlike '#*' }).Count)"
