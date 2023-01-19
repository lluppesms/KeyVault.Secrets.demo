// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault secret if the action parameter is set to ADD or UPDATE
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param action string = 'ADD'
@secure()
param secretValue string = ''
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
var createSecret = action == 'ADD' || action == 'UPDATE' || action == ''

// --------------------------------------------------------------------------------
resource createSecretValue 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if (createSecret) {
  name: '${keyVaultName}/${secretName}'
  properties: {
    value: secretValue
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}

// --------------------------------------------------------------------------------
output secretCreated bool = createSecret
