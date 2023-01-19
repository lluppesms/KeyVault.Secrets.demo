// ----------------------------------------------------------------------------------------------
// This BICEP file will check if a KeyVault secret exists or is different from the supplied value
// ----------------------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
@secure()
param secretValueSanitized string = ''
param checkForDuplicateKey bool = true
param location string = resourceGroup().location
param utcValue string = utcNow()
//param userManagedIdentityId string = ''

var checkForDuplicates = checkForDuplicateKey ? 'true' : 'false'

resource checkSecretValue 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (checkForDuplicateKey) {
  name: 'checkSecretValue'
  location: location
  kind: 'AzurePowerShell'
  //   identity: {
  //     type: 'UserAssigned'
  //     userAssignedIdentities: { '${ userManagedIdentityId }': {} }
  //   }
  properties: {
    azPowerShellVersion: '8.1'
    forceUpdateTag: utcValue
    retentionInterval: 'PT1H'
    timeout: 'PT5M'
    cleanupPreference: 'Always' // cleanupPreference: 'OnSuccess' or 'Always'
    arguments: ' -KeyVaultName ${keyVaultName} -SecretName ${secretName} -SecretValue ${secretValueSanitized} -CheckForDuplicates ${checkForDuplicates}'

    // primaryScriptUri must be an https url
    primaryScriptUri: 'https://raw.githubusercontent.com/lluppesms/KeyVault.Secrets.demo/master/infra/scripts/CheckSecretValue.ps1'

    // scriptContent: '''
    //   Param ([string] $KeyVaultName, [string] $SecretName, [string] $SecretValue, [string] $CheckForDuplicates)
    //   $startDate = Get-Date
    //   $startTime = [System.Diagnostics.Stopwatch]::StartNew()
    //   $message = ""
    //   $action = "SKIP"
    //   if ($CheckForDuplicateKey -eq "false") {
    //     $DeploymentScriptOutputs = @{}
    //     $DeploymentScriptOutputs['message'] = "Skipping duplicate check for $($KeyVaultName).$($SecretName)"
    //     $DeploymentScriptOutputs['action'] = "SKIP"
    //     return
    //   }
    //   $message = "Evaluating $($KeyVaultName).$($SecretName)... "
    //   $message = "Evaluating $($KeyVaultName).$($SecretName)... "
    //   $SecretValue = $SecretValue.Replace('&','_').Replace(';','_')
    //   $secretObject = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName
    //   $currentValue = ""
    //   $existingId = ""
    //   $existingVersion = ""
    //   if ($secretObject) {
    //     $currentValue = $secretObject.secretvalue | ConvertFrom-SecureString -AsPlainText
    //     $currentValue = $currentValue.Replace('&','_').Replace(';','_')
    //     $existingId = $secretObject.id
    //     $existingVersion = $secretObject.version
    //   }
    //   if ($currentValue) {
    //     if ($currentValue.IndexOf($SecretValue) -eq 0 -and ($SecretValue.Length) -eq $currentValue.Length) {
    //       $message += "Value for $($KeyVaultName).$($SecretName) is already the supplied value!";
    //       $action = "SKIP"
    //     }
    //     else {
    //       $message += "A new version of should be created! The current version ($($existingVersion)) will be disabled!";
    //       $action = "UPDATE"
    //       Update-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Enable $False -Version $existingVersion
    //     }
    //   }
    //   else {
    //     $message = "Secret does not exist and a new secret should be created!";
    //     $action = "ADD"
    //   }
    //   $endDate = Get-Date
    //   $endTime = $startTime.Elapsed;
    //   $elapsedTime = "Elapsed Time: {0:HH:mm:ss}" -f ([datetime]$endTime.Ticks)
    //   $elapsedTime += "; Start: {0:HH:mm:ss}" -f ([datetime]$startDate)
    //   $elapsedTime += "; End: {0:HH:mm:ss}" -f ([datetime]$endDate)
    //   Write-Output $message
    //   Write-Output $action
    //   Write-Output $elapsedTime
    //   $DeploymentScriptOutputs = @{}
    //   $DeploymentScriptOutputs['message'] = $message
    //   $DeploymentScriptOutputs['action'] = $action
    //   $DeploymentScriptOutputs['elapsed'] = $elapsedTime
    //   '''
  }
}

output message string = checkSecretValue != null ? checkSecretValue.properties.outputs.message : ''
output action string = checkSecretValue != null ? checkSecretValue.properties.outputs.action : ''
output elapsed string = checkSecretValue != null ? checkSecretValue.properties.outputs.elapsed : ''
