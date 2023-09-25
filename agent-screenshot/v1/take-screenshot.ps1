Add-Type -Name ConsoleUtils -Namespace WPIA -MemberDefinition @'
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();
	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'@
   
$ConsoleMode = @{ MINIMIZED = 2; }
$hWnd = [WPIA.ConsoleUtils]::GetConsoleWindow()
$a = [WPIA.ConsoleUtils]::ShowWindow($hWnd, $ConsoleMode.MINIMIZED)

$tempPath = Get-VstsTaskVariable -Name "Agent.TempDirectory"


# Screenshot code borrowed from: https://techibee.com/powershell/powershell-script-to-take-a-screenshot-of-your-desktop/1626

function Get-Screenshot{
[cmdletbinding()]
param(
 [Drawing.Rectangle]$bounds, 
 [string]$path
) 
   $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
   $graphics = [Drawing.Graphics]::FromImage($bmp)
   $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)
   $bmp.Save($path)
   $graphics.Dispose()
   $bmp.Dispose()
}
 
function Get-ScreenResolution {
 $Screens = [system.windows.forms.screen]::AllScreens
 foreach ($Screen in $Screens) {
  $DeviceName = $Screen.DeviceName
  $Width  = $Screen.Bounds.Width
  $Height  = $Screen.Bounds.Height
  $IsPrimary = $Screen.Primary
  $OutputObj = New-Object -TypeName PSobject
  $OutputObj | Add-Member -MemberType NoteProperty -Name DeviceName -Value $DeviceName
  $OutputObj | Add-Member -MemberType NoteProperty -Name Width -Value $Width
  $OutputObj | Add-Member -MemberType NoteProperty -Name Height -Value $Height
  $OutputObj | Add-Member -MemberType NoteProperty -Name IsPrimaryMonitor -Value $IsPrimary
  $OutputObj
 }
}
 
$datetime = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")
$fileName = "{1}.png" -f $datetime
$filePath = join-path $tempPath $fileName 
 
[void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
 
$screen = Get-ScreenResolution | ? {$_.IsPrimaryMonitor -eq $true}
$bounds = [Drawing.Rectangle]::FromLTRB(0, 0, $Screen.Width, $Screen.Height)
 
Get-Screenshot -Bounds $bounds -Path "$filePath"

Write-Host "##vso[task.uploadfile]$filePath"