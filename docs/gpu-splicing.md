## GPU Slicing on EKS

GPU-slicing is a method where multiple tasks share GPU resources in small time intervals, which helps in efficient utilization and task concurrency [1].

To use GPU slicing in EKS, we first create a nodegroup which instances which have GPUs e.g g4dn.2xlarge. Ensure the nodes in the nodegroup have a label to indicate they have GPUs.

    kubectl label node <nodename> nvidia.com/gpu.present=true

To enable GPU splicing we need to install the NVIDIA GPU device plugin. The plugin enables kubernetes to manage GPU resources similarly to how it handles CPU and memory. It exposes the GPU capacity on each node which the scheduler then uses to allocate pods that request GPU resources. This device plugin runs as a daemonset and communicates with the Kubernetes API server to advertise the node’s GPU capacity. This ensures that when a pod needs GPU resources, it’s placed on a node that can fulfill that requirement.

We only run the daemonset on nodes with the label we had set i.e nvidia.com/gpu.present=true.

    helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
    helm repo update
    
    helm upgrade -i nvdp nvdp/nvidia-device-plugin \
      --namespace kube-system \
      --set nodeSelector."nvidia\.com/gpu\.present"="true" \

We now need to create a config map which will contain the time slicing configuration.

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nvidia-device-plugin
      namespace: kube-system
    data:
      any: |-
        version: v1
        sharing:
          timeSlicing:
            resources:
            - name: nvidia.com/gpu
              replicas: 10

This means that a single physical GPU will be divided into 10 virtual ones. We then update the helm chart to point to the config map.

    helm upgrade -i nvdp nvdp/nvidia-device-plugin \
      --namespace kube-system \
      --set nodeSelector."nvidia\.com/gpu\.present"="true" \
      --set config.name=nvidia-device-plugin \

We can then request for GPU resources like this.

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gpu-deployment
      labels:
        app: gpu-app
    spec:
      replicas: 5
      selector:
        matchLabels:
          app: gpu-app
      template:
        metadata:
          labels:
            app: gpu-app
        spec:
          nodeSelector:
            nvidia.com/gpu.present: true
          containers:
          - name: gpu-container
            image: tensorflow/tensorflow:latest
            resources:
              limits:
                nvidia.com/gpu: 1 

Each of the 5 replicas will get 1 virtual GPU.

## Splicing when using karpenter

We setup an EC2NodeClass.

    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: platform-ml
    spec:
      amiFamily: AL2
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "dev"
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "dev"
      instanceProfile: "dev-node-karpenter"
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 100Gi
            volumeType: gp3
            deleteOnTermination: true

We also set up a NodePool ensuring we include instances with GPUs. We apply the label nvidia.com/gpu.present=true to nodes that will be started.

    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: platform-ml
    spec:
      template:
        metadata:
          labels:
            nvidia.com/gpu.present: true
        spec:
          nodeClassRef:
            apiVersion: karpenter.k8s.aws/v1beta1
            kind: EC2NodeClass
            name: platform-ml
          requirements:
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values: ["g5.xlarge","g5.2xlarge"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
          kubelet:
            maxPods: 58
      limits:
        cpu: 32
        memory: 128Gi
      disruption:
        expireAfter: 1440h

**References**
[1] GPU sharing on Amazon EKS with NVIDIA time-slicing and accelerated EC2 instances
https://aws.amazon.com/blogs/containers/gpu-sharing-on-amazon-eks-with-nvidia-time-slicing-and-accelerated-ec2-instances/
[2] EC2 GPU Instances
https://docs.aws.amazon.com/dlami/latest/devguide/gpu.html
[3] Recommended GPU Instances
https://docs.aws.amazon.com/dlami/latest/devguide/gpu.html
[4] Amazon EKS- implementing and using GPU nodes with NVIDIA drivers
https://marcincuber.medium.com/amazon-eks-implementing-and-using-gpu-nodes-with-nvidia-drivers-08d50fd637fe
