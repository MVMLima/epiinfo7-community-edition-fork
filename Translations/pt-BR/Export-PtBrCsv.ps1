<#
.SYNOPSIS
  Extrai as strings das DLLs satelite pt-BR para a planilha pt-BR.csv (fonte editavel da traducao).

.DESCRIPTION
  Le todos os Epi.Core\pt-BR\*.resources.dll e grava uma linha por string:
    Assembly ; ResourceSet ; Key ; English ; Portuguese ; Alerta ; Status
  A coluna English e preenchida a partir dos assemblies compilados em build\Release (recurso "neutro").
  Se a planilha ja existir, as colunas Alerta/Status existentes sao preservadas e o texto em Portuguese
  da planilha tem prioridade (use -FromDlls para sobrescrever o Portuguese com o conteudo das DLLs).

  IMPORTANTE: este script e ASCII puro de proposito (Windows PowerShell 5.1 le .ps1 sem BOM como ANSI).
#>
[CmdletBinding()]
param(
    [string]$SatelliteDir = (Join-Path $PSScriptRoot '..\..\Epi.Core\pt-BR'),
    [string]$BuildDir     = (Join-Path $PSScriptRoot '..\..\build\Release'),
    [string]$OutCsv       = (Join-Path $PSScriptRoot 'pt-BR.csv'),
    [switch]$FromDlls
)
$ErrorActionPreference = 'Stop'

function Read-ResourceSet([Reflection.Assembly]$asm, [string]$name) {
    $h = [ordered]@{}
    $stream = $asm.GetManifestResourceStream($name)
    if (-not $stream) { return $h }
    $reader = New-Object System.Resources.ResourceReader($stream)
    try {
        $e = $reader.GetEnumerator()
        while ($e.MoveNext()) {
            if ($e.Value -is [string]) { $h[[string]$e.Key] = [string]$e.Value }
        }
    } finally { $reader.Close() }
    return $h
}

# 1) Indice do ingles (recursos neutros) dos assemblies compilados: chave "Assembly|ResourceSet"
$neutral = @{}
if (Test-Path $BuildDir) {
    foreach ($f in Get-ChildItem $BuildDir -File | Where-Object { $_.Extension -in '.dll', '.exe' }) {
        try { $a = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($f.FullName)) } catch { continue }
        $simple = $a.GetName().Name
        foreach ($n in $a.GetManifestResourceNames()) {
            if ($n -notlike '*.resources') { continue }
            if ($n -match '\.[a-z]{2}(-[A-Za-z]{2,4})?\.resources$') { continue }   # ignora culturas
            $k = $simple + '|' + ($n -replace '\.resources$', '')
            if (-not $neutral.ContainsKey($k)) { $neutral[$k] = Read-ResourceSet $a $n }
        }
    }
    Write-Host "Ingles: $($neutral.Count) conjuntos de recursos indexados de $BuildDir"
} else {
    Write-Warning "BuildDir nao encontrado ($BuildDir): a coluna English ficara vazia."
}

# 2) Planilha existente (para preservar edicoes / Alerta / Status)
$existing = @{}
if ((Test-Path $OutCsv) -and -not $FromDlls) {
    foreach ($r in (Import-Csv -Path $OutCsv -Delimiter ';' -Encoding UTF8)) {
        $existing[$r.Assembly + '|' + $r.ResourceSet + '|' + $r.Key] = $r
    }
    Write-Host "Planilha existente: $($existing.Count) linhas serao preservadas."
}

# 3) Percorre as DLLs satelite
$rows = New-Object System.Collections.Generic.List[object]
foreach ($dll in Get-ChildItem $SatelliteDir -Filter '*.resources.dll') {
    $assemblyName = $dll.Name -replace '\.resources\.dll$', ''
    $asm = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($dll.FullName))
    foreach ($resName in $asm.GetManifestResourceNames()) {
        if ($resName -notlike '*.pt-BR.resources') { continue }
        $set = $resName -replace '\.pt-BR\.resources$', ''
        $pt  = Read-ResourceSet $asm $resName
        $en  = $null
        if ($neutral.ContainsKey($assemblyName + '|' + $set)) { $en = $neutral[$assemblyName + '|' + $set] }
        else {
            $hit = $neutral.Keys | Where-Object { $_.EndsWith('|' + $set) } | Select-Object -First 1
            if ($hit) { $en = $neutral[$hit] }
        }
        foreach ($k in $pt.Keys) {
            $id  = $assemblyName + '|' + $set + '|' + $k
            $old = $existing[$id]
            $rows.Add([pscustomobject]@{
                Assembly    = $assemblyName
                ResourceSet = $set
                Key         = $k
                English     = $(if ($en -and $en.Contains($k)) { $en[$k] } else { '' })
                Portuguese  = $(if ($old) { $old.Portuguese } else { $pt[$k] })
                Alerta      = $(if ($old) { $old.Alerta } else { '' })
                Status      = $(if ($old) { $old.Status } else { '' })
            })
        }
    }
}

# 4) Grava (UTF-8 com BOM, separador ';', todos os campos entre aspas) - abre certo no Excel pt-BR
function Quote([string]$v) { '"' + ($v -replace '"', '""') + '"' }
$sorted = $rows | Sort-Object Assembly, ResourceSet, Key
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append((('Assembly','ResourceSet','Key','English','Portuguese','Alerta','Status' | ForEach-Object { Quote $_ }) -join ';') + "`r`n")
foreach ($r in $sorted) {
    $cells = $r.Assembly, $r.ResourceSet, $r.Key, $r.English, $r.Portuguese, $r.Alerta, $r.Status
    [void]$sb.Append((($cells | ForEach-Object { Quote ([string]$_) }) -join ';') + "`r`n")
}
[IO.File]::WriteAllText($OutCsv, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
Write-Host "OK: $($rows.Count) strings gravadas em $OutCsv"
