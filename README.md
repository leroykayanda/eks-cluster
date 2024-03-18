Contains the k8s module that sets up:

 1. a kubernetes cluster
 2. a cloudwatch dashboard
 3. argocd
 4. cluster autoscaler
 5. cloudwatch container insights
 6. AWS load balancer controller
 7. metrics server
 8. AWS secrets manager CSI driver

This repo also sets up:

 1. A Route 53 record that points to the argocd management URL.
 2. argocd ingress
 3. argocd image updater