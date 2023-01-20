// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
@allowed(['azd','gha','azdo','dev','demo','design','qa','stg','ct','prod'])
param environmentCode string = 'demo'

// --------------------------------------------------------------------------------
var lowerAppName = replace(toLower(appName), ' ', '')
var sanitizedAppName = replace(replace(lowerAppName, '-', ''), '_', '')
var sanitizedEnvironment = toLower(environmentCode)

// --------------------------------------------------------------------------------
// other resource names can be changed if desired, but if using the "azd deploy" command it expects the
// function name to be exactly "{appName}function" so don't change the functionAppName format if using azd
var functionAppName = environmentCode == 'azd' ? '${lowerAppName}function' : toLower('${lowerAppName}-${sanitizedEnvironment}')
var baseStorageName = toLower('${sanitizedAppName}${sanitizedEnvironment}str')

// --------------------------------------------------------------------------------
output logicAppServiceName string           = functionAppName
output logAnalyticsWorkspaceName string     = '${functionAppName}-logs'
output blobStorageConnectionName string     = '${functionAppName}-blobconnection'

output cosmosAccountName string             = toLower('${sanitizedAppName}-cosmos-${sanitizedEnvironment}')
output serviceBusName string                = toLower('${sanitizedAppName}-svcbus-${sanitizedEnvironment}')
output iotHubName string                    = toLower('${sanitizedAppName}-hub-${sanitizedEnvironment}')
output dpsName string                       = toLower('${sanitizedAppName}-dps-${sanitizedEnvironment}')
output signalRName string                   = toLower('${sanitizedAppName}-signal-${sanitizedEnvironment}')
output streamName string                    = toLower('${sanitizedAppName}-stream-${sanitizedEnvironment}')

// Key Vaults and Storage Accounts can only be 24 characters long
var keyVaultName                            = take(toLower('${sanitizedAppName}${sanitizedEnvironment}vault'), 24)
output keyVaultName string                  = keyVaultName
output keyVaultUserAssignedIdentity string  = '${keyVaultName}-cicd'
output logicAppStorageAccountName string    = take('${baseStorageName}app${uniqueString(resourceGroup().id)}', 24)
output blobStorageAccountName string        = take('${baseStorageName}blob${uniqueString(resourceGroup().id)}', 24)
output iotStorageAccountName string         = take('${baseStorageName}iot${uniqueString(resourceGroup().id)}', 24)
