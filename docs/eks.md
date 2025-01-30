

## EKS Setup Instructions

**Cluser components**
1.  EKS cluster
2.  VPC
3. Metrics, dashboards & alerts - Prometheus and grafana or cloudwatch container insights
4. ELK or cloudwatch for logs
5.  Continuous Delivery - Argocd. This sets up the core argocd helm chart which comes bundled with argocd notifications. This sends notifications to slack when the health of an argocd application is degraded. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
6.  Autoscaling - Karpenter or cluster autoscaler. Karpenter is preferred because it can consolidate pods into cheaper nodes and it supports nodegroups with instances from different EC2 families.
7.  AWS load balancer controller
8.  Metrics server
9.  External secrets helm chart
10. Storage - EBS or EFS CSI providers. By default we use EFS for persistent volumes because EFS is multi-az. We don't have to schedule all of a deployment's pods in the AZ which has an EBS volume which enhances fault tolerance.
11. We set up a critical nodegroup where we make use of taints and tolerations as well as node selectors to schedule critical components such i.e ELK, Grafana, Keycloak and Karpenter. This is to ensure we retain cluster visibility in the event of an issue affecting the cluster.
12. We use priority classes to schedule pods with low priority which will be evicted when higher priority pods need to be scheduled. This reduces pod startup time because we don't need to wait for instances to start up.
13. [Keycloak](https://www.keycloak.org/), an opensource identity and management tool, is used to provide Single Sign On for argocd, kibana, prometheus, grafana and kiali. 

**Instructions**
- Set up a terraform cloud workspace named eks-staging.
- Set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY or better yet, use [dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration) such that terraform will assume an IAM role during each run. This is more secure than having long lived AWS credentials in terraform cloud.
- Clone this repo
- Navigate to the eks folder
- Set up eks/backend.tf
- Set up these environment variables in terraform cloud.

1. access_entries - for EKS permissions
2. argocd_slack_token ( The slack app should have chat:write permissions and should be installed in the channel it should post messages to )
3. argocd_ssh_private_key ( The private key is set here in terraform and the public key should be imported into github in Settings > SSH and GPG keys )
4. env
5. sns_topic
6. elastic_password
7. grafana_password
8. slack_incoming_webhook_url - used for alerting by Grafana
9. company_name - used to make s3 bucket names unique
10. keycloak_credentials
11. keycloak_db_credentials

- Ensure the variables in eks/variables.tf suit your needs. 
- Run terraform init and terraform apply
- At this point, the cluster has been created
- To log in via kubectl, use:

`aws eks update-kubeconfig --region eu-west-1 --name dev-compute --profile rr`

- Verify the worker nodes are ready

 `k get nodes`

- Set the value of the cluster_created variable in eks/variable.ts to true. This will create resources that needed the cluster to be created first e.g the argocd helm chart
- Run terraform apply
- In case you wish to install the helm charts one by one, install them in this order. It is recommended to follow this approach as you can test each component as you go along.

Order

 - EFS and EBS Storage classes
 - External Secrets Operator
 - Pod Priority Class
 - AWS Loadbalancer controller
 - Keycloak
 - ArgoCD
 - ELK
 - Grafana
 - Karpenter
 - Istio

**Verify that**

1. A cloudwatch dashboard named dev-compute-kubernetes-cluster has been created if cloudwatch was selected for metrics.
2. 4 cluster cloudwatch alarms have been created with the prefix dev-compute if cloudwatch was selected for metrics.
3. You can log in to keycloak. Create a user in the Devops_Admins groups.
4. You can access argocd using keycloak credentials. If using local credentials, the username is admin and the password can be gotten by running the cmd below.

`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode`

5. If ELK is being used for logs, ensure you can access the kibana dashboard.
6. If Prometheus-Grafana is being used for metrics, ensure you can access prometheus as well as log in to grafana and view the kubernetes dashboard and alarms. Test whether Grafana alerts are delivered to Slack.
7. If karpenter is being used for autoscaling, ensure karpenter is able to bring up worker nodes and there are no errors in the karpenter controller logs.
8. You can log in to Kiali if istio is enabled.
