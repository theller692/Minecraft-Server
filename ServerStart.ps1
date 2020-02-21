#this part has to be first.
param (
    [switch]$BackupProcess = $False
 )
	
#If running backup warnings, the script will just exit.
Set-Location $PSScriptRoot


#Admin Check
$Admin = ([Security.Principal.WindowsBuiltInRole]::Administrator)
$GetUserRole = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($GetUserRole.IsInRole($Admin))) { 
Write-Host "!!!WARNING!!! `n Detected that Powershell is not running as administrator. Please accept the prompt to run as admin so backups will work."
Start-Sleep -Seconds 3
Start-Process powershell -verb RunAs -ArgumentList "-NoExit -c cd -path '$PWD'; .\ServerStart.ps1"
Start-Sleep -Seconds 3
exit
}

#Hold my variables, or at least most of them.
$WarningTrigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
$BackupJobTrigger = New-JobTrigger -Daily -At 3:06AM
$WarningAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -file `"$PWD\Test.ps1`" -Argument `"-BackupProcess`""
$MainDir = "$PWD"
$WorldDir = "$PWD\world\"
$WorldBackup = "$PWD\WorldBackup"
$TitleBase = '/title @a '
$TitleTiming = 'times 20 50 20{ENTER}'
$SubTitle1 = 'subtitle {{}"text":"Server shutdown in '
$SubTitle2 = ' seconds!","color":"red"{}}{ENTER}'
$MainTitle = 'title {{}"text":"!!! WARNING !!!","color":"red"{}}{ENTER}'

#Set up variables from the Minecraft website
$ServerVersion = ((invoke-webrequest -Uri https://www.minecraft.net/en-us/download/server/).Links| where {$_.InnerHTML -like "minecraft_server*"} |Where-Object {$_.href -like "http*"}).innerHTML
$ServerDownloadLink = ((invoke-webrequest -Uri https://www.minecraft.net/en-us/download/server/).Links| where {$_.InnerHTML -like "minecraft_server*"} |Where-Object {$_.href -like "http*"}).href


#Check if the minecraft_server1.x.x.jar file is the same as the website's. If not, download it.
Write-Host ----- Checking for server updates -----
if (Test-Path $pwd\$ServerVersion) {
Write-Host "     Server is already up to date."
}

#Main script functions after the above checks
else {
	if (!(Test-Path "$pwd\JarArchive")){
	Write-Host "---No archive directory found; creating one---"
	New-Item -ItemType Directory "$pwd\JarArchive\" | Out-Null
	}
Get-ChildItem *.jar -recurse |ForEach-Object {Move-Item $_ -Destination "$pwd\JarArchive"}
Write-Host "   New server version availble. Downloading..."
Invoke-Command -ScriptBlock {Invoke-Webrequest -Uri $ServerDownloadLink -Outfile "$pwd\$ServerVersion"}
}

#Backups section
if ($BackupProcess) {
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class SFW {
	 [DllImport("user32.dll")]
	 [return: MarshalAs(UnmanagedType.Bool)]
	 public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

$WindowName = (Get-Process Powershell | Where-Object { $_.MainWindowTitle -like 'Minecraft Server Shell' }).MainWindowHandle
[SFW]::SetForegroundWindow($WindowName)
$CountdownVar = 60
#Clear out any old/malformed commands
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
[System.Windows.Forms.SendKeys]::SendWait('say !!ATTENTION!! The server will RESTART for BACKUPS in 5 minutes. {ENTER}say Please get to a safe area and log off! {ENTER}')
Start-Sleep -Seconds 240
#Set up alert timing
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $TitleTiming)
#Send 60 Second alert
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $SubTitle1 + $CountdownVar + $SubTitle2)
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $MainTitle)
Start-Sleep -Seconds 30
#30 Second alert
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $SubTitle1 + ($CountdownVar = $CountdownVar -30) + $SubTitle2)
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $MainTitle)
Start-Sleep -Seconds 20
#10 Second Alert
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $SubTitle1 + ($CountdownVar = $CountdownVar -20) + $SubTitle2)
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $MainTitle)

#10 second countdown
1..10 | % {
$CountdownVar = $CountdownVar -1
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $SubTitle1 + $CountdownVar + $SubTitle2)
[System.Windows.Forms.SendKeys]::SendWait($TitleBase + $MainTitle)
Start-Sleep -Seconds 1
}

[System.Windows.Forms.SendKeys]::SendWait('stop{ENTER}')
Start-Sleep -Seconds 10
[System.Windows.Forms.SendKeys]::SendWait('^c')

#Automatic restart once backup should be complete
Start-Sleep -Seconds 60
[System.Windows.Forms.SendKeys]::SendWait('.\ServerStart.ps1{ENTER}')
exit
}

#Set Task Scheduler for running the alerts (this can't be done in a job because jobs always run in background and background scripts can't send keystrokes)
Register-ScheduledTask -RunLevel Highest -TaskName MinecraftServerAlert -trigger $WarningTrigger -Action $WarningAction | Out-Null
Write-Host "Starting task for client side backup alerts. If there is red text above this, that likely means a job already exists and the message in red can be ignored."

<# Schedule a job to:
- Cleanup backup directory
- Make new backup folder
- Populate backup folder with \world data
- This section was crafted with wizard magic and does not like being touched.
#>
Register-ScheduledJob -Name MinecraftBackupJob -Trigger $BackupJobTrigger -Scriptblock {
param($WarningAction, $WarningTrigger, $WorldBackup, $WorldDir)
#Keep revolving 14 days of backups
(New-Item -Path $PWD -Name "WorldBackup" -ItemType "directory" -Force | Out-Null)
(Get-ChildItem $WorldBackup | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-14)} | Remove-Item -Recurse)
#Save new backup
New-Item -ItemType Directory -Path "$WorldBackup\Backup $((Get-Date).adddays(-1).ToString('MM-dd-yyyy'))"
(Copy-Item -Path $WorldDir -Destination "$WorldBackup\Backup $((Get-Date).adddays(-1).ToString('MM-dd-yyyy'))" -Recurse)
} -ArgumentList $WarningAction, $WarningTrigger, $WorldBackup, $WorldDir 
Write-Host "Starting backup job. If there is red text above this, that likely means a job already exists and the message in red can be ignored."

#Name the Window
$Host.UI.RawUI.WindowTitle = 'Minecraft Server Shell'
#Run the server, and allow for crashes/reboots
While($True){
	Write-Host $(Get-Date -DisplayHint Time): Minecraft Server started.
	Start-Process -wait -NoNewWindow java -ArgumentList "-Xms512M -Xmx1536M -XX:+UseG1GC -server -jar $ServerVersion nogui"

	Write-Host "----- WARNING:SERVER CRASH ----- `n-----  $(Get-Date) -----"
	
	#Time before rebooting
	Start-Sleep -Seconds 15
}

