// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a Service Bus connection
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param keyName string = 'myKeyName'
param serviceBusName string = 'myservicebusname'
param accessKeyName string = 'RootManageSharedAccessKey'
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true

// --------------------------------------------------------------------------------
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusConnectionString       = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=${accessKeyName};SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var serviceBusConnectionStringSanitized = replace(replace(serviceBusConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = if (checkForDuplicateKey) {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: keyName
    secretValueSanitized: serviceBusConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
  }
}

module keyVaultSecretCreation 'key-vault-secret-create.bicep' = {
  name: '${moduleName}-Create'
  dependsOn: [ keyVaultSecretCheckValue ]
  params: {
    keyVaultName: keyVaultName
    secretName: keyName
    secretValue: serviceBusConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
