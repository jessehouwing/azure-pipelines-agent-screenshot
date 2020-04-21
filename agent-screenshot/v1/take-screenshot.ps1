Add-Type -Name ConsoleUtils -Namespace WPIA -MemberDefinition @'
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();
	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'@
   
$ConsoleMode = @{ MINIMIZED = 2; }
$hWnd = [WPIA.ConsoleUtils]::GetConsoleWindow()
$a = [WPIA.ConsoleUtils]::ShowWindow($hWnd, $ConsoleMode.MINIMIZED)

$path = Get-VstsTaskVariable "Agent.TempDirectory"
& "$PSScriptRoot\screenshot-cmd.exe" -o "$path\screenshot.png"

Write-Host "##vso[task.uploadfile]$path\screenshot.png"