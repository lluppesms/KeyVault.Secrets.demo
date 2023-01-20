# Key Vault Secrets Demo

[![Open in vscode.dev](https://img.shields.io/badge/Open%20in-vscode.dev-blue)][1]
[1]: https://vscode.dev/github/lluppesms/KeyVault.Secrets.demo/

<!-- ![azd Compatible](/Docs/images/AZD_Compatible.png) -->

---

## Overview

Deploying Key Vault Secrets in a pipeline is a common task. This demo shows how to deploy a variety of secrets to a Key Vault. (Generic String, Storage Account, CosmosDB, IoT Hub, Service Bus, SignalR)

Normally each time you run the deploy pipeline, the secrets are (unfortunately) redeployed and you end up with multiple versions of the same secret.

This project explores the use of the a PowerShell script to determine if the secret already exists and if it has changed, then passes that indicator to the create secret task and only creates the secret if it is new or different.

This process *does work* and only adds secrets if they are new or changed, but is very slow. It takes the process of adding a key vault secret from 5-10 seconds to 2 minutes per secret, which makes this solution not very viable when you are adding a lot of secrets.

    Note: In order to make this work, you have to have a UserAssignedManagedIdentity added to the Key Vault. This identity is needed in order to authenticate to the Key Vault and determine if the secret exists and if it has changed.

---

## Future Work

The next step would be to explore using a script to scan the entire Key Vault and return an array/list of existing names, then have the other steps look at that array and only add a secret if it's NOT in that list. That should speed up the process - **HOWEVER** - it will not handle the case where you *WANT* the secret to be *UPDATED* with a new value.

---

## References

[Use deployment scripts in ARM templates - MS Learn](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template)

[Bicep - Create secret if not exists in KeyVault – Teching.nl](https://teching.nl/2022/08/bicep-create-secret-if-not-exists-in-keyvault/)
