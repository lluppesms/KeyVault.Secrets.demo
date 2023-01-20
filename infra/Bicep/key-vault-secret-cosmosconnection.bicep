// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a Cosmos connection
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param cosmosAccountName string = 'mycosmosname'
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosAccountName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var cosmosConnectionStringSanitized = replace(replace(cosmosConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: cosmosConnectionStringSanitized
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
    secretValue: cosmosConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
