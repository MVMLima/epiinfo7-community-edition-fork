param([int[]]$Xs, [int[]]$Ys, [string[]]$Names)
$ErrorActionPreference = 'Stop'
$sp = 'C:\Users\mvmli\AppData\Local\Temp\claude\C--Users-mvmli-Projetos-EpiInfo7\605079c4-368c-449a-b0f4-68edfda9632e\scratchpad'
$app = "$sp\e2e_b4"
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class W32d {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(int f, int dx, int dy, int d, int e);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
[W32d]::SetProcessDPIAware() | Out-Null
$p = Start-Process "$app\EpiInfo.exe" -WorkingDirectory $app -PassThru
Start-Sleep -Seconds 7; $p.Refresh()
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$c = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, 'classicBox')
$root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c).GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
Start-Sleep -Seconds 14
$mod = Get-Process -Name Analysis | Select-Object -First 1
[W32d]::SetForegroundWindow($mod.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500
for ($i = 0; $i -lt $Xs.Count; $i++) {
  [W32d]::SetCursorPos($Xs[$i], $Ys[$i]) | Out-Null
  Start-Sleep -Milliseconds 300
  foreach ($k in 1, 2) { [W32d]::mouse_event(2, 0, 0, 0, 0); [W32d]::mouse_event(4, 0, 0, 0, 0); Start-Sleep -Milliseconds 80 }
  Start-Sleep -Seconds 3
  $bmp = New-Object System.Drawing.Bitmap 1800, 1100
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
  $bmp.Save("$sp\dlg_$($Names[$i]).png", [System.Drawing.Imaging.ImageFormat]::Png)
  [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
  Start-Sleep -Seconds 1
  "ok $($Names[$i])"
}
Get-Process -Name Analysis, EpiInfo, Menu -ErrorAction SilentlyContinue | Stop-Process -Force
