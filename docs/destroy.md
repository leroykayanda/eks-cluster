## Tearing down the infrastructure
- Queue a destroy plan for the terraform workspace azure-demo-app-dev
- Set the variable cluster_created to false in aks/variables.tf. 
- Run terraform apply. This will delete terraform applications such as argocd
- Queue a destroy plan for the aks-dev workspace.