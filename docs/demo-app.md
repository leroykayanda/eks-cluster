


## Demo app set up instructions
This sets up a simple python Flask app that prints out an environment variable retrieved from AWS scerets manager using the **[External Secrets Operator.](https://external-secrets.io/latest/)**

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
- Ingress
- HPA (Horizontal App Autoscaler)

**Instructions**

- Set up a terraform cloud workspace named aws-demo-app-staging
- Set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY or better yet, use [dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration) such that terraform will assume an IAM role during each run. This is more secure than having long lived AWS credentials in terraform cloud.
- Navigate to the demo-app folder
- Set up demo-app/terraform/backend.tf
- Set up these environment variables in terraform cloud.

1. env
2. sns_topic (If cloudwatch, rather than Grafana is being used for alerting)
3. ARGOCD_AUTH_USERNAME 
4. ARGOCD_AUTH_PASSWORD

- Verify the variables in demo-app/terraform/variables.tf are appropriate. 
- Modify aws_iam_policy.policy in demo-app/terraform/miscellaneous.tf with the appropriate IAM permissions for the app. 
- Comment out argocd_application in miscellaneous.tf. We shall create it later.
- Run terraform init and terraform apply. This creates:
ECR repo
App kubernetes namespace
App R53 record
App kubernetes service account
AWS secrets manager secret

**Pipeline setup**
- We use github actions to push an image to ECR. ArgoCD will detect this new image and trigger a new deployment.
- Set up a repository secret called TERRAFORM_CLOUD_TOKEN as well as SSH_KEY_GITHUB_ACTIONS (see [this](https://breadnet.co.uk/terraform-init-on-github-actions-with-private-modules/)).
- Use [this](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) to set up an IAM role that will allow Github to push images to ECR. This requires you to configure a github organisation in the trust policy of the IAM role that github will assume. If you don't have a github organisation, use an AWS access key to authenticate.
- Push the changes to github so that the pipeline is triggered and an image is pushed to ECR.

**Helm**
- Test out the helm charts by installing them manually using helm install to ensure everything is okay.
- If creating the resources one by one, follow this order.

SecretStore
ExternalSecret
Deployment
Service
HPA
Ingress

**Helm Cmds**

```
helm install --dry-run demo-app app -f demo-app/base-values.yaml -f demo-app/staging-values.yaml
helm install demo-app app -f demo-app/base-values.yaml -f demo-app/staging-values.yaml -n demo-app
helm uninstall demo-app -n demo-app

helm upgrade --dry-run demo-app app -f demo-app/base-values.yaml -f demo-app/staging-values.yaml -n demo-app -n demo-app
helm upgrade demo-app app -f demo-app/base-values.yaml -f demo-app/staging-values.yaml -n demo-app -n demo-app
```

- Delete the helm chart using helm uninstall
- Ensure argocd has been configured with the latest target_revision which is a git tag representing the latest snapshot of the helm chart in the repo. Uncomment argocd_application in miscellaneous.tf and run terraform apply

**Verify that**
- The service has endpoints registered.
- HPA is able to retrieve scaling metrics
- The deployment containers are healthy
- Ingress object has reconciled
- The app can be accessed via its domain name
- The app can access secrets manager secrets
- Reloader triggers a deployment when a secret is added or modified.
- Cloudwatch alarms have been created if cloudwatch is being used for metrics.
- An argocd application has been created
-  Argocd notifications are working and notifications are being sent to slack
-  Argocd image updater triggers a deployment when an image is pushed to ECR
- You can log in to kiali and the microservice graph can be seen.

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
