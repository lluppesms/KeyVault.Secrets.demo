// --------------------------------------------------------------------------------
// Key Vault Secrets - Main Bicep File for Resource Deployment
// --------------------------------------------------------------------------------
param appName string = 'keyvault-secrets'
@allowed(['azd','gha','azdo','dev','demo','design','qa','stg','ct','prod'])
param environmentCode string = 'demo'
param location string = 'eastus'

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
  name: 'names-resources${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
  }
}

// --------------------------------------------------------------------------------
module blobStorageAccountModule 'storageaccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageAccountName: resourceNames.outputs.blobStorageAccountName
    blobStorageConnectionName: resourceNames.outputs.blobStorageConnectionName
    location: location
    commonTags: commonTags
    storageAccessTier: 'Hot'
    allowBlobPublicAccess: true
  }
}

module iotHubModule 'iothub.bicep' = {
  name: 'iotHub${deploymentSuffix}'
  params: {
    iotHubName: resourceNames.outputs.iotHubName
    iotStorageAccountName: resourceNames.outputs.iotStorageAccountName
    iotStorageContainerName: 'iothubuploads'
    location: location
    commonTags: commonTags
  }
}
module signalRModule 'signalr.bicep' = {
  name: 'signalR${deploymentSuffix}'
  params: {
    signalRName: resourceNames.outputs.signalRName
    location: location
    commonTags: commonTags
  }
}

module servicebusModule 'servicebus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    serviceBusName: resourceNames.outputs.serviceBusName
    queueNames: [ 'msgs' ]
    location: location
    commonTags: commonTags
  }
}

module cosmosModule 'cosmosdatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    cosmosAccountName: resourceNames.outputs.cosmosAccountName
    containerArray: [ { name: 'TestData', partitionKey: '/partitionKey' } ]
    cosmosDatabaseName: 'TestDatabase'
    location: location
    commonTags: commonTags
  }
}
