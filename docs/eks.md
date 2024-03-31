**EKS cluser components**
1.  EKS module
2.  VPC
3. cloudwatch container insights for metrics
4. fluentbit for logs
5.  a cloudwatch dashboard showing key cluster metrics like cpu, memory and disk usage. There are cloudwatch alarms for these key metrics.
6.  argocd for CICD. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
7.  cluster autoscaler
8.  AWS load balancer controller
9.  metrics server
10.  External secrets helm chart


## EKS Setup Instructions
- set up a terraform cloud workspace named eks-dev.
- set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY
- Clone this repo
- Navigate to the eks folder
- set up eks/backend.tf
- set up these environment variables in terraform cloud.

1. access_entries
2. argo_slack_token
3. argo_ssh_private_key
4. env
5. sns_topic
6. company_name

- set up these variables in eks/variables.tf. Modify any other variables that you may need to e.g region

1. zone_id
2. certificate_arn
3. argo_domain_name
4. argocd_image_updater_values

- Run terraform init and terraform apply
- At this point, the cluster has been created
- To log in via kubectl, use:

`aws eks update-kubeconfig --region eu-west-1 --name dev-compute --profile rr`

- verify the worker nodes are ready

 `k get nodes`

- set the value of the cluster_created variable in eks/variable.ts to true. This will create resources that needed the cluster to be created first eg the cluster autoscaler helm chart
- run terraform apply
- verify that

1. A cloudwatch dashboard named dev-compute-kubernetes-cluster has been created
2. 4 cluster cloudwatch alarms have been created with the prefix dev-compute
3. A load balancer has been created with a port 443 listener rule pointing to the argocd service
4. Navigate to the argocd domain name.
5. use the username admin and run cmd below to get the password

`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode`

6. After logging in, go to settings>repositories to make sure argocd has credentials to log in to your github argo.
