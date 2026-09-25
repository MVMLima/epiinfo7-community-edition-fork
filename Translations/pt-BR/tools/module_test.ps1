param([string]$Tag = 'b2', [string]$ButtonId = 'classicBox', [string]$ProcName = 'Analysis', [int]$Wait = 12)
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\mvmli\Projetos\EpiInfo7\Epi-Info-Community-Edition'
$sp   = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$app  = Join-Path $sp "e2e_$Tag"
if (-not (Test-Path "$app\EpiInfo.exe")) {
    robocopy "$repo\build\Release" $app /E /XD Configuration Logs /NFL /NDL /NJH /NJS /NP | Out-Null
}
& "$repo\Translations\pt-BR\Build-PtBrResources.ps1" -OutDir "$app\pt-BR" | Select-Object -Last 1
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
public class W32m {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, int f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
}
'@
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
[W32m]::SetProcessDPIAware() | Out-Null
if (-not (Test-Path "$app\Configuration\EpiInfo.Config.xml")) {
    $p0 = Start-Process "$app\EpiInfo.exe" -WorkingDirectory $app -PassThru
    Start-Sleep -Seconds 6; Stop-Process -Id $p0.Id -Force
}
$cfg = "$app\Configuration\EpiInfo.Config.xml"
[IO.File]::WriteAllText($cfg, ([IO.File]::ReadAllText($cfg) -replace '<Language>[^<]*</Language>', '<Language>pt-BR</Language>'))

$p = Start-Process "$app\EpiInfo.exe" -WorkingDirectory $app -PassThru
Start-Sleep -Seconds 7
$p.Refresh()
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $ButtonId)
$el = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
if (-not $el) { Stop-Process -Id $p.Id -Force; throw "botao $ButtonId nao encontrado" }
$el.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
Start-Sleep -Seconds $Wait
$mod = Get-Process -Name $ProcName -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $mod) { Stop-Process -Id $p.Id -Force; throw "processo $ProcName nao iniciou" }
$mod.Refresh()
"modulo: $($mod.ProcessName) titulo='$($mod.MainWindowTitle)'"
$mroot = [System.Windows.Automation.AutomationElement]::FromHandle($mod.MainWindowHandle)
$all = $mroot.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
$names = @(); foreach ($e in $all) { $n = $e.Current.Name; if ($n -and $n.Length -gt 1 -and $n.Length -lt 90) { $names += $n } }
"textos UIA: $($names.Count)"
($names | Select-Object -Unique | Select-Object -First 90) -join ' | '
$rc = New-Object RECT
[W32m]::GetWindowRect($mod.MainWindowHandle, [ref]$rc) | Out-Null
$w = $rc.Right - $rc.Left; $h = $rc.Bottom - $rc.Top
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp); $hdc = $g.GetHdc()
[W32m]::PrintWindow($mod.MainWindowHandle, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc)
$out = Join-Path $sp "shot_${Tag}_$ProcName.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
"salvo $out (${w}x${h})"
Get-Process -Name $ProcName, EpiInfo, Menu -ErrorAction SilentlyContinue | Stop-Process -Force
