# To deploy this main.bicep manually:
# az login
# az account set --subscription <subscriptionId>
# az group create -l eastus -n rg-keyvault-demo
az deployment group create --resource-group rg-keyvault-demo --template-file 'main-resources.bicep' --parameters appName=lll-keyvault environmentCode=demo keyVaultOwnerUserId=af35198e-8dc7-4a2e-a41e-b2ba79bebd51 -n main-resources-20230118T093500Z
az deployment group create --resource-group rg-keyvault-demo --template-file 'main-keys.bicep' --parameters appName=lll-keyvault environmentCode=demo keyVaultOwnerUserId=af35198e-8dc7-4a2e-a41e-b2ba79bebd51 -n main-keys-20230118T093600Z