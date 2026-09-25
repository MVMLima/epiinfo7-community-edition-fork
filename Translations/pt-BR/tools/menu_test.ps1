$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$app = "$sp\e2e_b4"
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class W32z { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); }
'@
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
[W32z]::SetProcessDPIAware() | Out-Null
$p = Start-Process "$app\EpiInfo.exe" -WorkingDirectory $app -PassThru
Start-Sleep -Seconds 7; $p.Refresh()
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$c = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, 'createFormsBox')
$root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c).GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
Start-Sleep -Seconds 14
$mod = Get-Process -Name MakeView | Select-Object -First 1; $mod.Refresh()
[W32z]::SetForegroundWindow($mod.MainWindowHandle) | Out-Null
$mroot = [System.Windows.Automation.AutomationElement]::FromHandle($mod.MainWindowHandle)
foreach ($name in 'Arquivo','Editar','Inserir','Formato','Ferramentas','Ajuda') {
  $mc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
  $mi = $mroot.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $mc)
  if (-not $mi) { "menu $name nao achado"; continue }
  try { $mi.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern).Expand() } catch { $mi.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() }
  Start-Sleep -Milliseconds 900
  $bmp = New-Object System.Drawing.Bitmap 700, 700
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
  $bmp.Save("$sp\menu_$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  [System.Windows.Forms.SendKeys]::SendWait('{ESC}{ESC}')
  Start-Sleep -Milliseconds 400
  "ok $name"
}
Get-Process -Name MakeView, EpiInfo, Menu -ErrorAction SilentlyContinue | Stop-Process -Force
