# Add an AI Foundry project

Independent Terraform root for adding a project to an existing Foundry account while sharing existing AI Search, Storage, and Cosmos DB resources.

Set a stable `project_suffix`; unlike the Bicep timestamp default, this avoids creating a different project name on a later plan. Provider aliases support dependencies in different subscriptions, assuming the authenticated identity can read them and assign their roles.

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out add-project.tfplan
terraform apply add-project.tfplan
```

The state owns only the new project, its three connections, capability host, control-plane role assignments, Storage ABAC assignment, and Cosmos SQL data-plane role assignment. It does not own the shared resources.