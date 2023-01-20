// --------------------------------------------------------------------------------
// Key Vault Secrets - Main Bicep File for deploying many Key Vault Secrets
// --------------------------------------------------------------------------------
// Testing Notes:
//
// Because it's an inline script used in the check module, you can't run them at the same time, 
//   so each step needs to be dependent on the previous one - if they run in parallel they crash
//
// Initial working test showed that it took ~2.5 minutes to create each secret for a total of 15-17 minutes
//   to create all 5 secrets. The script itself showed an elapsed time of < 1 second, so it's something
//   in the setup of the deployment script that is taking so long.
//
// a) how much faster if I do check for duplicate key = false?
//      it does run much faster, but it's still about 30 seconds per secret, instead of 2 minutes 
//      and then it will still create dupliate keys
// b) what if I used a URI path to a script file instead of an inline script?
//      no change... so you might as well use the inline script as it's easier to read/maintain
// c) is the deduplication working without the managed identity...?
//      NO! it's not working right without the key vault userManagedIdentity
//        the script still runs and looks right, but it always says there is no key
//        so it will create the keys every time  
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
  name: 'names-keys${deploymentSuffix}'
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
    userAssignedIdentityName: resourceNames.outputs.keyVaultUserAssignedIdentity
    location: location
    commonTags: commonTags
  }
}

module keyVaultGeneric 'key-vault-secret-generic.bicep' = {
  name: 'keyVaultGeneric${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    moduleName: 'keyVaultGeneric${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'GenericSecret'
    secretValue: 'NotReallyASecret'
    checkForDuplicateKey: true
    location: location
    userManagedIdentityId: keyVaultModule.outputs.userManagedIdentityId
  }
}

module keyVaultStorage 'key-vault-secret-storageconnection.bicep' = {
  name: 'keyVaultStorage${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultGeneric ]
  params: {
    moduleName: 'keyVaultStorage${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'BlobStorageConnectionString'
    storageAccountName: resourceNames.outputs.blobStorageAccountName
    checkForDuplicateKey: true
    location: location
    userManagedIdentityId: keyVaultModule.outputs.userManagedIdentityId
  }
}

module keyVaultCosmos 'key-vault-secret-cosmosconnection.bicep' = {
  name: 'keyVaultCosmos${deploymentSuffix}'
  dependsOn: [ keyVaultModule, keyVaultStorage ]
  params: {
    moduleName: 'keyVaultCosmos${deploymentSuffix}'
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'CosmosConnectionString'
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
    secretName: 'ServiceBusConnectionString'
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
    secretName: 'SignalRConnectionString'
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
    secretName: 'IotHubConnectionString'
    iotHubName: resourceNames.outputs.iotHubName
    checkForDuplicateKey: false
    location: location
  }
}


// // --------------------------------------------------------------------------------
// // For performance reasons, I tried putting all of the checks and creations in one file
// // to see if it was faster than doing them one at a time, but it wasn't.
// // Each of the keys was still taking about ~2.5 minutes to check and run the create.
// // --------------------------------------------------------------------------------
// module keyVaultSecrets 'key-vault-secret-allkeys.bicep' = {
//   name: 'keyVaultSecrets${deploymentSuffix}'
//   dependsOn: [ keyVaultModule ]
//   params: {
//     keyVaultName: keyVaultModule.outputs.name
//     storageAccountSecretName: 'BlobStorageConnectionString'
//     storageAccountName: resourceNames.outputs.blobStorageAccountName
//     cosmosAccountSecretName: 'CosmosConnectionString'
//     cosmosAccountName: resourceNames.outputs.cosmosAccountName
//     iotHubSecretName: 'IotHubConnectionString'
//     iotHubName: resourceNames.outputs.iotHubName
//     serviceBusSecretName: 'ServiceBusConnectionString'
//     serviceBusName: resourceNames.outputs.serviceBusName
//     signalRSecretName: 'SignalRConnectionString'
//     signalRName: resourceNames.outputs.signalRName
//     checkForDuplicateKey: true
//     location: location
//     userManagedIdentityId: keyVaultModule.outputs.userManagedIdentityId
//   }
// }
