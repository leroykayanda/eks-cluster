

## Tearing down the infrastructure

 - Delete all images in ECR. 
 - Queue a destroy plan for the demo-app terraform workspace 
 - Delete all ingress objects. Terraform destroy typically
   throws an error when attempting to destroy these objects. 
   
       kubectl delete ingress --all --all-namespaces
        
  - Delete these namespaces.
  
    `k delete namespace elk grafana argocd istio-system keycloak`

- Delete finalizers for the istio-system ns.

      kubectl get namespace istio-system -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/istio-system/finalize" -f -

- Delete grafana alerts from the terraform state.

cmds

    terraform state rm module.eks.grafana_folder.rule_folder
    terraform state rm module.eks.grafana_rule_group.container_cpu_limit_use
    terraform state rm module.eks.grafana_rule_group.container_mem_limit_use
    terraform state rm module.eks.grafana_rule_group.container_restarts
    terraform state rm module.eks.grafana_rule_group.node_condition
    terraform state rm module.eks.grafana_rule_group.node_cpu
    terraform state rm module.eks.grafana_rule_group.node_disk
    terraform state rm module.eks.grafana_rule_group.node_memory
    terraform state rm module.eks.grafana_rule_group.pod_not_ready
    terraform state rm module.eks.grafana_rule_group.karpenter_cpu
    terraform state rm module.eks.grafana_rule_group.karpenter_memory

- Set the variable cluster_created to false in eks/variables.tf and cluster_not_terminated to true.
- Comment all the contents of these files.

app_elk.tf
app_grafana.tf
app_grafana_alerts.tf
app_istio.tf
app_keycloak.tf
app_argocd.tf

- Run terraform apply. This will delete terraform applications such as argocd
- Delete the database in console because it has lifecycle.prevent_destroy set.
- Run terraform apply -destroy