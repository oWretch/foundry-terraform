# VNet-integrated Azure Function infrastructure

Independent Terraform root converted from `foundry-bicep/tool-servers/azure-function-server/deploy-function.bicep`.

It creates a delegated integration subnet, Elastic Premium Linux plan, Python 3.11 Function App, runtime Storage account, Function private endpoint, Blob/Queue/File Storage private endpoints, and all matching private DNS zones and VNet links.

The Function App and runtime Storage public endpoints remain enabled to preserve the source deployment's creation sequence and Foundry DataProxy compatibility. Private endpoints provide private routing for VNet callers. Tighten inbound Function access with App Service access restrictions only after verifying the DataProxy source requirements.

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out function.tfplan
terraform apply function.tfplan

# Terraform provisions infrastructure only. Publish the unchanged source app.
$functionAppName = terraform output -raw function_app_name
Push-Location ..\..\..\foundry-bicep\tool-servers\azure-function-server
func azure functionapp publish $functionAppName
Pop-Location
```

The Storage access key is used by the Functions runtime and is stored as sensitive provider data in Terraform state. Protect the state with encryption and least-privilege access.