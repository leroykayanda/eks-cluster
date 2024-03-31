**Demo app components**
 - app service account. We use IRSA (IAM Role for Service Accounts)
 - cloudwatch alarms 
 - ECR repo
 - argocd application
- deployment
- service
- secrets
- load balancer controller
- HPA (Horizontal App Autoscaler)
- app namespace 

## Demo app set up instructions

Make sure you are in the correct terraform workspace and kubernetes context.

    terraform workspace select dev
    kubectl config use-context dev

Verify the manifest files in demo-app/manifests are correct. Go to the correct kustomize context locally and create the resources.

    cd demo-app/manifests/overlays/dev
    kubectl apply -k .

- set up a terraform cloud workspace named demo-app-aws-dev
- set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY
- Navigate to the demo-app folder
- set up demo-app/terraform/backend.tf
- set up these environment variables in terraform cloud.

1. env
2. sns_topic
3. ARGOCD_AUTH_USERNAME 
4. ARGOCD_AUTH_PASSWORD

- set up these variables in demo-app/terraform/variables.tf. Modify any other variables that you may need to e.g region

1. region
2. zone_id
3. dns_name
4. argo_annotations
5. argo_repo
6. argo_target_revision
7. argo_path
8. argo_server

- modify aws_iam_policy.policy in demo-app/terraform/misc.tf with the appropriate IAM permissions for the app. 
- run terraform init and terraform apply

**Pipeline setup**
- We use github actions to push an image to ECR. ArgoCD will detect this new image and trigger a new deployment.
- set up these repository secrets in github.

1. AWS_ACCESS_KEY_ID
2. AWS_SECRET_ACCESS_KEY
3. TERRAFORM_CLOUD_TOKEN

- Push the changes to github so that the pipeline is triggered and an image is pushed to ECR.

Verify these components have been created

- deployment
- service
- secrets
- load balancer controller
- HPA
- app namespace

Also verify that
- the app can be accessed via its domain name
- the app can access secrets manager secrets
- cloudwatch alarms have been created
- an argocd application has been created
-  argocd notifications are working and notifications are being sent to slack
-  argocd image updater triggers a deployment when an image is pushed to ECR

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