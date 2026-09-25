param([Parameter(Mandatory)][string]$Map, [string]$Override = "", [Parameter(Mandatory)][string]$OutStrings, [Parameter(Mandatory)][string]$OutReplace)
# Segunda onda do lote de codigo: varre os *.Designer.cs que NAO usam ApplyResources (texto fixo em ingles)
# e gera (1) TSV para add_code_strings.ps1 e (2) TSV para code_replace.ps1.
# Map = TSV Ingles<TAB>Portugues (UTF-8). Um texto sem traducao no mapa interrompe o script.
# Chave = UI_ + texto em maiusculas (sem &); texto com & ganha sufixo _MN. ASCII puro.
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$dirs = 'Epi.Windows.MakeView','Epi.Windows.Enter','Epi.Windows','Epi.Windows.Analysis','Epi.Windows.ImportExport','Epi.Windows.Menu','Epi.Windows.Globalization'
$skipFiles = @('MakeView\Dialogs\TableToViewDialog.Designer.cs', 'ImportExport\Dialogs\TableToViewDialog.Designer.cs')
$skipLit = @('PromptFont','PromptTopPosition','ControlFont','ControlTopPosition','ListSourceTable','PromptLeftPosition','ControlLeftPosition','ListSourceTextColumnName','ListSourceTableName',
 'toolStripContainer1','toolStrip1','labelText place holder','OverlayForm','SplashScreenForm','label3','statusStrip1','ViewOutputFiles','SplashDialog','labelStatus','toolStripDownButton','menuStrip2','label1',
 'address','latitude','longitude','quality','confidence','http://www.microsoft.com/maps/','[Success Message]','DRAFT','FINAL')
$ptMap = @{}
foreach ($l in [IO.File]::ReadAllLines($Map, [Text.Encoding]::UTF8)) {
    if ([string]::IsNullOrWhiteSpace($l)) { continue }
    $p = $l -split "`t", 2
    if ($p.Count -lt 2) { throw "Mapa: linha sem tab: $l" }
    $ptMap[$p[0].Trim()] = $p[1].TrimEnd()
}
$ovr = @{}
if ($Override) { foreach ($l in [IO.File]::ReadAllLines($Override, [Text.Encoding]::UTF8)) { if ([string]::IsNullOrWhiteSpace($l)) { continue }; $p = $l -split "`t", 3; $ovr[$p[0] + "|" + $p[1].Trim()] = $p[2].TrimEnd() } }
function Unescape([string]$s) { $s.Replace([string][char]92 + [string][char]92, [string][char]92) }
$items = New-Object System.Collections.Generic.List[object]
foreach ($d in $dirs) {
    foreach ($f in Get-ChildItem "$repo\$d" -Recurse -Include *esigner.cs) {
        if ($f.FullName.Contains('obj')) { continue }
        $skip = $false; foreach ($s in $skipFiles) { if ($f.FullName.EndsWith($s)) { $skip = $true } }
        if ($skip) { continue }
        $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
        if ($t.Contains('ApplyResources')) { continue }
        $rel = $f.FullName.Substring($repo.Length + 1)
        foreach ($m in [regex]::Matches($t, 'this\.(\w+\.)?(\w+\.)?(Text|HeaderText|ToolTipText) = "([^"]*)";')) {
            $lit = $m.Groups[4].Value
            if ($lit -notmatch '[A-Za-z]{2}') { continue }
            if ($skipLit -contains $lit.Trim()) { continue }
            $items.Add([pscustomobject]@{ File = $rel; Old = $m.Value; Lit = $lit; Prop = $m.Value.Substring(0, $m.Value.Length - $lit.Length - 6) })
        }
    }
}
$missing = @($items | Where-Object { -not $ptMap.ContainsKey($_.Lit.Trim()) } | Select-Object -ExpandProperty Lit -Unique)
if ($missing.Count -gt 0) { "SEM TRADUCAO ($($missing.Count)):"; $missing; throw 'Complete o mapa.' }
foreach ($it in $items) {
    $pt = $ptMap[$it.Lit.Trim()]
    $ok = $it.File + '|' + $it.Lit.Trim(); if ($ovr.ContainsKey($ok)) { $pt = $ovr[$ok] }
    $it | Add-Member -NotePropertyName Pt -NotePropertyValue $pt
    $it | Add-Member -NotePropertyName Id -NotePropertyValue ($it.Lit + '||' + $pt)
}
# chaves: uma por par (texto, traducao)
$keyOf = @{}; $used = @{}; $litOf = @{}; $ptOf = @{}
foreach ($id in ($items | Select-Object -ExpandProperty Id -Unique | Sort-Object)) {
    $it = $items | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    $u = (Unescape $it.Lit).Trim()
    $base = ($u.Replace('&', '').ToUpperInvariant() -replace '[^A-Z0-9]+', '_').Trim('_')
    if ($base.Length -gt 44) { $base = $base.Substring(0, 44).Trim('_') }
    if ($base.Length -eq 0) { $base = 'TEXT' }
    $k = 'UI_' + $base; if ($u.Contains('&')) { $k += '_MN' }
    $n = 2; $k0 = $k; while ($used.ContainsKey($k)) { $k = $k0 + '_' + $n; $n++ }
    $used[$k] = $id; $keyOf[$id] = $k; $litOf[$id] = $it.Lit; $ptOf[$id] = $it.Pt
}
$sb = New-Object System.Text.StringBuilder
foreach ($id in ($keyOf.Keys | Sort-Object { $keyOf[$_] })) {
    [void]$sb.Append("Core`t$($keyOf[$id])`t$(Unescape $litOf[$id])`t$($ptOf[$id])`n")
}
[IO.File]::WriteAllText($OutStrings, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
$rb = New-Object System.Text.StringBuilder
foreach ($it in $items) {
    $new = $it.Prop + ' = global::Epi.SharedStrings.' + $keyOf[$it.Id] + ';'
    $old = $it.Old.Replace('"', '\q')
    [void]$rb.Append("$($it.File.Replace('\','/'))`t$old`t$new`t1`n")
}
[IO.File]::WriteAllText($OutReplace, $rb.ToString(), (New-Object Text.UTF8Encoding($false)))
"literais: $($items.Count) | textos unicos: $($keyOf.Count) | arquivos: $(@($items | Select-Object -ExpandProperty File -Unique).Count)"
$all = @{}; foreach ($d in $dirs + 'EpiDashboard','Epi.Windows.Dashboard','Epi.Core','Epi.ImportExport','StatCalc') { foreach ($f in Get-ChildItem "$repo\$d" -Recurse -Filter *.cs) { if (-not $f.FullName.Contains('obj')) { $all[$f.FullName] = [IO.File]::ReadAllText($f.FullName) } } }
$hits = 0
foreach ($lit in ($items | Select-Object -ExpandProperty Lit -Unique)) {
    $bare = (Unescape $lit).Replace('&', '').Trim()
    $rx = '(==|!=|Equals\(|case|IndexOf\(|Contains\(|StartsWith\()\s*"' + [regex]::Escape($bare) + '"'
    foreach ($k in $all.Keys) { if ($all[$k].Contains('"' + $bare + '"') -and [regex]::IsMatch($all[$k], $rx)) { "COMPARA: '$lit' em $($k.Substring($repo.Length + 1))"; $hits++ } }
}
"possiveis comparacoes: $hits"
foreach ($g in ($items | Group-Object File)) {
    $seen = @{}
    foreach ($it in $g.Group) {
        $pt = $it.Pt; $i = $pt.IndexOf('&')
        if ($i -ge 0 -and $i + 1 -lt $pt.Length) { $c = $pt.Substring($i + 1, 1).ToUpperInvariant(); if ($seen.ContainsKey($c) -and $seen[$c] -ne $pt) { "ATALHO repetido '$c' em $($g.Name): '$($seen[$c])' x '$pt'" } else { $seen[$c] = $pt } }
    }
}
