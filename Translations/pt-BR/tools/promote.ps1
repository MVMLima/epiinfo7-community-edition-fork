$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$sp   = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$gen  = Join-Path $sp 'gen_promote'
$live = "$repo\Epi.Core\pt-BR"
if (Test-Path $gen) { Remove-Item -LiteralPath $gen -Recurse -Force }
& "$repo\Translations\pt-BR\Build-PtBrResources.ps1" -OutDir $gen | Select-Object -Last 1

function Load-Dll([string]$file) {
    $h = @{}
    $a = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($file))
    foreach ($n in $a.GetManifestResourceNames()) {
        $r = New-Object System.Resources.ResourceReader($a.GetManifestResourceStream($n))
        $e = $r.GetEnumerator()
        while ($e.MoveNext()) { $h[$n + '|' + $e.Key] = [string]$e.Value }
        $r.Close()
    }
    return $h
}
$changed = @()
foreach ($f in Get-ChildItem $gen -Filter *.resources.dll) {
    $old = Load-Dll "$live\$($f.Name)"
    $new = Load-Dll $f.FullName
    $diff = 0
    foreach ($k in $new.Keys) { if (-not $old.ContainsKey($k) -or $old[$k] -cne $new[$k]) { $diff++ } }
    foreach ($k in $old.Keys) { if (-not $new.ContainsKey($k)) { $diff++ } }
    "{0,-42} entradas={1,4} diferencas={2}" -f $f.Name, $new.Count, $diff
    if ($diff -gt 0) { $changed += $f }
}
"DLLs com conteudo alterado: $($changed.Count)"
foreach ($f in $changed) { Copy-Item $f.FullName -Destination "$live\$($f.Name)" -Force; "  substituida: $($f.Name)" }

# confere Epi.Core\pt-BR (agora) contra a planilha
$csv = Import-Csv "$repo\Translations\pt-BR\pt-BR.csv" -Delimiter ';' -Encoding UTF8
$bad = 0; $n = 0
$cache = @{}
foreach ($r in $csv) {
    if (-not $cache.ContainsKey($r.Assembly)) { $cache[$r.Assembly] = Load-Dll "$live\$($r.Assembly).resources.dll" }
    $k = $r.ResourceSet + '.pt-BR.resources|' + $r.Key
    $exp = [string]$r.Portuguese
    if (([string]$r.English).Contains("`r`n")) { $exp = ($exp -replace "`r`n", "`n") -replace "`n", "`r`n" }
    $n++
    if (-not $cache[$r.Assembly].ContainsKey($k) -or $cache[$r.Assembly][$k] -cne $exp) { $bad++ }
}
"planilha x DLLs oficiais: $n linhas, $bad divergencias"
Remove-Item -LiteralPath $gen -Recurse -Force
