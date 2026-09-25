param([Parameter(Mandatory)][string]$Tsv, [switch]$WhatIf)
# Substituicoes exatas de texto em arquivos de codigo (lote de codigo). Preserva BOM e fim de linha.
# TSV (UTF-8, tab): Arquivo(relativo ao repo)<TAB>Antigo<TAB>Novo<TAB>Ocorrencias esperadas
# Em Antigo/Novo: \t = tab, \q = aspas duplas. Linhas com # sao ignoradas. ASCII puro.
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$files = @{}; $bom = @{}
$n = 0
foreach ($line in [IO.File]::ReadAllLines($Tsv, [Text.Encoding]::UTF8)) {
    $n++
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 4) { throw "Linha ${n}: esperado Arquivo<TAB>Antigo<TAB>Novo<TAB>N" }
    $path = Join-Path $repo $p[0]
    if (-not $files.ContainsKey($path)) {
        $b = [IO.File]::ReadAllBytes($path)
        $bom[$path] = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
        $files[$path] = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    }
    $old = $p[1].Replace('\q', '"').Replace('\t', "`t"); $new = $p[2].Replace('\q', '"').Replace('\t', "`t")
    $expect = if ($p[3] -eq "*") { -1 } else { [int]$p[3] }
    $s = $files[$path]; $count = 0; $i = 0
    while (($i = $s.IndexOf($old, $i, [StringComparison]::Ordinal)) -ge 0) { $count++; $i += $old.Length }
    if (($expect -lt 0 -and $count -lt 1) -or ($expect -ge 0 -and $count -ne $expect)) { throw "Linha ${n}: '$old' aparece $count vez(es) em $($p[0]) (esperado $expect)" }
    $files[$path] = $s.Replace($old, $new)
    "ok  $($p[0]) : $old -> $new  ($count)"
}
if ($WhatIf) { 'WhatIf: nada gravado.'; return }
foreach ($k in $files.Keys) { [IO.File]::WriteAllText($k, $files[$k], (New-Object Text.UTF8Encoding($bom[$k]))) }
"gravados: $($files.Count) arquivo(s)"
