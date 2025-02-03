
This repo contains terraform code that sets up an EKS cluster and a demo flask application. The application is exposed via ingress and can be accessed [here](https://demo-app.demo.rentrahisi.co.ke/). It simply displays an environment variable that has been retrieved from AWS secrets manager using the [External Secrets Operator](https://external-secrets.io/latest/).

This is the structure of the repo.

**.github**
Sets up the pipeline using Github Actions. When code is pushed to main, an image is built and pushed to ECR. ArgoCD periodically checks for new images and deploys them to the cluster.

**_helm-charts**
Helm chart for the app. [These](https://github.com/leroykayanda/eks-cluster/blob/main/_helm-charts/demo-app/staging-values.yaml#L5-L6) values can be set to true if one wishes to use spot instances as well as ARM instances.

    use_arm_instances: true
    use_spot_instances: true

Based on these, we use [node selectors](https://github.com/leroykayanda/eks-cluster/blob/main/_helm-charts/app/templates/deployment.yaml#L35-L45) to schedule pods on nodes with the appropriate labels.

      nodeSelector:
        {{- if .Values.use_arm_instances }}
        beta.kubernetes.io/arch: arm64
        {{- else }}
        beta.kubernetes.io/arch: amd64
        {{- end }}
        {{- if .Values.use_spot_instances }}
        karpenter.sh/capacity-type: spot
        {{- else }}
        eks.amazonaws.com/capacityType: ON_DEMAND
        {{- end }}

The karpenter nodepool has been defined [here](https://github.com/leroykayanda/eks-cluster/blob/main/eks/modules/eks/app_karpenter.tf#L335-L343) where we have added support for spot and ARM instances. We also add both ARM and x86 instance types [here](https://github.com/leroykayanda/eks-cluster/blob/main/eks/variables.tf#L328).

**eks**
I wrote a custom module to set up EKS [here](https://github.com/leroykayanda/eks-cluster/tree/main/eks/modules/eks). Other than setting up the EKS cluster, the module also sets up:

- Argocd for CICD
- ELK for logs
- Prometheus and Grafana for metrics, dashboards and alerts
- Istio service mesh
- Karpenter for autoscaling
- [Keycloak](https://www.keycloak.org/) for Single Sign On
- AWS load balancer controller for ingress
- [External Secrets Operator](https://external-secrets.io/latest/) to sync secrets from AWS secrets manager to kubernetes.
- EBS and EFS storage classes 

**demo-app**
Sets up a simple flask app.

The ECR and RDS modules that were used can be found in this repo which I own as well - [Terraform modules](https://github.com/leroykayanda/terraform-cloud-modules)

Detailed instructions on how the infrastructure was set up can be found below.

* [Setting up EKS](docs/eks.md)
* [Setting up the demo app](docs/demo-app.md)
* [Tearing down the infrastructure](docs/destroy.md)