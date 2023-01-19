// --------------------------------------------------------------------------------
// Key Vault Secrets - Main Bicep File
// --------------------------------------------------------------------------------
param appName string = 'keyvault-secrets'
@allowed(['azd','gha','azdo','dev','demo','design','qa','stg','ct','prod'])
param environmentCode string = 'demo'
param location string = 'eastus'
param keyVaultOwnerUserId string = ''
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------
module deployResources 'main-resources.bicep' = {
  name: 'main-resources${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
    location: location
    runDateTime: runDateTime
  }
}

module deployKeys 'main-keys.bicep' = {
  name: 'main-keys${deploymentSuffix}'
  dependsOn: [ deployResources]
  params: {
    appName: appName
    environmentCode: environmentCode
    location: location
    keyVaultOwnerUserId: keyVaultOwnerUserId
    runDateTime: runDateTime
  }
}
