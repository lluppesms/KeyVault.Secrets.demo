// --------------------------------------------------------------------------------
// Creates a KeyVault 
// --------------------------------------------------------------------------------
// FYI: to delete an existing/deleted Key Vault, run this command in an Azure Cloud Shell:
//  > az keyvault purge --name keyvaultname
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVaultName'
param commonTags object = {}
param location string = resourceGroup().location
param adminUserObjectIds array = []
param applicationUserObjectIds array = []
param createUserAssignedIdentity bool = true
param userAssignedIdentityName string = '${keyVaultName}-cicd'

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~key-vault.bicep' }
var tags = union(commonTags, templateTag)

var skuName = 'standard'
var enabledForDeployment = false
var enabledForDiskEncryption = false
var enabledForTemplateDeployment = false
var tenantId = subscription().tenantId

var adminAccessPolicies = [for adminUser in adminUserObjectIds: {
  objectId: adminUser
  tenantId: subscription().tenantId
  permissions: {
    certificates: [ 'all' ]
    secrets: [ 'all' ]
    keys: [ 'all' ]
  }
}]
var applicationUserPolicies = [for appUser in applicationUserObjectIds: {
  objectId: appUser
  tenantId: subscription().tenantId
  permissions: {
    secrets: [ 'get' ]
  }
}]
var accessPolicies = union(adminAccessPolicies, applicationUserPolicies)

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: false
    tenantId: tenantId
    // Use Access Policies model
    //enableRbacAuthorization: true
    enableRbacAuthorization: false      
    accessPolicies: accessPolicies

    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// this creates a user assigned identity that can be used to verify and update secrets in future steps
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = if (createUserAssignedIdentity) {
  name: userAssignedIdentityName
  location: location
}
resource userAssignedIdentityKeyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = if (createUserAssignedIdentity) {
  name: 'add'
  parent: keyVaultResource
  properties: {
    accessPolicies: [
      {
        permissions: {
          secrets: ['get','list','set']
        }
        tenantId: userAssignedIdentity.properties.tenantId
        objectId: userAssignedIdentity.properties.principalId
      }
    ]
  }
}

// --------------------------------------------------------------------------------
output name string = keyVaultResource.name
output id string = keyVaultResource.id
output userManagedIdentityId string = userAssignedIdentity != null ? userAssignedIdentity.id : ''
