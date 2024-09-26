

## EKS Setup Instructions

**Cluser components**
1.  EKS cluster
2.  VPC
3. Metrics, dashboards & alerts - Prometheus and grafana or cloudwatch container insights
4. ELK or fluentbit for logs
5.  Continuous Delivery - Argocd. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
6.  Autoscaling - Karpenter or cluster autoscaler
7.  AWS load balancer controller
8.  Metrics server
9.  External secrets helm chart
10. Storage - EBS or EFS CSI providers. By default we use EFS for persistent volumes because EFS is multi-az. We don't have to schedule all of a deployment's pods in the AZ which has an EBS volume which enhances fault tolerance.
11. We set up a critical nodegroup where we make use of taints and tolerations as well as node selectors to schedule critical components such i.e ELK, Grafana and Karpenter. This is to ensure we retain cluster visibility in the event of an issue affecting the cluster.

**Instructions**
- Set up a terraform cloud workspace named eks-dev.
- Set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY or better yet, use [dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration) such that terraform will assume an IAM role during each run. This is more secure than having long lived AWS credentials in terraform cloud.
- Clone this repo
- Navigate to the eks folder
- Set up eks/backend.tf
- Set up these environment variables in terraform cloud.

1. access_entries
2. argocd_slack_token ( The slack app should have chat:write permissions and should be installed in the channel it should post messages to )
3. argocd_ssh_private_key ( The private key is set here in terraform and the public key should be imported into github in Settings > SSH and GPG keys )
4. env
5. sns_topic
6. elastic_password
8. grafana_password
9. slack_incoming_webhook_url
10. company_name

- Ensure the variables in eks/variables.tf suit your needs. 
- Run terraform init and terraform apply
- At this point, the cluster has been created
- To log in via kubectl, use:

`aws eks update-kubeconfig --region eu-west-1 --name dev-compute --profile rr`

- Verify the worker nodes are ready

 `k get nodes`

- Set the value of the cluster_created variable in eks/variable.ts to true. This will create resources that needed the cluster to be created first e.g the argocd helm chart
- Run terraform apply
- In case you wish to install the helm charts one by one, install them in this order.

Order

 - Storage class
 - Secrets
 - AWS Loadbalancer controller
 - ArgoCD
 - ELK
 - Grafana
 - Karpenter

**Verify that**

1. A cloudwatch dashboard named dev-compute-kubernetes-cluster has been created if cloudwatch was selected for metrics.
2. 4 cluster cloudwatch alarms have been created with the prefix dev-compute if cloudwatch was selected for metrics.
4. You can access argocd. Use the username admin and run cmd below to get the password

`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode`

5. If ELK is being used for logs, ensure you can access the kibana dashboard.
8. If Prometheus-Grafana is being used for metrics, ensure you can access prometheus as well as log in to grafana and view the kubernetes dashboard and alarms. Test whether Grafana alerts are delivered to Slack.
9. If karpenter is being used for autoscaling, ensure karpenter is able to bring up worker nodes and there are no errors in the karpenter controller logs.
