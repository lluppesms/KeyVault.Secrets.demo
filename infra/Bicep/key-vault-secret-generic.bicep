// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
@secure()
param secretValue string = ''
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var secretValueSanitized = replace(replace(secretValue, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: secretValueSanitized
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
    secretValue: secretValue
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
