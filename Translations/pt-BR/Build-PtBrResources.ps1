<#
.SYNOPSIS
  Gera as DLLs satelite pt-BR (Epi.Core\pt-BR\*.resources.dll) a partir da planilha pt-BR.csv.

.DESCRIPTION
  Para cada Assembly da planilha:
    1. escreve um arquivo .resources por ResourceSet (System.Resources.ResourceWriter);
    2. monta a DLL satelite com al.exe (Assembly Linker do .NET Framework SDK), cultura pt-BR.
  As DLLs geradas substituem as de Epi.Core\pt-BR, que o build ja copia para build\Release\pt-BR.

  Nenhuma DLL e gerada se a planilha tiver erros (chave duplicada, Assembly/ResourceSet/Key vazios).

  IMPORTANTE: este script e ASCII puro de proposito (Windows PowerShell 5.1 le .ps1 sem BOM como ANSI).
#>
[CmdletBinding()]
param(
    [string]$Csv     = (Join-Path $PSScriptRoot 'pt-BR.csv'),
    [string]$OutDir  = (Join-Path $PSScriptRoot '..\..\Epi.Core\pt-BR'),
    [string]$Version = '7.2.6.2',
    [string]$AlPath
)
$ErrorActionPreference = 'Stop'

# --- localizar al.exe -------------------------------------------------------------------------
if (-not $AlPath) {
    $sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Microsoft SDKs\Windows'
    $AlPath = Get-ChildItem $sdkRoot -Recurse -Filter al.exe -ErrorAction SilentlyContinue |
              Where-Object { $_.FullName -match 'NETFX 4\.\d Tools' -and $_.FullName -notmatch '\\x64\\' } |
              Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $AlPath -or -not (Test-Path $AlPath)) { throw "al.exe nao encontrado. Instale o .NET Framework SDK (Build Tools) ou passe -AlPath." }
Write-Host "al.exe: $AlPath"

# --- ler e validar a planilha -----------------------------------------------------------------
$first = (Get-Content -Path $Csv -TotalCount 1 -Encoding UTF8)
$delim = if ($first -match ';') { ';' } else { ',' }
$rows  = @(Import-Csv -Path $Csv -Delimiter $delim -Encoding UTF8)
if ($rows.Count -eq 0) { throw "Planilha vazia: $Csv" }

$errors = New-Object System.Collections.Generic.List[string]
$seen   = @{}
$n = 1
foreach ($r in $rows) {
    $n++
    if ([string]::IsNullOrWhiteSpace($r.Assembly) -or [string]::IsNullOrWhiteSpace($r.ResourceSet) -or [string]::IsNullOrEmpty($r.Key)) {
        $errors.Add("Linha ${n}: Assembly/ResourceSet/Key vazio."); continue
    }
    $id = ($r.Assembly + '|' + $r.ResourceSet + '|' + $r.Key).ToLowerInvariant()   # ResourceWriter ignora maiusculas
    if ($seen.ContainsKey($id)) { $errors.Add("Linha ${n}: chave duplicada '$($r.Key)' em $($r.Assembly)/$($r.ResourceSet) (ja vista na linha $($seen[$id]))."); continue }
    $seen[$id] = $n
}
if ($errors.Count -gt 0) {
    $errors | Select-Object -First 30 | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Planilha invalida ($($errors.Count) erro(s)). Nenhuma DLL foi gerada."
}

# --- gerar ------------------------------------------------------------------------------------
$work = Join-Path ([IO.Path]::GetTempPath()) ('ptbr_build_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$stage = Join-Path $work 'out'
New-Item -ItemType Directory -Path $stage | Out-Null
try {
    $totalSets = 0; $totalStrings = 0
    foreach ($asmGroup in ($rows | Group-Object Assembly)) {
        $asmName = $asmGroup.Name
        $rsp = New-Object System.Collections.Generic.List[string]
        $rsp.Add('/target:library')
        $rsp.Add('/culture:pt-BR')
        $rsp.Add("/version:$Version")
        $rsp.Add("/fileversion:$Version")
        $rsp.Add('/out:"' + (Join-Path $stage ($asmName + '.resources.dll')) + '"')
        $i = 0
        foreach ($setGroup in ($asmGroup.Group | Group-Object ResourceSet)) {
            $i++
            $resFile = Join-Path $work ('{0}_{1:D4}.resources' -f $asmName, $i)
            $w = New-Object System.Resources.ResourceWriter($resFile)
            try {
                foreach ($r in $setGroup.Group) {
                    $pt = [string]$r.Portuguese
                    # se o ingles usa CRLF, garante CRLF tambem no portugues (o Excel costuma trocar por LF)
                    if (([string]$r.English).Contains("`r`n")) { $pt = ($pt -replace "`r`n", "`n") -replace "`n", "`r`n" }
                    $w.AddResource([string]$r.Key, $pt)
                    $totalStrings++
                }
                $w.Generate()
            } finally { $w.Close() }
            $rsp.Add('/embed:"' + $resFile + '",' + $setGroup.Name + '.pt-BR.resources')
            $totalSets++
        }
        $rspFile = Join-Path $work ($asmName + '.rsp')
        [IO.File]::WriteAllLines($rspFile, $rsp, (New-Object System.Text.UTF8Encoding($false)))
        $output = & $AlPath "@$rspFile" 2>&1
        if ($LASTEXITCODE -ne 0) { throw "al.exe falhou para ${asmName}:`n$($output -join "`n")" }
    }

    # so copia para o destino depois que TODAS as DLLs foram geradas com sucesso
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    Get-ChildItem $stage -Filter '*.resources.dll' | ForEach-Object { Copy-Item $_.FullName -Destination $OutDir -Force }
    Write-Host ("OK: {0} DLLs, {1} conjuntos de recursos, {2} strings -> {3}" -f (Get-ChildItem $stage -Filter '*.resources.dll').Count, $totalSets, $totalStrings, (Resolve-Path $OutDir))
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
