

This repo contains terraform code that sets up an EKS cluster and a demo application.

**EKS cluser components**
1.  EKS module
2. cloudwatch container insights for metrics
6. fluentbit for logs
3.  a cloudwatch dashboard showing key cluster metrics like cpu, memory and disk usage. There are cloudwatch alarms for these key metrics.
4.  argocd for CICD. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
5.  cluster autoscaler
6.  AWS load balancer controller
7.  metrics server
8.  External secrets helm chart

To log in via kubectl, use:

`aws eks update-kubeconfig --region eu-west-1 --name dev-compute --profile rr`

This repo also sets up various components for a demo python flask app. The app code is in the demo-app folder.

**Demo app components**

We create these components via terraform.
 - app service account 
 - cloudwatch alarms 
 - ECR repo
 - argocd application

We then create these components via Kustomize.

- deployment
- service
- secrets
- load balancer controller
- HPA
- app namespace

To set up a new application, follow these steps:
Make sure you are in the correct terraform workspace and kubernetes context.

    terraform workspace select dev
    kubectl config use-context dev

Set up the terraform kubernetes provider Create the kubernetes service account in terraform as well as the other terraform resources. We don't create the argocd application and domain name yet.

Go to the correct kustomize context locally and create the resources.

    cd manifests/overlays/dev
    kubectl apply -k .

Verify the kustomize resources have been created. Get the argocd password.

    kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode


Add the variables ARGOCD_AUTH_USERNAME (admin) and ARGOCD_AUTH_PASSWORD (gotten above) as terraform env variables. Set up the terraform provider and backend and create the argocd application. Set up the argocd domain name as well.
 Apply the changes in terraform.
Test the app.

**Misc**

We can use cloudwatch log insights to search deployment logs using deployment and namespace names as filters.

    fields  @timestamp, log, kubernetes.container_name
    | sort  @timestamp  desc
    | filter kubernetes.labels.app = 'demo-app'  and kubernetes.namespace_name = 'dev-demo-app'

When you add a new secret in AWS secrets manager or modify a secret, stakater reloader will trigger a rolling update. Keep this in mind as this can cause issues in production. You may need to update secrets during a maintenance window.. Use the command below to check when a secret was last updated.

    kubectl describe ExternalSecret -n dev-demo-app
    Events:
      Type    Reason   Age   From              Message
      ----    ------   ----  ----              -------
      Normal  Updated  23s   external-secrets  Updated Secret

The app image is pushed to ECR using a Github actions workflow.