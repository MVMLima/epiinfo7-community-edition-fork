param([Parameter(Mandatory)][string]$Tsv, [switch]$WhatIf)
# Lote de codigo: cria chaves novas de recurso para textos que estavam fixos em ingles no codigo.
# TSV (UTF-8, tab): Alvo<TAB>CHAVE<TAB>Ingles<TAB>Portugues   (\n = quebra de linha; linhas com # sao ignoradas)
# Para cada linha: (1) acrescenta <data> no .resx ingles, (2) acrescenta o acessor no .Designer.cs,
# (3) acrescenta a linha na planilha pt-BR.csv. Chaves que ja existem no .resx sao puladas.
# Alvos: Core (Epi.Core/SharedStrings), Menu, StatCalc, Dashboard.
# Script em ASCII puro (Windows PowerShell 5.1 le .ps1 sem BOM como ANSI).
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$targets = @{
    Core      = @{ Dir = 'Epi.Core';         Base = 'SharedStrings';          Assembly = 'Epi.Core';    Set = 'Epi.SharedStrings' }
    Menu      = @{ Dir = 'Epi.Windows.Menu'; Base = 'MenuSharedStrings';      Assembly = 'Menu';        Set = 'Epi.Windows.Menu.MenuSharedStrings' }
    StatCalc  = @{ Dir = 'StatCalc';         Base = 'StatCalcSharedStrings';  Assembly = 'StatCalc';    Set = 'StatCalc.StatCalcSharedStrings' }
    Dashboard = @{ Dir = 'EpiDashboard';     Base = 'DashboardSharedStrings'; Assembly = 'EpiDashboard'; Set = 'EpiDashboard.DashboardSharedStrings' }
}
$utf8bom = New-Object Text.UTF8Encoding($true)
$csvPath = "$repo\Translations\pt-BR\pt-BR.csv"
$rows = New-Object System.Collections.Generic.List[object]
foreach ($r in (Import-Csv $csvPath -Delimiter ';' -Encoding UTF8)) { $rows.Add($r) }
$resx = @{}; $des = @{}
function Esc([string]$s) { $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }
$added = 0; $lineNo = 0
foreach ($line in [IO.File]::ReadAllLines($Tsv, [Text.Encoding]::UTF8)) {
    $lineNo++
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
    $p = $line -split "`t", 4
    if ($p.Count -lt 4) { throw "Linha ${lineNo}: esperado Alvo<TAB>Chave<TAB>Ingles<TAB>Portugues" }
    $t = $targets[$p[0]]; if (-not $t) { throw "Linha ${lineNo}: alvo desconhecido '$($p[0])'" }
    $key = $p[1]; $en = $p[2].Replace('\n', "`r`n"); $pt = $p[3].Replace('\n', "`r`n")
    if ($key -notmatch '^[A-Z][A-Z0-9_]*$') { throw "Linha ${lineNo}: chave invalida '$key'" }
    $rp = "$repo\$($t.Dir)\$($t.Base).resx"; $dp = "$repo\$($t.Dir)\$($t.Base).Designer.cs"
    if (-not $resx.ContainsKey($rp)) { $resx[$rp] = [IO.File]::ReadAllText($rp, [Text.Encoding]::UTF8); $des[$dp] = [IO.File]::ReadAllText($dp, [Text.Encoding]::UTF8) }
    if ($resx[$rp].Contains('<data name="' + $key + '"')) { "ja existe no resx: $($p[0]) $key"; continue }
    $exists = $rows | Where-Object { $_.Assembly -eq $t.Assembly -and $_.ResourceSet -eq $t.Set -and $_.Key -ceq $key }
    if ($exists) { throw "Linha ${lineNo}: $key esta na planilha mas nao no resx" }
    # resx
    $entry = "  <data name=`"$key`" xml:space=`"preserve`">`r`n    <value>$(Esc $en)</value>`r`n  </data>`r`n</root>"
    $s = $resx[$rp]; $i = $s.LastIndexOf('</root>')
    if ($i -lt 0) { throw "Sem </root> em $rp" }
    $resx[$rp] = $s.Substring(0, $i) + $entry + $s.Substring($i + 7)
    # Designer.cs
    $doc = (Esc ($en -replace '\s+', ' ')).Trim()
    $acc = "`r`n        `r`n        /// <summary>`r`n        ///   Looks up a localized string similar to $doc.`r`n        /// </summary>`r`n        public static string $key {`r`n            get {`r`n                return ResourceManager.GetString(`"$key`", resourceCulture);`r`n            }`r`n        }"
    $d = $des[$dp]
    $m = [regex]::Matches($d, '\r?\n    \}\r?\n\}')
    if ($m.Count -eq 0) { throw "Fim de classe nao encontrado em $dp" }
    $at = $m[$m.Count - 1].Index
    $des[$dp] = $d.Substring(0, $at) + $acc + $d.Substring($at)
    # planilha
    $rows.Add([pscustomobject]@{ Assembly = $t.Assembly; ResourceSet = $t.Set; Key = $key; English = $en; Portuguese = $pt; Alerta = ''; Status = 'Revisado' })
    $added++
    "+ $($p[0]) $key | '$($p[2])' -> '$($p[3])'"
}
"adicionadas: $added"
if ($WhatIf) { 'WhatIf: nada gravado.'; return }
foreach ($k in $resx.Keys) { [IO.File]::WriteAllText($k, $resx[$k], $utf8bom) }
foreach ($k in $des.Keys)  { [IO.File]::WriteAllText($k, $des[$k], $utf8bom) }
function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append((('Assembly', 'ResourceSet', 'Key', 'English', 'Portuguese', 'Alerta', 'Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
foreach ($r in $rows) { [void]$sb.Append((($r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n") }
[IO.File]::WriteAllText($csvPath, $sb.ToString(), $utf8bom)
'Recursos, acessores e planilha gravados.'
