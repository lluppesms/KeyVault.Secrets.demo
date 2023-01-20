// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secrets for many things
//   but ONLY if it does not already exist or the value is different.
// --------------------------------------------------------------------------------
// For performance reasons, I tried putting all of the checks and creations in one file
// to see if it was faster than doing them one at a time, but it wasn't.
// Each of the keys was still taking about ~2 minutes to check and run the create.
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param storageAccountSecretName string = 'BlobStorageConnectionString'
param storageAccountName string = 'blobStorageAccountName'
param cosmosAccountSecretName string = 'CosmosConnectionString'
param cosmosAccountName string = 'cosmosAccountName'
param iotHubSecretName string = 'IotHubConnectionString'
param iotHubName string = 'iotHubName'
param serviceBusSecretName string = 'ServiceBusConnectionString'
param serviceBusName string = 'serviceBusName'
param serviceBusAccessKeyName string = 'RootManageSharedAccessKey'
param signalRSecretName string = 'SignalRConnectionString'
param signalRName string = 'signalRName'
param location string = resourceGroup().location
param utcValue string = utcNow()
param checkForDuplicateKey bool = true
param userManagedIdentityId string = 'myUserManagedIdentityId'

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var storageAccountConnectionStringSanitized = replace(replace(storageAccountConnectionString, '&', '_'), ';', '_')

module keyVaultSecretStorageCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-Storage-Check'
  params: {
    keyVaultName: keyVaultName
    secretName: storageAccountSecretName
    secretValueSanitized: storageAccountConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretStorageCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-Storage-Create'
  dependsOn: [ keyVaultSecretStorageCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: storageAccountSecretName
    secretValue: storageAccountConnectionString
    action: keyVaultSecretStorageCheck.outputs.action
  }
}

output storageMessage string = keyVaultSecretStorageCheck.outputs.message
output storageCreated bool = keyVaultSecretStorageCreation.outputs.secretCreated


// --------------------------------------------------------------------------------
resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosAccountName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var cosmosConnectionStringSanitized = replace(replace(cosmosConnectionString, '&', '_'), ';', '_')

module keyVaultSecretCosmosCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-Cosmos-Check'
  dependsOn: [ keyVaultSecretStorageCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: cosmosAccountSecretName
    secretValueSanitized: cosmosConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretCosmosCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-Cosmos-Create'
  dependsOn: [ keyVaultSecretCosmosCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: cosmosAccountSecretName
    secretValue: cosmosConnectionString
    action: keyVaultSecretCosmosCheck.outputs.action
  }
}

output cosmosMessage string = keyVaultSecretCosmosCheck.outputs.message
output cosmosCreated bool = keyVaultSecretCosmosCreation.outputs.secretCreated

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessSecretName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var iotHubConnectionStringSanitized = replace(replace(iotHubConnectionString, '&', '_'), ';', '_')

module keyVaultSecretIoTHubCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-IoTHub-Check'
  dependsOn: [ keyVaultSecretCosmosCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: iotHubSecretName
    secretValueSanitized: iotHubConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretIoTHubCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-IoTHub-Create'
  dependsOn: [ keyVaultSecretIoTHubCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: iotHubSecretName
    secretValue: iotHubConnectionString
    action: keyVaultSecretIoTHubCheck.outputs.action
  }
}

output iothubMessage string = keyVaultSecretIoTHubCheck.outputs.message
output iothubCreated bool = keyVaultSecretIoTHubCreation.outputs.secretCreated

// --------------------------------------------------------------------------------
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusConnectionString       = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=${serviceBusAccessKeyName};SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var serviceBusConnectionStringSanitized = replace(replace(serviceBusConnectionString, '&', '_'), ';', '_')

module keyVaultSecretServiceBusCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-ServiceBus-Check'
  dependsOn: [ keyVaultSecretIoTHubCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: serviceBusSecretName
    secretValueSanitized: serviceBusConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretServiceBusCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-ServiceBus-Create'
  dependsOn: [ keyVaultSecretServiceBusCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: serviceBusSecretName
    secretValue: serviceBusConnectionString
    action: keyVaultSecretServiceBusCheck.outputs.action
  }
}

output serviceBusmessage string = keyVaultSecretServiceBusCheck.outputs.message
output serviceBussecretCreated bool = keyVaultSecretServiceBusCreation.outputs.secretCreated

// --------------------------------------------------------------------------------
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = '${listKeys(signalRResource.id, signalRResource.apiVersion).primaryKey}'
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'
// Note: the Powershell scripts that check for duplicate key values in the KeyVault do not like the & and ; characters at all so remove them for the check
var signalRConnectionStringSanitized = replace(replace(signalRConnectionString, '&', '_'), ';', '_')

module keyVaultSecretSignalRCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-SignalR-Check'
  dependsOn: [ keyVaultSecretServiceBusCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: signalRSecretName
    secretValueSanitized: signalRConnectionStringSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretSignalRCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-SignalR-Create'
  dependsOn: [ keyVaultSecretSignalRCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: signalRSecretName
    secretValue: signalRConnectionString
    action: keyVaultSecretSignalRCheck.outputs.action
  }
}

output signalRmessage string = keyVaultSecretSignalRCheck.outputs.message
output signalRsecretCreated bool = keyVaultSecretSignalRCreation.outputs.secretCreated


// --------------------------------------------------------------------------------
var genericText = 'NotReallyASecret'
var genericTextSanitized = genericText

module keyVaultSecretGenericCheck 'key-vault-secret-check.bicep' = {
  name: 'keyVaultSecret-Generic-Check'
  dependsOn: [ keyVaultSecretSignalRCreation ]
  params: {
    keyVaultName: keyVaultName
    secretName: 'GenericSecret'
    secretValueSanitized: genericTextSanitized
    location: location
    utcValue: utcValue
    checkForDuplicateKey: checkForDuplicateKey
    userManagedIdentityId: userManagedIdentityId
  }
}

module keyVaultSecretGenericCreation 'key-vault-secret-create.bicep' = {
  name: 'keyVaultSecret-Generic-Create'
  dependsOn: [ keyVaultSecretGenericCheck ]
  params: {
    keyVaultName: keyVaultName
    secretName: 'GenericSecret'
    secretValue: genericText
    action: keyVaultSecretGenericCheck.outputs.action
  }
}

output genericSecretMessage string = keyVaultSecretGenericCheck.outputs.message
output genericSecretCreated bool = keyVaultSecretGenericCreation.outputs.secretCreated
