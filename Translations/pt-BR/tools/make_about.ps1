param([string]$Out)
$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$row = Import-Csv 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition\Translations\pt-BR\pt-BR.csv' -Delimiter ';' -Encoding UTF8 |
       Where-Object { $_.Assembly -eq 'Epi.Core' -and $_.Key -eq 'ABOUT_EPIINFO_LINE3' }
$t = [string]$row.English
foreach ($line in [IO.File]::ReadAllLines("$sp\about_repl.tsv", [Text.Encoding]::UTF8)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t", 2
    $before = $t
    $t = [regex]::Replace($t, $p[0], $p[1].Replace('$', '$$'))
    if ($t -ceq $before) { Write-Warning "padrao nao encontrado: $($p[0])" }
}
$bs = [string][char]92
$t = ($t -replace "`r`n", "`n").Replace("`n", $bs + 'n')
[IO.File]::AppendAllText($Out, "SharedStrings`tABOUT_EPIINFO_LINE3`t$t`n", (New-Object Text.UTF8Encoding($false)))
"linha adicionada em $Out"
