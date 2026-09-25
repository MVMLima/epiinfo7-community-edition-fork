param([string]$Assembly, [string]$Rules, [string[]]$Manual, [string]$Out)
$ErrorActionPreference = 'Stop'
$csv = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv'
$map = @{}
foreach ($l in [IO.File]::ReadAllLines($Rules, [Text.Encoding]::UTF8)) { if ($l.Trim()) { $p = $l -split "`t", 2; $map[$p[0]] = $p[1] } }
$skip = @{}
foreach ($m in $Manual) { foreach ($l in [IO.File]::ReadAllLines($m, [Text.Encoding]::UTF8)) { if ($l.Trim()) { $p = $l -split "`t", 3; $skip[$p[0] + "`t" + $p[1]] = $true } } }
$lines = New-Object System.Collections.Generic.List[string]
foreach ($r in (Import-Csv $csv -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Assembly -eq $Assembly })) {
    $short = $r.ResourceSet -replace '^.*\.', ''
    $id = $short + "`t" + $r.Key
    if ($skip.ContainsKey($id)) { continue }
    $en = [string]$r.English
    if (-not $en) { continue }
    $pt = $null
    if ($map.ContainsKey($en)) { $pt = $map[$en] }
    if ($r.Key -match '^btn(And|Or)\.Text$' -and $en -cmatch '^(AND|OR)$') { $pt = '=EN' }
    if ($short -eq 'AssignDialog' -and $r.Key -match '\.ToolTipText$') { $pt = '=EN' }
    if ($short -eq 'AssignDialog' -and $r.Key -match 'ToolStripMenuItem\.Text$' -and $en -cmatch '^[A-Z]{2,}$') { $pt = '=EN' }
    if ($pt) { $lines.Add($id + "`t" + $pt) }
}
[IO.File]::WriteAllLines($Out, $lines, (New-Object Text.UTF8Encoding($false)))
"regras geradas: $($lines.Count)"
