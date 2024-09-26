
## Demo app set up instructions

**Demo app components**
 - App namespace 
 - App DNS record
 - App service account. We use IRSA (IAM Role for Service Accounts)
 - Cloudwatch alarms if cloudwatch is being used for metrics rather than prometheus.
 - ECR repo
 - AWS Secrets Manager secrets
 - Argocd application

Helm chart which sets up
- Deployment
- Service
- Secrets
- Load balancer controller
- HPA (Horizontal App Autoscaler)

**Instructions**

- Set up a terraform cloud workspace named demo-app-aws-dev
- Set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY or better yet, use dynamic credentials such that terraform will assume an IAM role during each run. This is more secure than having long lived AWS credentials in terraform cloud.
- Navigate to the demo-app folder
- Set up demo-app/terraform/backend.tf
- Set up these environment variables in terraform cloud.

1. env
2. sns_topic
3. ARGOCD_AUTH_USERNAME 
4. ARGOCD_AUTH_PASSWORD

- Verify the variables in demo-app/terraform/variables.tf are appropriate. 
- Modify aws_iam_policy.policy in demo-app/terraform/misc.tf with the appropriate IAM permissions for the app. 
- Run terraform init and terraform apply

**Pipeline setup**
- We use github actions to push an image to ECR. ArgoCD will detect this new image and trigger a new deployment.
- set up these repository secrets in github.

1. AWS_ACCESS_KEY_ID
2. AWS_SECRET_ACCESS_KEY
3. TERRAFORM_CLOUD_TOKEN

- Push the changes to github so that the pipeline is triggered and an image is pushed to ECR.
- Verify the helm chart kubernetes objects have been created

**Verify that**
- The app can be accessed via its domain name
- The app can access secrets manager secrets
- Reloader triggers a deployment when a secret is added or modified.
- Cloudwatch alarms have been created if cloudwatch is being used for metrics.
- An argocd application has been created
-  Argocd notifications are working and notifications are being sent to slack
-  Argocd image updater triggers a deployment when an image is pushed to ECR

**Miscellaneous**

We can use cloudwatch log insights to search deployment logs using deployment and namespace names as filters.

    fields  @timestamp, log, kubernetes.container_name
    | sort  @timestamp  desc
    | filter kubernetes.labels.app = 'demo-app'  and kubernetes.namespace_name = 'dev-demo-app'

When you add a new secret in AWS secrets manager or modify a secret, stakater reloader will trigger a rolling update. Keep this in mind as this can cause issues in production. You may need to update secrets during a maintenance window. Use the command below to check when a secret was last updated.

    kubectl describe ExternalSecret -n dev-demo-app
    Events:
      Type    Reason   Age   From              Message
      ----    ------   ----  ----              -------
      Normal  Updated  23s   external-secrets  Updated Secret

The app image is pushed to ECR using a Github actions workflow.

**Helm Cmds**

    helm install --dry-run demo-app app -f base-values.yaml -f dev-values.yaml
    helm install demo-app app -f base-values.yaml -f dev-values.yaml -n demo-app
    helm uninstall demo-app -n demo-app
    
    helm upgrade --dry-run demo-app app -f base-values.yaml -f dev-values.yaml -n demo-app
    helm upgrade demo-app app -f base-values.yaml -f dev-values.yaml -n demo-app
