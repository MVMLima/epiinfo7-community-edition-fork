$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$csv = Import-Csv "$repo\Translations\pt-BR\pt-BR.csv" -Delimiter ';' -Encoding UTF8
$sets = @{}
foreach ($r in $csv) { $short = $r.ResourceSet -replace '^.*\.', ''; $k = $r.Assembly + '|' + $short; if (-not $sets.ContainsKey($k)) { $sets[$k] = @{} }; $sets[$k][$r.Key] = $true }
$asmDirs = @{ 'MakeView'='Epi.Windows.MakeView'; 'Enter'='Epi.Windows.Enter'; 'Analysis'='Epi.Windows.Analysis'; 'Menu'='Epi.Windows.Menu'; 'Epi.Windows'='Epi.Windows'; 'Epi.Windows.ImportExport'='Epi.Windows.ImportExport'; 'Epi.ImportExport'='Epi.ImportExport'; 'Epi.Windows.Globalization'='Epi.Windows.Globalization'; 'Mapping'='Epi.Windows.Mapping'; 'StatCalc'='StatCalc'; 'EpiDashboard'='EpiDashboard'; 'Epi.Core'='Epi.Core' }
$out = New-Object System.Collections.Generic.List[string]
$total = 0; $missing = 0; $unknownSets = 0
foreach ($f in Get-ChildItem $repo -Recurse -Filter *.resx -ErrorAction SilentlyContinue) {
  if ($f.Name -match '\.[a-z]{2}(-[A-Za-z]+)?\.resx$') { continue }
  if ($f.FullName.Contains('/bin/') -or $f.FullName.Contains([string][char]92 + 'bin' + [char]92) -or $f.FullName.Contains([string][char]92 + 'obj' + [char]92) -or $f.FullName.Contains([string][char]92 + 'packages' + [char]92) -or $f.FullName.Contains([string][char]92 + 'build' + [char]92)) { continue }
  $base = $f.BaseName
  [xml]$x = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  foreach ($d in $x.root.data) {
    if ($d.type -or $d.mimetype) { continue }
    if ($d.name -like '>>*' -or $d.name -like '$this.*' -and $false) { continue }
    if ($d.name -like '>>*') { continue }
    $val = [string]$d.value
    if ($d.name -notmatch '\.(Text|ToolTipText)$' -and $d.name -notmatch '^[A-Z_0-9]+$') { continue }
    if ([string]::IsNullOrWhiteSpace($val)) { continue }
    $total++
    $hit = $false; $setFound = $false
    foreach ($k in $sets.Keys) { if ($k.EndsWith('|' + $base)) { $setFound = $true; if ($sets[$k].ContainsKey($d.name)) { $hit = $true } } }
    if (-not $hit) { $missing++; $out.Add(("{0}|{1}|{2}|{3}" -f ($f.FullName.Substring($repo.Length + 1)), $base, $d.name, ($val -replace "\s+", ' ')) + $(if (-not $setFound) { '|NOSET' } else { '' })) }
  }
}
"resx strings considered: $total | not in CSV: $missing"
$out | Out-File -Encoding utf8 "C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad\resx_gap.txt"
