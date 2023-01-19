// --------------------------------------------------------------------------------
// Key Vault Secrets - Main Bicep File for Key Vault Secrets Deployment
// --------------------------------------------------------------------------------
param appName string = 'keyvault-secrets'
@allowed(['azd','gha','azdo','dev','demo','design','qa','stg','ct','prod'])
param environmentCode string = 'demo'
param location string = 'eastus'
param keyVaultOwnerUserId string = ''

param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Application: appName
  Environment: environmentCode
}

// --------------------------------------------------------------------------------
module resourceNames 'resource-names.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
  }
}

module keyVaultModule 'key-vault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    adminUserObjectIds: [ keyVaultOwnerUserId ]
    applicationUserObjectIds: [ ]
    location: location
    commonTags: commonTags
  }
}

module keyVaultStorage 'key-vault-secret-storageconnection.bicep' = {
  name: 'keyVaultStorage${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    moduleName: 'keyVaultStorage${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'BlobStorageConnectionString'
    storageAccountName: resourceNames.outputs.blobStorageAccountName
    checkForDuplicateKey: false
    location: location
  }
}

// with an inline script used in each module, you can't run them at the same time, 
// so each needs to be dependent on the previous one
  
  // initial working test showed that it took ~2 minutes to create each secret for a total of 17 minutes

  // a) how much faster if I do check for duplicate key = false?
  //     much faster
  // b) how much faster if I used a path to a script file instead of an inline script?
  //     no change... 

module keyVaultCosmos 'key-vault-secret-cosmosconnection.bicep' = {
  name: 'keyVaultCosmos${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultStorage ]
  params: {
    moduleName: 'keyVaultCosmos${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'CosmosConnectionString'
    cosmosAccountName: resourceNames.outputs.cosmosAccountName
    checkForDuplicateKey: false
    location: location
  }
}

module keyVaultServiceBus 'key-vault-secret-servicebusconnection.bicep' = {
  name: 'keyVaultServiceBus${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultCosmos ]
  params: {
    moduleName: 'keyVaultServiceBus${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'ServiceBusConnectionString'
    serviceBusName: resourceNames.outputs.serviceBusName
    checkForDuplicateKey: false
    location: location
  }
}

module keyVaultSignalR 'key-vault-secret-signalrconnection.bicep' = {
  name: 'keyVaultSignalR${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultServiceBus ]
  params: {
    moduleName: 'keyVaultSignalR${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'SignalRConnectionString'
    signalRName: resourceNames.outputs.signalRName
    checkForDuplicateKey: false
    location: location
  }
}

module keyVaultIoTHub 'key-vault-secret-iothubconnection.bicep' = {
  name: 'keyVaultIoTHub${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultSignalR ]
  params: {
    moduleName: 'keyVaultIoTHub${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'IotHubConnectionString'
    iotHubName: resourceNames.outputs.iotHubName
    checkForDuplicateKey: false
    location: location
  }
}
