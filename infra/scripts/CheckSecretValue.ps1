Param ([string] $KeyVaultName, [string] $SecretName, [string] $SecretValue, [string] $CheckForDuplicates)

$startDate = Get-Date
$startTime = [System.Diagnostics.Stopwatch]::StartNew()
# add a 2 second delay just to make the elapsed time at least two seconds...
Start-Sleep -Seconds 2;

$message = ""
$action = "SKIP"

if ($CheckForDuplicateKey -eq "false") {
  $DeploymentScriptOutputs = @{}
  $DeploymentScriptOutputs['message'] = "Skipping duplicate check for $($KeyVaultName).$($SecretName)"
  $DeploymentScriptOutputs['action'] = "SKIP"
  return
}

$message = "Evaluating $($KeyVaultName).$($SecretName)... "
$message = "Evaluating $($KeyVaultName).$($SecretName)... "
$SecretValue = $SecretValue.Replace('&','_').Replace(';','_')
$secretObject = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName
$currentValue = ""
$existingVersion = ""
if ($secretObject) {
  $currentValue = $secretObject.secretvalue | ConvertFrom-SecureString -AsPlainText
  $currentValue = $currentValue.Replace('&','_').Replace(';','_')
  $existingVersion = $secretObject.version
}
if ($currentValue) {
  if ($currentValue.IndexOf($SecretValue) -eq 0 -and ($SecretValue.Length) -eq $currentValue.Length) {
    $message += "Value for $($KeyVaultName).$($SecretName) is already the supplied value!";
    $action = "SKIP"
  }
  else {
    $message += "A new version of should be created! The current version ($($existingVersion)) will be disabled!";
    $action = "UPDATE"
    Update-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Enable $False -Version $existingVersion
  }
}
else {
  $message = "Secret does not exist and a new secret should be created!";
  $action = "ADD"
}

$endDate = Get-Date
$endTime = $startTime.Elapsed;
$elapsedTime = "Elapsed Time: {0:HH:mm:ss}" -f ([datetime]$endTime.Ticks)
$elapsedTime += "; Start: {0:HH:mm:ss}" -f ([datetime]$startDate)
$elapsedTime += "; End: {0:HH:mm:ss}" -f ([datetime]$endDate)

Write-Output $message
Write-Output $action
Write-Output $elapsedTime

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['message'] = $message
$DeploymentScriptOutputs['action'] = $action
$DeploymentScriptOutputs['elapsed'] = $elapsedTime
