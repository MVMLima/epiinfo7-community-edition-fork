$rows = Import-Csv 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv' -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Assembly -eq 'Epi.ImportExport' -and $_.English }
function PassEn([string]$m) { $l = ('12:00:00:  ' + $m).ToLowerInvariant(); $l.Contains('error') -or $l.Contains(':  project') -or $l.Contains('warning') -or $l.Contains(':  import') -or $l.Contains('notice') }
function PassPt([string]$m) { $l = ('12:00:00:  ' + $m).ToLowerInvariant(); $l.Contains('erro') -or $l.Contains(':  projeto') -or $l.Contains('aviso') -or $l.Contains(':  import') -or $l.Contains('observa' + [char]0xE7 + [char]0xE3 + 'o') }
$bad = 0; $en_pass = 0; $pt_extra = 0
foreach ($r in $rows) {
  $e = PassEn $r.English; $p = PassPt $r.Portuguese
  if ($e) { $en_pass++ }
  if ($e -and -not $p) { $bad++; "PERDE: $($r.Key) :: $($r.Portuguese)" }
  if ($p -and -not $e) { $pt_extra++; "GANHA: $($r.Key) :: $($r.Portuguese.Substring(0,[Math]::Min(80,$r.Portuguese.Length)))" }
}
"passam em EN: $en_pass | perdem em PT: $bad | ganham em PT: $pt_extra"
