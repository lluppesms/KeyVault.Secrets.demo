// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a IoT Hub Connection
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param iotHubName string = 'myiothubname'
param location string = resourceGroup().location
param utcValue string = utcNow()
param moduleName string = 'keyVaultSecret1'
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var iotHubConnectionStringSanitized = replace(replace(iotHubConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCheckValue 'key-vault-secret-check.bicep' = {
  name: '${moduleName}-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    secretValueSanitized: iotHubConnectionStringSanitized
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
    secretValue: iotHubConnectionString
    action: keyVaultSecretCheckValue.outputs.action
  }
}

output message string = keyVaultSecretCheckValue.outputs.message
output secretCreated bool = keyVaultSecretCreation.outputs.secretCreated
