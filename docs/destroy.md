
## Tearing down the infrastructure

 - Delete all images in ECR. 
 - Queue a destroy plan for the terraform workspace 
 - Delete all ingress objects. Terraform destroy typically
   throws an error when attempting to destroy these objects. 
  - Delete namespaces
  
.
    `k delete namespace elk grafana argocd`

- Delete grafana alerts from the terraform state.

cmds

    terraform state rm module.eks.grafana_folder.rule_folder
    terraform state rm module.eks.grafana_rule_group.container_cpu_limit_use
    terraform state rm module.eks.grafana_rule_group.container_mem_limit_use
    terraform state rm module.eks.grafana_rule_group.container_oom
    terraform state rm module.eks.grafana_rule_group.container_restarts
    terraform state rm module.eks.grafana_rule_group.node_condition
    terraform state rm module.eks.grafana_rule_group.node_cpu
    terraform state rm module.eks.grafana_rule_group.node_disk
    terraform state rm module.eks.grafana_rule_group.node_memory
    terraform state rm module.eks.grafana_rule_group.pod_not_ready

- Set the variable cluster_created to false in eks/variables.tf and cluster_not_terminated to true.
- Run terraform apply. This will delete terraform applications such as argocd
- Scale down karpenter nodes
- Queue a destroy plan for the eks-dev workspace.