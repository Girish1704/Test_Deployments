Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,
    [string]
    $AzurePassword,
    [string]
    $AzureTenantID,
    [string]
    $AzureSubscriptionID,
    [string]
    $ODLID,
    [string]
    $DeploymentID,
    [string]
    $vmAdminUsername,
    [string]
    $vmAdminPassword,
    [string]
    $trainerUserName,
    [string]
    $trainerUserPassword,
    [string]
    $AppID,
    [string]
    $AppSecret
)
 
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

[System.Environment]::SetEnvironmentVariable('AppID', $AppID,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AppSecret', $AppSecret,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("DeploymentID", $DeploymentID, [System.EnvironmentVariableTarget]::Machine)
System.Environment]::SetEnvironmentVariable("AzureSubscriptionID", $AzureSubscriptionID, [System.EnvironmentVariableTarget]::Machine)

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath
 
# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon

InstallAzCLI
InstallAzPowerShellModule
InstallModernVmValidator

CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID 

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

# Create a folder in the C drive
$folderPath = "C:\datasets"
New-Item -Path $folderPath -ItemType Directory -Force

# Change directory to the new folder
Set-Location -Path $folderPath

$WebClient = New-Object System.Net.WebClient	
Invoke-WebRequest -Uri "https://github.com/CloudLabsAI-Azure/Knowledge-Augmented-Chatbot-with-LangChain-and-AI-Search/archive/refs/heads/datasets.zip" -OutFile "C:\datasets.zip"

#unziping folder	
function Expand-ZIPFile($file, $destination)	
{	
$shell = new-object -com shell.application	
$zip = $shell.NameSpace($file)	
foreach($item in $zip.items())	
{	
$shell.Namespace($destination).copyhere($item)	
}	
}	
Expand-ZIPFile -File "C:\datasets.zip" -Destination "C:\datasets"

# Create a folder in the C drive
$folderPath2 = "C:\codefiles"
New-Item -Path $folderPath -ItemType Directory -Force

# Change directory to the new folder
Set-Location -Path $folderPath

$WebClient = New-Object System.Net.WebClient	
Invoke-WebRequest -Uri "https://github.com/CloudLabsAI-Azure/Knowledge-Augmented-Chatbot-with-LangChain-and-AI-Search/archive/refs/heads/codefiles.zip" -OutFile "C:\codefiles.zip"

#unziping folder	
function Expand-ZIPFile($file, $destination)	
{	
$shell = new-object -com shell.application	
$zip = $shell.NameSpace($file)	
foreach($item in $zip.items())	
{	
$shell.Namespace($destination).copyhere($item)	
}	
}	
Expand-ZIPFile -File "C:\codefiles.zip" -Destination "C:\codefiles"

# Create a new WebClient object
$WebClient = New-Object System.Net.WebClient

# Download the logon-lang.ps1 task script
$WebClient = New-Object System.Net.WebClient
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Girish1704/Test_Deployments/refs/heads/main/gpt/s27/t1/logon-lang.ps1" -OutFile "C:\LabFiles\logontask.ps1"

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\azureuser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value $adminPassword -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord
 
# Scheduled Task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\azureuser" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File C:\LabFiles\logontask.ps1"
Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
 
Stop-Transcript
 
Restart-Computer -Force
