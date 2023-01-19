# To deploy this main.bicep manually, run these commands at a PowerShell prompt:

# create a resource group 
# az login
# az account set --subscription <subscriptionId>
az group create -l eastus -n rg-keyvault-demo

# deploy resources and keys all at once (calls both of the next two scripts)
az deployment group create --resource-group rg-keyvault-demo --template-file 'main.bicep' --parameters appName=lll-keyvault environmentCode=demo keyVaultOwnerUserId=af35198e-8dc7-4a2e-a41e-b2ba79bebd51 -n main-20230118T093500Z

# deploy only the resources
az deployment group create --resource-group rg-keyvault-demo --template-file 'main-resources.bicep' --parameters appName=lll-keyvault environmentCode=demo keyVaultOwnerUserId=af35198e-8dc7-4a2e-a41e-b2ba79bebd51 -n resource-deploy-20230118T093500Z

# deploy only keys so you can test this multiple times
az deployment group create --resource-group rg-keyvault-demo --template-file 'main-keys.bicep' --parameters appName=lll-keyvault environmentCode=demo keyVaultOwnerUserId=af35198e-8dc7-4a2e-a41e-b2ba79bebd51 -n key-deploy-20230118T154400Z  
