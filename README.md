# Key Vault Secrets Demo

[![Open in vscode.dev](https://img.shields.io/badge/Open%20in-vscode.dev-blue)][1]
[1]: https://vscode.dev/github/lluppesms/KeyVault.Secrets.demo/

<!-- ![azd Compatible](/Docs/images/AZD_Compatible.png) -->

---

Deploying Key Vault Secrets in a pipeline is a common task. This demo shows how to deploy a variety of secrets to a Key Vault.
Unfortunately, each time you run the pipeline, the secrets are redeployed and you end up with multiple versions of the same secret.

This project explores the use of the a script to determine if the secret already exists and if it has changed, then passes that 
indicator to the create secret task to only create the secret if it is new or different.

## References

[Use deployment scripts in ARM templates - MS Learn](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template)
