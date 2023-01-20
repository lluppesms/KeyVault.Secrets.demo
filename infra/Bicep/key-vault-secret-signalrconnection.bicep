// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a signalR connection
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param signalRName string = 'mysignalrname'
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = '${listKeys(signalRResource.id, signalRResource.apiVersion).primaryKey}'
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var signalRConnectionStringSanitized = replace(replace(signalRConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: signalRConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretCreation 'key-vault-secret-create.bicep' = {
  name: '${moduleName}-Create'
  dependsOn: [ keyVaultSecretCheckValue ]
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValue: signalRConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
