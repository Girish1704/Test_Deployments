Start-Transcript -Path C:\WindowsAzure\Logs\logon.txt -Append
# logon task
$AppID = $env:AppID
$AppSecret = $env:AppSecret
$DeploymentID = $env:DeploymentID
 
#if we need to login to the Azure uisng CLI or poweshell command we need to user
 
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID

 
$securePassword = $AppSecret | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AppID, $SecurePassword
 
# If we are using Connect-AzAccount we need to use Login-AzAccount
Login-AzAccount -ServicePrincipal -Credential $cred -Tenant $AzureTenantID | Out-Null

# Variables
$storageAccountName = "storage"+ $DeploymentID 
$containerName = "documents"           
$localDirectory = "C:\datasets\Knowledge-Augmented-Chatbot-with-LangChain-and-AI-Search-datasets"    
$rg = "langchain-"+ $DeploymentID

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rg -AccountName $storageAccountName )[0].Value

# Authenticate and get the storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storage_account_key

# Get all files from the specified local directory
Get-ChildItem -Path $localDirectory -File | ForEach-Object {
    $filePath = $_.FullName
    $blobName = $_.Name  # The name of the blob will be the same as the file name

    Write-Host "Uploading $blobName..."
    Set-AzStorageBlobContent -File $filePath -Container $containerName -Blob $blobName -Context $context
    Write-Host "$blobName uploaded successfully!"
}

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false 


