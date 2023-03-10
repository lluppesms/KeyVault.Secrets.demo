// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a storage account connection
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param storageAccountName string = 'myStorageAccountName'
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var storageAccountConnectionStringSanitized = replace(replace(storageAccountConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: storageAccountConnectionStringSanitized
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
    secretValue: storageAccountConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

module keyVaultSecretCheckValue2 'key-vault-secret-check.bicep' = {
  name: '${moduleName}2-Check'
  dependsOn: [ keyVaultSecretCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: storageAccountConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretCreation2 'key-vault-secret-create.bicep' = {
  name: '${moduleName}2-Create'
  dependsOn: [ keyVaultSecretCheckValue2 ]
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValue: storageAccountConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
